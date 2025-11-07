-- =====================================================
-- Migration: 003_auth_reset_tokens.sql
-- Sprint: 1 - Auth & RBAC
-- Descrição: Tabela de tokens de reset de senha no schema auth
-- Data: 06/11/2025 (refatorado para schemas)
-- Versão: v1.0.1-HML (corrigido: índice sem função volátil)
-- =====================================================

-- ============================================
-- UP: Criação da Tabela de Reset Tokens
-- ============================================

-- Tabela de tokens de reset de senha (schema auth)
CREATE TABLE IF NOT EXISTS auth.reset_tokens (
    id_token UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- FK para usuário
    id_usuario UUID NOT NULL REFERENCES auth.usuarios(id_usuario) ON DELETE CASCADE,
    
    -- Token e controle
    token VARCHAR(255) NOT NULL UNIQUE,
    expira_em TIMESTAMPTZ NOT NULL,
    usado BOOLEAN NOT NULL DEFAULT false,
    
    -- Auditoria
    ip_solicitacao INET,
    usado_em TIMESTAMPTZ,
    ip_uso INET,
    
    -- Controle
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices otimizados (sem funções voláteis em predicados)

-- Acelera buscas por usuário
CREATE INDEX IF NOT EXISTS idx_reset_tokens_user_id 
    ON auth.reset_tokens (id_usuario);

-- Acelera busca por token (já tem UNIQUE, mas índice explícito melhora performance)
CREATE INDEX IF NOT EXISTS idx_reset_tokens_token 
    ON auth.reset_tokens (token);

-- Acelera comparações por expiração feitas nas queries
-- (queries usarão: WHERE expira_em > now())
CREATE INDEX IF NOT EXISTS idx_reset_tokens_expires_at 
    ON auth.reset_tokens (expira_em);

-- Índice parcial "estável" para tokens ativos (não usados e não expirados)
-- Predicado usa apenas colunas (imutável), sem now()/CURRENT_TIMESTAMP
-- Queries fazem: WHERE usado = false AND expira_em > now()
CREATE INDEX IF NOT EXISTS idx_reset_tokens_ativos 
    ON auth.reset_tokens (id_usuario, expira_em)
    WHERE usado = false;

-- Comentários
COMMENT ON TABLE auth.reset_tokens IS 'Tokens de reset de senha - one-time use, TTL 1 hora';
COMMENT ON COLUMN auth.reset_tokens.token IS 'Token único para reset (hash)';
COMMENT ON COLUMN auth.reset_tokens.usado IS 'Flag de uso (one-time only)';
COMMENT ON COLUMN auth.reset_tokens.expira_em IS 'Timestamp de expiração (TTL 1 hora)';
COMMENT ON COLUMN auth.reset_tokens.usado_em IS 'Timestamp de quando o token foi usado';

-- ============================================
-- DOWN: Rollback
-- ============================================

-- DROP INDEX IF EXISTS idx_reset_tokens_ativos;
-- DROP INDEX IF EXISTS idx_reset_tokens_expires_at;
-- DROP INDEX IF EXISTS idx_reset_tokens_token;
-- DROP INDEX IF EXISTS idx_reset_tokens_user_id;
-- DROP TABLE IF EXISTS auth.reset_tokens CASCADE;

-- =====================================================
-- NOTA v1.0.1-HML:
-- Corrigido erro "functions in index predicate must be marked IMMUTABLE"
-- Removido índice parcial com CURRENT_TIMESTAMP no predicado
-- Criados índices sem funções voláteis (queries continuam usando WHERE expira_em > now())
-- Adicionado índice parcial estável para tokens ativos (WHERE usado = false)
-- =====================================================

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
