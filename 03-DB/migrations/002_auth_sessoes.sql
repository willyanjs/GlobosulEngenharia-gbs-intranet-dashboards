-- =====================================================
-- Migration: 002_auth_sessoes.sql
-- Sprint: 1 - Auth & RBAC
-- Descrição: Tabela de sessões no schema auth
-- Data: 06/11/2025 (refatorado para schemas)
-- Versão: v1.0.1-HML (corrigido: índice sem função volátil)
-- =====================================================

-- ============================================
-- UP: Criação da Tabela de Sessões
-- ============================================

-- Tabela de sessões (schema auth)
CREATE TABLE IF NOT EXISTS auth.sessoes (
    id_sessao UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- FK para usuário (cross-schema está OK, mesmo schema auth)
    id_usuario UUID NOT NULL REFERENCES auth.usuarios(id_usuario) ON DELETE CASCADE,
    
    -- Token e controle
    token VARCHAR(255) NOT NULL UNIQUE,
    expira_em TIMESTAMPTZ NOT NULL,
    
    -- Auditoria
    ip_address INET,
    user_agent TEXT,
    
    -- Controle
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices otimizados (sem funções voláteis em predicados)

-- Acelera buscas por usuário
CREATE INDEX IF NOT EXISTS idx_sessoes_user_id 
    ON auth.sessoes (id_usuario);

-- Acelera busca de sessões ativas (token único)
CREATE INDEX IF NOT EXISTS idx_sessoes_token 
    ON auth.sessoes (token);

-- Acelera comparações por expiração feitas nas queries
-- (queries usarão: WHERE expira_em > now())
CREATE INDEX IF NOT EXISTS idx_sessoes_expires_at 
    ON auth.sessoes (expira_em);

-- Comentários
COMMENT ON TABLE auth.sessoes IS 'Sessões ativas - cookie httpOnly + SameSite=Strict';
COMMENT ON COLUMN auth.sessoes.token IS 'Token da sessão (hash único)';
COMMENT ON COLUMN auth.sessoes.expira_em IS 'Timestamp de expiração da sessão';

-- ============================================
-- DOWN: Rollback
-- ============================================

-- DROP INDEX IF EXISTS idx_sessoes_expires_at;
-- DROP INDEX IF EXISTS idx_sessoes_token;
-- DROP INDEX IF EXISTS idx_sessoes_user_id;
-- DROP TABLE IF EXISTS auth.sessoes CASCADE;

-- =====================================================
-- NOTA v1.0.1-HML:
-- Corrigido erro "functions in index predicate must be marked IMMUTABLE"
-- Removido índice parcial com CURRENT_TIMESTAMP no predicado
-- Criados índices sem funções voláteis (queries continuam usando WHERE expira_em > now())
-- =====================================================

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
