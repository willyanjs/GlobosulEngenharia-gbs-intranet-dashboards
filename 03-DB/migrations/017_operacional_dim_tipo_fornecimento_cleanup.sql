-- =====================================================
-- Migration: 017_operacional_dim_tipo_fornecimento_cleanup.sql
-- Sprint: 2 - Medições
-- Descrição: Remove índice redundante e garante ownership
-- Data: 06/11/2025
-- Versão: v1.0.2-HML
-- =====================================================

-- ============================================
-- Contexto:
-- A constraint UNIQUE em dim_tipo_fornecimento.codigo
-- já cria automaticamente o índice dim_tipo_fornecimento_codigo_key.
-- O índice idx_dim_tipo_fornecimento_codigo é redundante.
-- Esta migration remove a duplicata e garante estrutura correta.
-- ============================================

-- Garantir tabela existe e tem owner correto (inofensivo se já existir)
CREATE TABLE IF NOT EXISTS operacional.dim_tipo_fornecimento (
  id_tipo    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo     VARCHAR(50) NOT NULL,
  rotulo     VARCHAR(100) NOT NULL,
  ativo      BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Owner explícito
ALTER TABLE IF EXISTS operacional.dim_tipo_fornecimento OWNER TO gbs_dev;

-- Garante constraint UNIQUE em codigo (apenas se não existir)
-- Esta constraint cria automaticamente o índice dim_tipo_fornecimento_codigo_key
DO $do$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'dim_tipo_fornecimento_codigo_key'
      AND conrelid = 'operacional.dim_tipo_fornecimento'::regclass
  ) THEN
    ALTER TABLE operacional.dim_tipo_fornecimento
      ADD CONSTRAINT dim_tipo_fornecimento_codigo_key UNIQUE (codigo);
    RAISE NOTICE 'Constraint UNIQUE criada: dim_tipo_fornecimento_codigo_key';
  END IF;
END
$do$;

-- Remove índice redundante (UNIQUE já cobre a coluna codigo)
DO $do$
BEGIN
  IF EXISTS (
    SELECT 1 
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_dim_tipo_fornecimento_codigo'
      AND n.nspname = 'operacional'
  ) THEN
    EXECUTE 'DROP INDEX operacional.idx_dim_tipo_fornecimento_codigo';
    RAISE NOTICE 'Índice redundante removido: idx_dim_tipo_fornecimento_codigo';
  END IF;
END
$do$;

-- Mantém índice de ativo (útil para filtros por status)
CREATE INDEX IF NOT EXISTS idx_dim_tipo_fornecimento_ativo
  ON operacional.dim_tipo_fornecimento (ativo);

-- Comentários
COMMENT ON TABLE operacional.dim_tipo_fornecimento IS 'Dimensão de tipos de fornecimento - índices otimizados (sem redundância)';
COMMENT ON COLUMN operacional.dim_tipo_fornecimento.codigo IS 'Código normalizado (UPPER, sem acento/espaços) - UNIQUE com índice automático';

-- =====================================================
-- Índices Finais em dim_tipo_fornecimento:
-- 1. dim_tipo_fornecimento_pkey (PRIMARY KEY em id_tipo)
-- 2. dim_tipo_fornecimento_codigo_key (UNIQUE em codigo) ✅ Gerado automaticamente
-- 3. idx_dim_tipo_fornecimento_ativo (INDEX em ativo) ✅ Útil para filtros
-- 
-- Removido:
-- ❌ idx_dim_tipo_fornecimento_codigo (redundante)
-- =====================================================

-- =====================================================
-- NOTA v1.0.2-HML:
-- - Índice redundante removido (performance otimizada)
-- - UNIQUE constraint garante índice automático
-- - Delimitador nominal $do$ conforme padrão
-- - Feedback via RAISE NOTICE
-- - Idempotente (re-execução segura)
-- =====================================================

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
