-- =====================================================
-- Migration: 010_financeiro_pagamentos.sql
-- Sprint: 2 - Medições
-- Descrição: Tabela de pagamentos no schema financeiro
-- Data: 06/11/2025 (refatorado para schemas)
-- Versão: v1.0.1-HML (corrigido: ENUM idempotente)
-- =====================================================

-- ============================================
-- UP: Criação do ENUM e Tabela de Pagamentos
-- ============================================

-- Tipo ENUM para status de pagamento - idempotente
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    WHERE t.typname = 'status_pagamento'
      AND t.typnamespace = 'financeiro'::regnamespace
  ) THEN
    CREATE TYPE financeiro.status_pagamento AS ENUM (
      'PENDENTE',
      'AGENDADO',
      'PAGO',
      'CANCELADO'
    );
  END IF;
END$$;

-- Garantir que todos os valores existem (sem erro se já existirem)
ALTER TYPE financeiro.status_pagamento ADD VALUE IF NOT EXISTS 'PENDENTE';
ALTER TYPE financeiro.status_pagamento ADD VALUE IF NOT EXISTS 'AGENDADO';
ALTER TYPE financeiro.status_pagamento ADD VALUE IF NOT EXISTS 'PAGO';
ALTER TYPE financeiro.status_pagamento ADD VALUE IF NOT EXISTS 'CANCELADO';

-- Tabela de pagamentos (parcelas) (schema financeiro)
-- Vínculo: N pagamentos para 1 NF (parcelas)
-- Identificação da NF: por chave_acesso (preferencial) ou trio (emitente_cnpj, serie, numero_nf)
CREATE TABLE IF NOT EXISTS financeiro.pagamentos (
    id_pag UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- FK para medição (mesmo schema)
    id_medicao UUID NOT NULL 
        REFERENCES financeiro.medicoes(id_medicao)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    
    -- Vínculo com NF: chave_acesso (preferencial) ou trio alternativo
    -- Normalizado só-dígitos antes de buscar NF correspondente
    chave_acesso_nf VARCHAR(44), -- Preferencial
    numero_nf VARCHAR(20) NOT NULL, -- Obrigatório (fallback)
    serie_nf VARCHAR(10), -- Trio alternativo
    emitente_cnpj_nf VARCHAR(14), -- Trio alternativo
    
    -- Valores e datas
    valor_pago NUMERIC(14,2) NOT NULL CHECK (valor_pago > 0),
    data_vencimento DATE,
    data_pagamento DATE, -- Quando foi efetivamente pago (NULL = ainda não pago)
    
    -- Forma de pagamento
    forma_pagamento VARCHAR(50), -- Ex: TED, PIX, BOLETO, CHEQUE
    
    -- Status
    status_pagamento financeiro.status_pagamento NOT NULL DEFAULT 'PENDENTE',
    
    -- Campos auxiliares
    numero_documento VARCHAR(100), -- Número do documento bancário (TED, PIX, etc)
    observacoes TEXT,
    
    -- Controle
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Validação: data_pagamento não pode ser futura (relaxável com flag)
    CONSTRAINT chk_pagamento_data_pagamento CHECK (
        data_pagamento IS NULL OR data_pagamento <= CURRENT_DATE
    )
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_pagamentos_medicao 
    ON financeiro.pagamentos(id_medicao);

CREATE INDEX IF NOT EXISTS idx_pagamentos_chave_acesso 
    ON financeiro.pagamentos(chave_acesso_nf) 
    WHERE chave_acesso_nf IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_pagamentos_numero_nf 
    ON financeiro.pagamentos(numero_nf);

CREATE INDEX IF NOT EXISTS idx_pagamentos_data_pagamento 
    ON financeiro.pagamentos(data_pagamento) 
    WHERE data_pagamento IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_pagamentos_status 
    ON financeiro.pagamentos(status_pagamento);

-- Índice composto para trio alternativo
CREATE INDEX IF NOT EXISTS idx_pagamentos_trio 
    ON financeiro.pagamentos(emitente_cnpj_nf, serie_nf, numero_nf) 
    WHERE emitente_cnpj_nf IS NOT NULL;

-- Índice para cálculo de DSO (data_pagamento + numero_nf)
CREATE INDEX IF NOT EXISTS idx_pagamentos_dso 
    ON financeiro.pagamentos(numero_nf, data_pagamento) 
    WHERE data_pagamento IS NOT NULL;

-- Índice para vencimentos pendentes
CREATE INDEX IF NOT EXISTS idx_pagamentos_vencimento 
    ON financeiro.pagamentos(data_vencimento, status_pagamento) 
    WHERE status_pagamento = 'PENDENTE' AND data_vencimento IS NOT NULL;

-- Comentários
COMMENT ON TABLE financeiro.pagamentos IS 'Pagamentos/parcelas de NFs - vínculo N:1 com NFs (uma NF pode ter múltiplas parcelas)';
COMMENT ON COLUMN financeiro.pagamentos.chave_acesso_nf IS 'Chave de acesso da NF (preferencial para vínculo)';
COMMENT ON COLUMN financeiro.pagamentos.numero_nf IS 'Número da NF normalizado (obrigatório como fallback)';
COMMENT ON COLUMN financeiro.pagamentos.data_pagamento IS 'Data efetiva do pagamento (NULL = ainda não pago) - base para DSO';
COMMENT ON COLUMN financeiro.pagamentos.valor_pago IS 'Valor efetivamente pago nesta parcela';
COMMENT ON COLUMN financeiro.pagamentos.forma_pagamento IS 'Forma de pagamento (TED, PIX, BOLETO, CHEQUE, etc)';

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION financeiro.update_pagamentos_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Trigger para atualizar status automaticamente quando data_pagamento preenchida
CREATE OR REPLACE FUNCTION financeiro.update_pagamento_status_on_payment()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.data_pagamento IS NOT NULL AND OLD.data_pagamento IS NULL THEN
        NEW.status_pagamento = 'PAGO';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- ============================================
-- DOWN: Rollback
-- ============================================

-- DROP TRIGGER IF EXISTS trg_pagamentos_auto_status ON financeiro.pagamentos;
-- DROP FUNCTION IF EXISTS financeiro.update_pagamento_status_on_payment();
-- DROP TRIGGER IF EXISTS trg_pagamentos_updated_at ON financeiro.pagamentos;
-- DROP FUNCTION IF EXISTS financeiro.update_pagamentos_timestamp();
-- DROP INDEX IF EXISTS idx_pagamentos_vencimento;
-- DROP INDEX IF EXISTS idx_pagamentos_dso;
-- DROP INDEX IF EXISTS idx_pagamentos_trio;
-- DROP INDEX IF EXISTS idx_pagamentos_status;
-- DROP INDEX IF EXISTS idx_pagamentos_data_pagamento;
-- DROP INDEX IF EXISTS idx_pagamentos_numero_nf;
-- DROP INDEX IF EXISTS idx_pagamentos_chave_acesso;
-- DROP INDEX IF EXISTS idx_pagamentos_medicao;
-- DROP TABLE IF EXISTS financeiro.pagamentos CASCADE;
-- DROP TYPE IF EXISTS financeiro.status_pagamento CASCADE;

-- =====================================================
-- NOTA v1.0.1-HML:
-- Corrigido CREATE TYPE para padrão idempotente com DO $$ ... END$$
-- Adicionados ALTER TYPE ... ADD VALUE IF NOT EXISTS para garantir valores
-- Adicionados IF NOT EXISTS em índices para idempotência completa
-- =====================================================

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================

-- -------------------------------------------------------------------
