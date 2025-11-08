-- =====================================================
-- Migration: 011_financeiro_glosas.sql
-- Sprint: 2 - Medições
-- Descrição: Tabela de glosas no schema financeiro
-- Data: 06/11/2025 (refatorado para schemas)
-- =====================================================

-- Tabela de glosas (schema financeiro)
-- Glosa não altera valor_previsto; define valor_aprovado = previsto - glosado
-- % glosa calculada sobre o "enviado" (medições com data_envio_relatorio)
CREATE TABLE IF NOT EXISTS financeiro.glosas (
    id_glosa UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- FK para medição (mesmo schema)
    id_medicao UUID NOT NULL 
        REFERENCES financeiro.medicoes(id_medicao)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    
    -- Valor e justificativa
    valor_glosa NUMERIC(14,2) NOT NULL CHECK (valor_glosa >= 0),
    motivo TEXT NOT NULL,
    
    -- Data de registro da glosa
    data_registro DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- Campos auxiliares
    responsavel VARCHAR(255), -- Quem identificou/registrou a glosa
    categoria VARCHAR(100), -- Ex: QUALIDADE, PRAZO, DOCUMENTACAO, OUTROS
    observacoes TEXT,
    
    -- Controle
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_glosas_medicao ON financeiro.glosas(id_medicao);
CREATE INDEX IF NOT EXISTS idx_glosas_data_registro ON financeiro.glosas(data_registro);
CREATE INDEX IF NOT EXISTS idx_glosas_categoria ON financeiro.glosas(categoria) WHERE categoria IS NOT NULL;

-- Índice composto para agregações de KPI (medicao + valor)
CREATE INDEX IF NOT EXISTS idx_glosas_kpi ON financeiro.glosas(id_medicao, valor_glosa);

-- Comentários
COMMENT ON TABLE financeiro.glosas IS 'Glosas (valores rejeitados) - não altera valor_previsto, define valor_aprovado';
COMMENT ON COLUMN financeiro.glosas.valor_glosa IS 'Valor glosado/rejeitado pelo cliente (≥0)';
COMMENT ON COLUMN financeiro.glosas.motivo IS 'Justificativa da glosa (obrigatório)';
COMMENT ON COLUMN financeiro.glosas.data_registro IS 'Data de registro da glosa (padrão: hoje)';
COMMENT ON COLUMN financeiro.glosas.categoria IS 'Categoria da glosa (QUALIDADE, PRAZO, DOCUMENTACAO, OUTROS)';

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION financeiro.update_glosas_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Trigger para atualizar valor_glosado na medição quando glosa é inserida/atualizada
CREATE OR REPLACE FUNCTION financeiro.sync_glosa_to_medicao()
RETURNS TRIGGER AS $$
BEGIN
    -- Recalcular soma de glosas para a medição
    UPDATE financeiro.medicoes
    SET valor_glosado = (
        SELECT COALESCE(SUM(valor_glosa), 0)
        FROM financeiro.glosas
        WHERE id_medicao = NEW.id_medicao
    )
    WHERE id_medicao = NEW.id_medicao;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Trigger para atualizar medição quando glosa é deletada
CREATE OR REPLACE FUNCTION financeiro.sync_glosa_delete_to_medicao()
RETURNS TRIGGER AS $$
BEGIN
    -- Recalcular soma de glosas para a medição
    UPDATE financeiro.medicoes
    SET valor_glosado = (
        SELECT COALESCE(SUM(valor_glosa), 0)
        FROM financeiro.glosas
        WHERE id_medicao = OLD.id_medicao
    )
    WHERE id_medicao = OLD.id_medicao;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
