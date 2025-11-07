-- =====================================================
-- Migration: 007_operacional_contratos.sql
-- Sprint: 2 - Medições
-- Descrição: Tabela de contratos no schema operacional
-- Data: 06/11/2025 (refatorado para schemas)
-- =====================================================

-- Tabela de contratos (schema operacional)
-- Obrigatório vínculo com obra; uma obra pode ter múltiplos contratos ao longo do tempo
CREATE TABLE IF NOT EXISTS operacional.contratos (
    id_contrato UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- FK para obra (mesmo schema)
    id_obra UUID NOT NULL 
        REFERENCES operacional.obras(id_obra)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    
    -- Identificação do contrato
    numero_contrato VARCHAR(100) NOT NULL,
    id_cliente_exati VARCHAR(50), -- ID do cliente no sistema Exati (para integração futura)
    
    -- Valores e vigência
    valor_total NUMERIC(14,2) NOT NULL CHECK (valor_total >= 0),
    vigencia_inicio DATE NOT NULL,
    vigencia_fim DATE NOT NULL,
    
    -- Campos auxiliares
    objeto TEXT,
    observacoes TEXT,
    
    -- Controle
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Validação: data fim deve ser posterior ou igual ao início
    CONSTRAINT chk_contratos_vigencia CHECK (vigencia_fim >= vigencia_inicio)
);

-- Índices para performance
CREATE INDEX idx_contratos_obra ON operacional.contratos(id_obra);
CREATE INDEX idx_contratos_numero ON operacional.contratos(numero_contrato);
CREATE INDEX idx_contratos_vigencia ON operacional.contratos(vigencia_inicio, vigencia_fim);
CREATE INDEX idx_contratos_cliente_exati ON operacional.contratos(id_cliente_exati) 
    WHERE id_cliente_exati IS NOT NULL;
CREATE INDEX idx_contratos_ativo ON operacional.contratos(ativo);

-- Índice composto para busca de contratos vigentes de uma obra
CREATE INDEX idx_contratos_obra_vigencia ON operacional.contratos(id_obra, vigencia_inicio, vigencia_fim) 
    WHERE ativo = true;

-- Comentários
COMMENT ON TABLE operacional.contratos IS 'Contratos de obras - uma obra pode ter múltiplos contratos ao longo do tempo';
COMMENT ON COLUMN operacional.contratos.numero_contrato IS 'Número do contrato (formato livre, ex: CNT-2025-001)';
COMMENT ON COLUMN operacional.contratos.id_cliente_exati IS 'ID do cliente no sistema Exati para integração futura';
COMMENT ON COLUMN operacional.contratos.valor_total IS 'Valor total do contrato em reais (2 casas decimais)';

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION operacional.update_contratos_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_contratos_updated_at
    BEFORE UPDATE ON operacional.contratos
    FOR EACH ROW
    EXECUTE FUNCTION operacional.update_contratos_timestamp();

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
