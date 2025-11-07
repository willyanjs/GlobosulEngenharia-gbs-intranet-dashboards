-- =====================================================
-- Migration: 005_operacional_dim_tipo_fornecimento.sql
-- Sprint: 2 - Medições
-- Descrição: Dimensão de tipos de fornecimento no schema operacional
-- Data: 06/11/2025 (refatorado para schemas)
-- Versão: v1.0.2-HML (fix: idempotência + delimitadores + owner)
-- =====================================================

-- Tabela de dimensão para tipos de fornecimento (schema operacional)
-- Cadastro mestre usado por obras/contratos e referenciado por financeiro
CREATE TABLE IF NOT EXISTS operacional.dim_tipo_fornecimento (
    id_tipo UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(50) NOT NULL UNIQUE,
    rotulo VARCHAR(100) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Owner explícito
ALTER TABLE IF EXISTS operacional.dim_tipo_fornecimento OWNER TO gbs_dev;

-- Índices (idempotentes)
-- Nota: idx_dim_tipo_fornecimento_codigo é redundante (UNIQUE já cria índice)
-- Será removido na migration 017_operacional_dim_tipo_fornecimento_cleanup.sql
CREATE INDEX IF NOT EXISTS idx_dim_tipo_fornecimento_codigo 
    ON operacional.dim_tipo_fornecimento(codigo);

CREATE INDEX IF NOT EXISTS idx_dim_tipo_fornecimento_ativo 
    ON operacional.dim_tipo_fornecimento(ativo);

-- Comentários
COMMENT ON TABLE operacional.dim_tipo_fornecimento IS 'Dimensão de tipos de fornecimento - catálogo controlado para classificação de obras';
COMMENT ON COLUMN operacional.dim_tipo_fornecimento.codigo IS 'Código normalizado (UPPER, sem acento/espaços) ex: CONSTRUCAO, MANUTENCAO';
COMMENT ON COLUMN operacional.dim_tipo_fornecimento.rotulo IS 'Rótulo amigável para exibição ex: Construção, Manutenção';
COMMENT ON COLUMN operacional.dim_tipo_fornecimento.ativo IS 'Flag para desativação lógica (não deleta histórico)';

-- Seed inicial (catálogo base)
-- Idempotente: ON CONFLICT DO NOTHING
INSERT INTO operacional.dim_tipo_fornecimento (codigo, rotulo) VALUES
    ('CONSTRUCAO', 'Construção'),
    ('MANUTENCAO', 'Manutenção'),
    ('EMERGENCIA', 'Emergência'),
    ('PROJETOS', 'Projetos'),
    ('PODA_VEGETACAO', 'Poda e Vegetação'),
    ('OUTROS', 'Outros')
ON CONFLICT (codigo) DO NOTHING;

-- =====================================================
-- v1.0.2-HML — Trigger idempotente + delimitadores
-- =====================================================

-- Função: atualiza updated_at antes de UPDATE
CREATE OR REPLACE FUNCTION operacional.update_dim_tipo_fornecimento_timestamp()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$fn$;

-- Ownership explícito
ALTER FUNCTION operacional.update_dim_tipo_fornecimento_timestamp() OWNER TO gbs_dev;

-- Trigger: criar somente se ainda não existir
DO $do$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trg_dim_tipo_fornecimento_updated_at'
      AND tgrelid = 'operacional.dim_tipo_fornecimento'::regclass
  ) THEN
    CREATE TRIGGER trg_dim_tipo_fornecimento_updated_at
      BEFORE UPDATE ON operacional.dim_tipo_fornecimento
      FOR EACH ROW
      EXECUTE FUNCTION operacional.update_dim_tipo_fornecimento_timestamp();
  END IF;
END
$do$;

-- =====================================================
-- NOTA v1.0.2-HML:
-- - Índices com IF NOT EXISTS (idempotência total)
-- - Owner explícito para gbs_dev (tabela + função)
-- - Delimitadores nominais: $fn$ (função) e $do$ (bloco)
-- - Trigger idempotente (verificação pg_trigger)
-- - Seed com ON CONFLICT DO NOTHING (já era idempotente)
-- - Índice redundante idx_dim_tipo_fornecimento_codigo será removido na 017
-- =====================================================

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
