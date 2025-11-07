-- =====================================================
-- Migration: 008_financeiro_medicoes.sql
-- Sprint: 2 - Medições
-- Descrição: Tabela de medições no schema financeiro com pipeline
-- Data: 06/11/2025 (refatorado para schemas)
-- Versão: v1.0.1-HML (corrigido: ENUM idempotente)
-- =====================================================

-- ============================================
-- UP: Criação do ENUM e Tabela de Medições
-- ============================================

-- Tipo ENUM para status (auxiliar; status real calculado por milestones) - idempotente
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    WHERE t.typname = 'status_medicao'
      AND t.typnamespace = 'financeiro'::regnamespace
  ) THEN
    CREATE TYPE financeiro.status_medicao AS ENUM (
      'PREVISTA',
      'EMITIDA',
      'ENVIADA',
      'APROVADA',
      'NF',
      'PAGA'
    );
  END IF;
END$$;

-- Garantir que todos os valores existem (sem erro se já existirem)
ALTER TYPE financeiro.status_medicao ADD VALUE IF NOT EXISTS 'PREVISTA';
ALTER TYPE financeiro.status_medicao ADD VALUE IF NOT EXISTS 'EMITIDA';
ALTER TYPE financeiro.status_medicao ADD VALUE IF NOT EXISTS 'ENVIADA';
ALTER TYPE financeiro.status_medicao ADD VALUE IF NOT EXISTS 'APROVADA';
ALTER TYPE financeiro.status_medicao ADD VALUE IF NOT EXISTS 'NF';
ALTER TYPE financeiro.status_medicao ADD VALUE IF NOT EXISTS 'PAGA';

-- Tabela de medições (schema financeiro)
-- Funil: PREVISTA → EMITIDA → ENVIADA → APROVADA → NF → PAGA
-- Status real calculado por milestones (datas), não pelo campo status
CREATE TABLE IF NOT EXISTS financeiro.medicoes (
    id_medicao UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- FK cross-schema para operacional
    id_obra UUID NOT NULL 
        REFERENCES operacional.obras(id_obra)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    
    id_contrato UUID 
        REFERENCES operacional.contratos(id_contrato)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    
    -- Competência: primeiro dia do mês (YYYY-MM-01)
    -- UNIQUE por obra: uma medição por obra por mês
    competencia DATE NOT NULL,
    
    -- Valores monetários (BRL, 2 casas decimais)
    valor_previsto NUMERIC(14,2) NOT NULL CHECK (valor_previsto >= 0),
    valor_glosado NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (valor_glosado >= 0),
    
    -- Valor aprovado: computed column (previsto - glosado, mínimo 0)
    valor_aprovado NUMERIC(14,2) GENERATED ALWAYS AS (
        GREATEST(valor_previsto - valor_glosado, 0)
    ) STORED,
    
    -- Milestones (datas de marco) - determinam o status real
    data_prevista DATE, -- Data prevista para conclusão (opcional)
    data_envio_relatorio DATE, -- Quando relatório foi enviado ao cliente
    data_aprovacao_cliente DATE, -- Quando cliente aprovou
    
    -- Status auxiliar (não é fonte da verdade; status real = calculado por milestones)
    status financeiro.status_medicao NOT NULL DEFAULT 'PREVISTA',
    
    -- Substatus auxiliar (ex: DEVOLVIDA quando há glosa sem aprovação)
    substatus VARCHAR(50),
    
    -- Campos auxiliares
    observacoes TEXT,
    
    -- Controle
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT uq_medicao_obra_competencia UNIQUE (id_obra, competencia),
    CONSTRAINT chk_medicao_competencia_primeiro_dia CHECK (
        EXTRACT(DAY FROM competencia) = 1
    )
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_medicoes_obra 
    ON financeiro.medicoes(id_obra);

CREATE INDEX IF NOT EXISTS idx_medicoes_contrato 
    ON financeiro.medicoes(id_contrato) 
    WHERE id_contrato IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_medicoes_competencia 
    ON financeiro.medicoes(competencia);

CREATE INDEX IF NOT EXISTS idx_medicoes_status 
    ON financeiro.medicoes(status);

-- Índice para queries do pipeline (obra + competência + status)
CREATE INDEX IF NOT EXISTS idx_medicoes_pipeline 
    ON financeiro.medicoes(id_obra, competencia, status);

-- Índice para cálculo de KPIs (competência + datas de marco)
CREATE INDEX IF NOT EXISTS idx_medicoes_kpis 
    ON financeiro.medicoes(competencia, data_envio_relatorio, data_aprovacao_cliente);

-- Índices parciais para datas de marco preenchidas
CREATE INDEX IF NOT EXISTS idx_medicoes_enviadas 
    ON financeiro.medicoes(data_envio_relatorio) 
    WHERE data_envio_relatorio IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_medicoes_aprovadas 
    ON financeiro.medicoes(data_aprovacao_cliente) 
    WHERE data_aprovacao_cliente IS NOT NULL;

-- Comentários
COMMENT ON TABLE financeiro.medicoes IS 'Medições de obras - pipeline financeiro Prevista→Emitida→Enviada→Aprovada→NF→Paga';
COMMENT ON COLUMN financeiro.medicoes.competencia IS 'Competência da medição - primeiro dia do mês (YYYY-MM-01), UNIQUE por obra';
COMMENT ON COLUMN financeiro.medicoes.valor_previsto IS 'Valor previsto da medição (base do funil)';
COMMENT ON COLUMN financeiro.medicoes.valor_glosado IS 'Valor glosado/rejeitado pelo cliente (padrão 0)';
COMMENT ON COLUMN financeiro.medicoes.valor_aprovado IS 'Computed: previsto - glosado (mínimo 0)';
COMMENT ON COLUMN financeiro.medicoes.data_envio_relatorio IS 'Data de envio do relatório ao cliente (milestone ENVIADA)';
COMMENT ON COLUMN financeiro.medicoes.data_aprovacao_cliente IS 'Data de aprovação pelo cliente (milestone APROVADA)';
COMMENT ON COLUMN financeiro.medicoes.status IS 'Status auxiliar - status REAL calculado por milestones (datas)';
COMMENT ON COLUMN financeiro.medicoes.substatus IS 'Substatus auxiliar (ex: DEVOLVIDA quando glosa sem aprovação)';

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION financeiro.update_medicoes_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- CREATE TRIGGER trg_medicoes_updated_at
    BEFORE UPDATE ON financeiro.medicoes
    FOR EACH ROW
    EXECUTE FUNCTION financeiro.update_medicoes_timestamp();

-- ============================================
-- DOWN: Rollback
-- ============================================

-- DROP TRIGGER IF EXISTS trg_medicoes_updated_at ON financeiro.medicoes;
-- DROP FUNCTION IF EXISTS financeiro.update_medicoes_timestamp();
-- DROP INDEX IF EXISTS idx_medicoes_aprovadas;
-- DROP INDEX IF EXISTS idx_medicoes_enviadas;
-- DROP INDEX IF EXISTS idx_medicoes_kpis;
-- DROP INDEX IF EXISTS idx_medicoes_pipeline;
-- DROP INDEX IF EXISTS idx_medicoes_status;
-- DROP INDEX IF EXISTS idx_medicoes_competencia;
-- DROP INDEX IF EXISTS idx_medicoes_contrato;
-- DROP INDEX IF EXISTS idx_medicoes_obra;
-- DROP TABLE IF EXISTS financeiro.medicoes CASCADE;
-- DROP TYPE IF EXISTS financeiro.status_medicao CASCADE;

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
-- HOTFIX v1.0.2-HML: tornar trigger idempotente e garantir ownerships
-- -------------------------------------------------------------------

-- garante owner da tabela e da função
ALTER TABLE  financeiro.medicoes                     OWNER TO gbs_dev;
ALTER FUNCTION financeiro.update_medicoes_timestamp() OWNER TO gbs_dev;

-- cria o trigger somente se não existir
DO $do$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_trigger
     WHERE tgname = 'trg_medicoes_updated_at'
       AND tgrelid = 'financeiro.medicoes'::regclass
  ) THEN
    EXECUTE 'CREATE TRIGGER trg_medicoes_updated_at
             BEFORE UPDATE ON financeiro.medicoes
             FOR EACH ROW
             EXECUTE FUNCTION financeiro.update_medicoes_timestamp()';
  END IF;
END
$do$;
