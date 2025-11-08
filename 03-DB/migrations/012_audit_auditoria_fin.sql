-- =====================================================
-- Migration: 012_audit_auditoria_fin.sql
-- Sprint: 2 - Medições
-- Descrição: Auditoria financeira no schema audit
-- Data: 06/11/2025 (refatorado para schemas)
-- =====================================================

-- Tabela de auditoria financeira (schema audit)
-- Registra todas operações CRUD e transições de status em medições/NFs/pagamentos/glosas
CREATE TABLE IF NOT EXISTS audit.auditoria_fin (
    id_auditoria UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identificação do usuário responsável (FK opcional para auth.usuarios)
    -- FK cross-schema para auth
    user_id UUID, -- Pode ser NULL (operações do sistema/job)
    user_email VARCHAR(255), -- Email do usuário (denormalizado para histórico)
    
    -- Ação e entidade
    acao VARCHAR(50) NOT NULL, -- INSERT, UPDATE, DELETE, TRANSITION
    entidade VARCHAR(50) NOT NULL, -- medicoes, notas_fiscais, pagamentos, glosas
    entidade_id VARCHAR(100) NOT NULL, -- UUID da entidade afetada
    
    -- Payload (estado antes/depois)
    antes JSONB, -- Estado anterior (NULL em INSERT)
    depois JSONB, -- Estado posterior (NULL em DELETE)
    
    -- Campos auxiliares
    rota VARCHAR(255), -- Rota da API que gerou o evento (ex: PATCH /v1/medicoes/:id)
    ip_address INET, -- IP do cliente
    user_agent TEXT, -- User agent do cliente
    
    -- Timestamp
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_auditoria_fin_user ON audit.auditoria_fin(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_auditoria_fin_acao ON audit.auditoria_fin(acao);
CREATE INDEX IF NOT EXISTS idx_auditoria_fin_entidade ON audit.auditoria_fin(entidade);
CREATE INDEX IF NOT EXISTS idx_auditoria_fin_entidade_id ON audit.auditoria_fin(entidade_id);
CREATE INDEX IF NOT EXISTS idx_auditoria_fin_created_at ON audit.auditoria_fin(created_at);

-- Índice composto para queries comuns (entidade + id + data)
CREATE INDEX IF NOT EXISTS idx_auditoria_fin_timeline ON audit.auditoria_fin(entidade, entidade_id, created_at);

-- Índice GIN para busca em JSONB
CREATE INDEX IF NOT EXISTS idx_auditoria_fin_antes_gin ON audit.auditoria_fin USING gin(antes);
CREATE INDEX IF NOT EXISTS idx_auditoria_fin_depois_gin ON audit.auditoria_fin USING gin(depois);

-- Comentários
COMMENT ON TABLE audit.auditoria_fin IS 'Auditoria financeira - registra CRUD e transições em medições/NFs/pagamentos/glosas';
COMMENT ON COLUMN audit.auditoria_fin.acao IS 'Tipo de ação (INSERT, UPDATE, DELETE, TRANSITION)';
COMMENT ON COLUMN audit.auditoria_fin.entidade IS 'Nome da tabela afetada (medicoes, notas_fiscais, pagamentos, glosas)';
COMMENT ON COLUMN audit.auditoria_fin.entidade_id IS 'UUID da linha afetada';
COMMENT ON COLUMN audit.auditoria_fin.antes IS 'Estado anterior da entidade (NULL em INSERT)';
COMMENT ON COLUMN audit.auditoria_fin.depois IS 'Estado posterior da entidade (NULL em DELETE)';
COMMENT ON COLUMN audit.auditoria_fin.rota IS 'Rota da API que gerou o evento';

-- Política de retenção: 18 meses online + arquivamento
COMMENT ON TABLE audit.auditoria_fin IS 'Auditoria financeira - Retenção: 18 meses online + 24 meses arquivo';

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
