-- =====================================================
-- Migration: 009_financeiro_notas_fiscais.sql
-- Sprint: 2 - Medições
-- Descrição: Tabela de notas fiscais no schema financeiro
-- Data: 06/11/2025 (refatorado para schemas)
-- =====================================================

-- Tabela de notas fiscais (schema financeiro)
-- Vínculo: 1 medição pode ter múltiplas NFs (1:N)
-- Identificação: chave_acesso (preferencial) ou trio (emitente_cnpj, serie, numero)
CREATE TABLE IF NOT EXISTS financeiro.notas_fiscais (
    id_nf UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- FK para medição (mesmo schema)
    id_medicao UUID NOT NULL 
        REFERENCES financeiro.medicoes(id_medicao)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    
    -- Identificação da NF (normalizado só-dígitos antes de persistir)
    numero_nf VARCHAR(20) NOT NULL,
    serie VARCHAR(10) NOT NULL,
    emitente_cnpj VARCHAR(14) NOT NULL, -- Somente dígitos (sem pontuação)
    
    -- Chave de acesso NFSe (preferencial para vínculo com pagamentos)
    chave_acesso VARCHAR(44), -- 44 caracteres padrão NFe/NFSe
    
    -- Valores e datas
    valor_nf NUMERIC(14,2) NOT NULL CHECK (valor_nf > 0),
    data_emissao_nf DATE NOT NULL,
    
    -- Tipo da NF (ex: NFe, NFSe, NFSe-Recife, etc)
    tipo_nf VARCHAR(50),
    
    -- Campos auxiliares
    descricao TEXT,
    xml_nf TEXT, -- XML completo da NF (opcional, para auditoria)
    
    -- Controle
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT uq_nf_numero UNIQUE (numero_nf),
    CONSTRAINT uq_nf_chave_acesso UNIQUE (chave_acesso),
    CONSTRAINT uq_nf_trio UNIQUE (emitente_cnpj, serie, numero_nf)
);

-- Índices para performance
CREATE INDEX idx_nf_medicao ON financeiro.notas_fiscais(id_medicao);
CREATE INDEX idx_nf_data_emissao ON financeiro.notas_fiscais(data_emissao_nf);
CREATE INDEX idx_nf_chave_acesso ON financeiro.notas_fiscais(chave_acesso) WHERE chave_acesso IS NOT NULL;

-- Índice composto para vínculo alternativo (trio)
CREATE INDEX idx_nf_trio ON financeiro.notas_fiscais(emitente_cnpj, serie, numero_nf);

-- Índice para queries de DSO (emissao + medicao)
CREATE INDEX idx_nf_dso ON financeiro.notas_fiscais(data_emissao_nf, id_medicao);

-- Comentários
COMMENT ON TABLE financeiro.notas_fiscais IS 'Notas fiscais emitidas - vínculo N:1 com medições (uma medição pode ter múltiplas NFs)';
COMMENT ON COLUMN financeiro.notas_fiscais.numero_nf IS 'Número da NF normalizado (só dígitos, sem letras/prefixos como M001)';
COMMENT ON COLUMN financeiro.notas_fiscais.emitente_cnpj IS 'CNPJ do emitente (só dígitos, 14 caracteres)';
COMMENT ON COLUMN financeiro.notas_fiscais.chave_acesso IS 'Chave de acesso NFSe (44 dígitos) - PREFERENCIAL para vínculo com pagamentos';
COMMENT ON COLUMN financeiro.notas_fiscais.tipo_nf IS 'Tipo da nota (NFe, NFSe, NFSe-Recife, etc)';
COMMENT ON COLUMN financeiro.notas_fiscais.xml_nf IS 'XML completo da NF (opcional, para auditoria e conferência)';

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION financeiro.update_notas_fiscais_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================

-- -------------------------------------------------------------------
-- HOTFIX v1.0.2-HML: idempotência de trigger + ownership explícito
-- -------------------------------------------------------------------
-- Ajusta owners (tabela/funcão) — não quebra se já estiver correto
DO $do$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class WHERE relname='notas_fiscais' AND relnamespace='financeiro'::regnamespace) THEN
    EXECUTE 'ALTER TABLE financeiro.notas_fiscais OWNER TO gbs_dev';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_proc
     WHERE proname='update_notas_fiscais_timestamp'
       AND pronamespace='financeiro'::regnamespace
  ) THEN
    EXECUTE 'ALTER FUNCTION financeiro.update_notas_fiscais_timestamp() OWNER TO gbs_dev';
  END IF;
END
$do$;

-- Cria a trigger somente se não existir (idempotente)
DO $do$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class WHERE relname='notas_fiscais' AND relnamespace='financeiro'::regnamespace)
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
        WHERE tgname  = 'trg_notas_fiscais_updated_at'
          AND tgrelid = 'financeiro.notas_fiscais'::regclass
     )
  THEN
    EXECUTE $$
      CREATE TRIGGER trg_notas_fiscais_updated_at
      BEFORE UPDATE ON financeiro.notas_fiscais
      FOR EACH ROW
      EXECUTE FUNCTION financeiro.update_notas_fiscais_timestamp()
    $$;
  END IF;
END
$do$;
