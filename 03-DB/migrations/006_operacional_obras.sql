-- =====================================================
-- Migration: 006_operacional_obras.sql
-- Sprint: 2 - Medições
-- Descrição: Tabela de obras no schema operacional com gate de implantação
-- Data: 06/11/2025 (refatorado para schemas)
-- Versão: v1.0.2-HML (fix: idempotência + delimitadores + owner)
-- =====================================================

-- Tabela de obras (schema operacional)
-- Gate crítico: implantacao_contrato obrigatório para listar em /v1/works
CREATE TABLE IF NOT EXISTS operacional.obras (
    id_obra UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo_obra VARCHAR(50) NOT NULL UNIQUE,
    descricao TEXT NOT NULL,
    cliente VARCHAR(255) NOT NULL,
    
    -- Gate de listagem: somente obras com esta data aparecem nas APIs
    implantacao_contrato DATE,
    
    -- Classificação (não afeta KPIs do pipeline, apenas filtros de lista)
    -- FK cross-schema está OK (mesmo schema operacional)
    tipo_fornecimento_id UUID 
        REFERENCES operacional.dim_tipo_fornecimento(id_tipo)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    
    -- Campos auxiliares
    endereco TEXT,
    cidade VARCHAR(100),
    estado CHAR(2),
    
    -- Controle
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Owner explícito
ALTER TABLE IF EXISTS operacional.obras OWNER TO gbs_dev;

-- Índices para performance (idempotentes)
-- Nota: idx_obras_codigo é redundante (UNIQUE já cria índice)
-- Será removido na migration 018_operacional_obras_cleanup.sql
CREATE INDEX IF NOT EXISTS idx_obras_codigo 
    ON operacional.obras(codigo_obra);

CREATE INDEX IF NOT EXISTS idx_obras_implantacao 
    ON operacional.obras(implantacao_contrato) 
    WHERE implantacao_contrato IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_obras_cliente 
    ON operacional.obras(cliente);

CREATE INDEX IF NOT EXISTS idx_obras_tipo_fornecimento 
    ON operacional.obras(tipo_fornecimento_id);

CREATE INDEX IF NOT EXISTS idx_obras_ativo 
    ON operacional.obras(ativo);

-- Índice composto para filtros comuns (gate + ativo)
CREATE INDEX IF NOT EXISTS idx_obras_gate_ativo 
    ON operacional.obras(implantacao_contrato, ativo) 
    WHERE implantacao_contrato IS NOT NULL AND ativo = true;

-- Comentários
COMMENT ON TABLE operacional.obras IS 'Obras da Globosul - Gate: implantacao_contrato obrigatório para listagem';
COMMENT ON COLUMN operacional.obras.codigo_obra IS 'Código único da obra (ex: OB-2025-001)';
COMMENT ON COLUMN operacional.obras.implantacao_contrato IS 'Data de implantação do contrato - GATE: se NULL, obra não aparece em /v1/works?gate=on';
COMMENT ON COLUMN operacional.obras.tipo_fornecimento_id IS 'Tipo de fornecimento (FK dimensão) - usado apenas para filtros, NÃO afeta KPIs';

-- =====================================================
-- v1.0.2-HML — Trigger idempotente + delimitadores
-- =====================================================

-- Função: atualiza updated_at antes de UPDATE
CREATE OR REPLACE FUNCTION operacional.update_obras_timestamp()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$fn$;

-- Ownership explícito
ALTER FUNCTION operacional.update_obras_timestamp() OWNER TO gbs_dev;

-- Trigger: criar somente se ainda não existir
DO $do$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trg_obras_updated_at'
      AND tgrelid = 'operacional.obras'::regclass
  ) THEN
    CREATE TRIGGER trg_obras_updated_at
      BEFORE UPDATE ON operacional.obras
      FOR EACH ROW
      EXECUTE FUNCTION operacional.update_obras_timestamp();
  END IF;
END
$do$;

-- =====================================================
-- NOTA v1.0.2-HML:
-- - Índices com IF NOT EXISTS (idempotência total)
-- - Owner explícito para gbs_dev (tabela + função)
-- - Delimitadores nominais: $fn$ (função) e $do$ (bloco)
-- - Trigger idempotente (verificação pg_trigger)
-- - Índice redundante idx_obras_codigo será removido na 018
-- =====================================================

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
