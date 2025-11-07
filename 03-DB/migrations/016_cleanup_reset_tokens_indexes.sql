-- =====================================================
-- Migration: 016_cleanup_reset_tokens_indexes.sql
-- Sprint: 1 - Auth & RBAC
-- Descrição: Limpeza de índices legados/duplicados em auth.reset_tokens
-- Data: 06/11/2025
-- Versão: v1.0.2-HML
-- =====================================================

-- ============================================
-- Contexto:
-- Após a migration 015 (patch com usado_em/revogado_em),
-- alguns índices legados ficaram duplicados ou obsoletos.
-- Esta migration remove índices antigos mantendo apenas
-- os padronizados da 003 (versão corrigida).
-- ============================================

-- Índices mantidos (da 003 v1.0.1-HML):
--   idx_reset_tokens_user_id (id_usuario)
--   idx_reset_tokens_token (token)
--   idx_reset_tokens_expires_at (expira_em)
--   idx_reset_tokens_ativos (parcial: WHERE usado = false)
--
-- Índices removidos (legado/duplicados):
--   idx_reset_tokens_expira (duplicado de expires_at)
--   idx_reset_tokens_usuario (duplicado de user_id)
--   idx_reset_tokens_usado (coberto pelo parcial ativos)

DO $do$
BEGIN
  -- Drop silencioso dos índices legados
  IF EXISTS (
    SELECT 1 
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_reset_tokens_expira'
      AND n.nspname = 'auth'
  ) THEN
    EXECUTE 'DROP INDEX auth.idx_reset_tokens_expira';
    RAISE NOTICE 'Índice legado removido: idx_reset_tokens_expira';
  END IF;

  IF EXISTS (
    SELECT 1 
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_reset_tokens_usuario'
      AND n.nspname = 'auth'
  ) THEN
    EXECUTE 'DROP INDEX auth.idx_reset_tokens_usuario';
    RAISE NOTICE 'Índice legado removido: idx_reset_tokens_usuario';
  END IF;

  IF EXISTS (
    SELECT 1 
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_reset_tokens_usado'
      AND n.nspname = 'auth'
  ) THEN
    EXECUTE 'DROP INDEX auth.idx_reset_tokens_usado';
    RAISE NOTICE 'Índice legado removido: idx_reset_tokens_usado';
  END IF;

  -- Garantir que os índices padronizados existem
  -- (caso a 003 não tenha sido aplicada corretamente)
  
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_reset_tokens_user_id'
      AND n.nspname = 'auth'
  ) THEN
    CREATE INDEX idx_reset_tokens_user_id 
        ON auth.reset_tokens (id_usuario);
    RAISE NOTICE 'Índice padrão criado: idx_reset_tokens_user_id';
  END IF;

  IF NOT EXISTS (
    SELECT 1 
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_reset_tokens_expires_at'
      AND n.nspname = 'auth'
  ) THEN
    CREATE INDEX idx_reset_tokens_expires_at 
        ON auth.reset_tokens (expira_em);
    RAISE NOTICE 'Índice padrão criado: idx_reset_tokens_expires_at';
  END IF;

  RAISE NOTICE 'Limpeza de índices de auth.reset_tokens concluída';
END
$do$;

-- Comentários
COMMENT ON TABLE auth.reset_tokens IS 'Tokens de reset de senha - índices padronizados via 016';

-- =====================================================
-- NOTA v1.0.2-HML:
-- - Remove índices duplicados/legados
-- - Garante que índices padronizados existem
-- - Idempotente (pode ser re-executada)
-- - Delimitador nominal $do$ conforme padrão
-- =====================================================

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
