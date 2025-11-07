-- =====================================================
-- Migration: 004_audit_core.sql
-- Sprint: 1 - Auth & RBAC
-- Descrição: Tabela de auditoria de auth no schema audit
-- Data: 06/11/2025 (refatorado para schemas)
-- Versão: v1.0.2-HML (fix: delimitadores + idempotência)
-- =====================================================

-- Tabela de auditoria (schema audit)
-- Registra eventos críticos de autenticação e RBAC
CREATE TABLE IF NOT EXISTS audit.auditoria (
    id_auditoria UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identificação do usuário (FK opcional para auth.usuarios)
    id_usuario UUID, -- Pode ser NULL (tentativas de login falhadas)
    email_usuario VARCHAR(255), -- Email denormalizado para histórico
    
    -- Tipo de evento
    tipo_evento VARCHAR(50) NOT NULL, -- LOGIN, LOGOUT, RESET_PASSWORD, CREATE_USER, etc
    
    -- Detalhes do evento
    acao TEXT NOT NULL,
    alvo VARCHAR(255), -- Entidade afetada (ex: email do usuário)
    payload JSONB, -- Dados adicionais (ex: role anterior/novo)
    
    -- Contexto
    ip_address INET,
    user_agent TEXT,
    
    -- Timestamp
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices (idempotentes)
CREATE INDEX IF NOT EXISTS idx_auditoria_usuario 
    ON audit.auditoria(id_usuario) 
    WHERE id_usuario IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_auditoria_tipo_evento 
    ON audit.auditoria(tipo_evento);

CREATE INDEX IF NOT EXISTS idx_auditoria_created_at 
    ON audit.auditoria(created_at);

CREATE INDEX IF NOT EXISTS idx_auditoria_email 
    ON audit.auditoria(email_usuario);

-- Índice composto para queries de timeline por usuário
CREATE INDEX IF NOT EXISTS idx_auditoria_usuario_timeline 
    ON audit.auditoria(id_usuario, created_at) 
    WHERE id_usuario IS NOT NULL;

-- Índice GIN para busca em JSONB
CREATE INDEX IF NOT EXISTS idx_auditoria_payload_gin 
    ON audit.auditoria USING gin(payload);

-- Comentários
COMMENT ON TABLE audit.auditoria IS 'Auditoria de autenticação - eventos críticos de login, reset, CRUD de usuários';
COMMENT ON COLUMN audit.auditoria.tipo_evento IS 'Tipo de evento (LOGIN, LOGOUT, RESET_PASSWORD, CREATE_USER, UPDATE_USER, DELETE_USER, UNLOCK_USER)';
COMMENT ON COLUMN audit.auditoria.payload IS 'Dados adicionais em JSONB (ex: role anterior/novo, tentativa de login)';

-- Owner explícito
ALTER TABLE IF EXISTS audit.auditoria OWNER TO gbs_dev;

-- =====================================================
-- NOTA v1.0.2-HML:
-- - Índices agora com IF NOT EXISTS (idempotência total)
-- - Owner explícito para gbs_dev
-- - Sem blocos DO ou funções (arquivo já limpo)
-- - Pronto para re-execução sem erros
-- =====================================================

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
