-- =====================================================
-- Migration: 018_operacional_obras_cleanup.sql
-- Sprint: 2 - Medições
-- Descrição: Remove índice redundante e garante ownership
-- Data: 06/11/2025
-- Versão: v1.0.2-HML
-- =====================================================

-- ============================================
-- Contexto:
-- A constraint UNIQUE em obras.codigo_obra
-- já cria automaticamente o índice obras_codigo_obra_key.
-- O índice idx_obras_codigo é redundante.
-- Esta migration remove a duplicata e garante estrutura correta.
-- ============================================

-- Garantir tabela existe e tem owner correto (inofensivo se já existir)
CREATE TABLE IF NOT EXISTS operacional.obras (
  id_obra UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_obra VARCHAR(50) NOT NULL,
  descricao TEXT NOT NULL,
  cliente VARCHAR(255) NOT NULL,
  implantacao_contrato DATE,
  tipo_fornecimento_id UUID,
  endereco TEXT,
  cidade VARCHAR(100),
  estado CHAR(2),
  ativo BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Owner explícito
ALTER TABLE IF EXISTS operacional.obras OWNER TO gbs_dev;

-- Garante constraint UNIQUE em codigo_obra (apenas se não existir)
-- Esta constraint cria automaticamente o índice obras_codigo_obra_key
DO $do$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'obras_codigo_obra_key'
      AND conrelid = 'operacional.obras'::regclass
  ) THEN
    ALTER TABLE operacional.obras
      ADD CONSTRAINT obras_codigo_obra_key UNIQUE (codigo_obra);
    RAISE NOTICE 'Constraint UNIQUE criada: obras_codigo_obra_key';
  END IF;
END
$do$;

-- Remove índice redundante (há UNIQUE que já cobre a coluna)
DO $do$
BEGIN
  IF EXISTS (
    SELECT 1 
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_obras_codigo'
      AND n.nspname = 'operacional'
  ) THEN
    EXECUTE 'DROP INDEX operacional.idx_obras_codigo';
    RAISE NOTICE 'Índice redundante removido: idx_obras_codigo';
  END IF;
END
$do$;

-- Garante índices úteis existem
CREATE INDEX IF NOT EXISTS idx_obras_implantacao 
    ON operacional.obras(implantacao_contrato) 
    WHERE implantacao_contrato IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_obras_cliente 
    ON operacional.obras(cliente);

CREATE INDEX IF NOT EXISTS idx_obras_tipo_fornecimento 
    ON operacional.obras(tipo_fornecimento_id);

CREATE INDEX IF NOT EXISTS idx_obras_ativo 
    ON operacional.obras(ativo);

CREATE INDEX IF NOT EXISTS idx_obras_gate_ativo 
    ON operacional.obras(implantacao_contrato, ativo) 
    WHERE implantacao_contrato IS NOT NULL AND ativo = true;

-- Comentários
COMMENT ON TABLE operacional.obras IS 'Obras da Globosul - índices otimizados (sem redundância)';
COMMENT ON COLUMN operacional.obras.codigo_obra IS 'Código único da obra - UNIQUE com índice automático';

-- =====================================================
-- Índices Finais em obras:
-- 1. obras_pkey (PRIMARY KEY em id_obra)
-- 2. obras_codigo_obra_key (UNIQUE em codigo_obra) ✅ Gerado automaticamente
-- 3. idx_obras_implantacao (INDEX parcial em implantacao_contrato)
-- 4. idx_obras_cliente (INDEX em cliente)
-- 5. idx_obras_tipo_fornecimento (INDEX em tipo_fornecimento_id)
-- 6. idx_obras_ativo (INDEX em ativo)
-- 7. idx_obras_gate_ativo (INDEX composto em implantacao_contrato, ativo)
-- 
-- Removido:
-- ❌ idx_obras_codigo (redundante)
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
