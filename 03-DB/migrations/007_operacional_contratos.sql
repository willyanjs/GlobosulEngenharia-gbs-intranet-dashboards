-- =====================================================
-- Migration: 007_operacional_contratos.sql
-- Sprint: 2 - Medições
-- Descrição: Tabela de contratos no schema operacional
-- Data: 06/11/2025 (refatorado para schemas)
-- Versão: v1.0.2-HML (fix: idempotência + delimitadores + owner)
-- =====================================================

-- Tabela de contratos (schema operacional)
-- Obrigatório vínculo com obra; uma obra pode ter múltiplos contratos ao longo do tempo
CREATE TABLE IF NOT EXISTS operacional.contratos (
    id_contrato UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- FK para obra (mesmo schema)
    id_obra UUID NOT NULL 
        REFERENCES operacional.obras(id_obra)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    
    -- Identificação do contrato
    numero_contrato VARCHAR(100) NOT NULL,
    id_cliente_exati VARCHAR(50), -- ID do cliente no sistema Exati (para integração futura)
    
    -- Valores e vigência
    valor_total NUMERIC(14,2) NOT NULL CHECK (valor_total >= 0),
    vigencia_inicio DATE NOT NULL,
    vigencia_fim DATE NOT NULL,
    
    -- Campos auxiliares
    objeto TEXT,
    observacoes TEXT,
    
    -- Controle
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Validação: data fim deve ser posterior ou igual ao início
    CONSTRAINT chk_contratos_vigencia CHECK (vigencia_fim >= vigencia_inicio)
);

-- Owner explícito
ALTER TABLE IF EXISTS operacional.contratos OWNER TO gbs_dev;

-- Índices para performance (idempotentes)
CREATE INDEX IF NOT EXISTS idx_contratos_numero
    ON operacional.contratos(numero_contrato);

CREATE INDEX IF NOT EXISTS idx_contratos_obra
    ON operacional.contratos(id_obra);

CREATE INDEX IF NOT EXISTS idx_contratos_vigencia
    ON operacional.contratos(vigencia_inicio, vigencia_fim);

CREATE INDEX IF NOT EXISTS idx_contratos_cliente_exati
    ON operacional.contratos(id_cliente_exati)
    WHERE id_cliente_exati IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_contratos_ativo
    ON operacional.contratos(ativo);

-- Índice composto para busca de contratos vigentes de uma obra
CREATE INDEX IF NOT EXISTS idx_contratos_obra_vigencia
    ON operacional.contratos(id_obra, vigencia_inicio, vigencia_fim)
    WHERE ativo = true;

-- Comentários
COMMENT ON TABLE operacional.contratos IS 'Contratos de obras - uma obra pode ter múltiplos contratos ao longo do tempo';
COMMENT ON COLUMN operacional.contratos.numero_contrato IS 'Número do contrato (formato livre, ex: CNT-2025-001)';
COMMENT ON COLUMN operacional.contratos.id_cliente_exati IS 'ID do cliente no sistema Exati para integração futura';
COMMENT ON COLUMN operacional.contratos.valor_total IS 'Valor total do contrato em reais (2 casas decimais)';

-- =====================================================
-- v1.0.2-HML — Trigger idempotente + delimitadores
-- =====================================================

-- Função: atualiza updated_at antes de UPDATE
CREATE OR REPLACE FUNCTION operacional.update_contratos_timestamp()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$fn$;

-- Ownership explícito
ALTER FUNCTION operacional.update_contratos_timestamp() OWNER TO gbs_dev;

-- Trigger: criar somente se ainda não existir
DO $do$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trg_contratos_updated_at'
      AND tgrelid = 'operacional.contratos'::regclass
  ) THEN
    CREATE TRIGGER trg_contratos_updated_at
      BEFORE UPDATE ON operacional.contratos
      FOR EACH ROW
      EXECUTE FUNCTION operacional.update_contratos_timestamp();
  END IF;
END
$do$;

-- =====================================================
-- NOTA v1.0.2-HML:
-- - Índices com IF NOT EXISTS (idempotência total)
-- - Owner explícito para gbs_dev (tabela + função)
-- - Delimitadores nominais: $fn$ (função) e $do$ (bloco)
-- - Trigger idempotente (verificação pg_trigger)
-- =====================================================

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
