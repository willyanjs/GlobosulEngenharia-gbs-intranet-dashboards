-- =====================================================
-- View: 013_vw_pipeline.sql
-- Sprint: 2 - Medições
-- Descrição: Pipeline de medições no schema vw (cross-schema)
-- Data: 06/11/2025 (refatorado para schemas)
-- =====================================================

-- View do pipeline financeiro (schema vw)
-- Status calculado por milestones (datas), não pelo campo status armazenado
-- Hierarquia: PAGA > NF > APROVADA > ENVIADA > PREVISTA
-- CRÍTICO: Usa schemas qualificados (financeiro, operacional)
CREATE OR REPLACE VIEW vw.vw_pipeline AS
SELECT
    -- Identificação
    m.id_medicao,
    m.id_obra,
    m.id_contrato,
    m.competencia,
    
    -- Obra (schema operacional)
    o.codigo_obra,
    o.descricao AS descricao_obra,
    o.cliente,
    
    -- Contrato (pode ser NULL) (schema operacional)
    c.numero_contrato,
    c.valor_total AS valor_contrato,
    
    -- Tipo de fornecimento (apenas para filtro, não afeta KPIs) (schema operacional)
    tf.codigo AS tipo_fornecimento_codigo,
    tf.rotulo AS tipo_fornecimento_rotulo,
    
    -- Valores monetários
    m.valor_previsto,
    m.valor_glosado,
    m.valor_aprovado,
    
    -- Valor NF (soma de todas as NFs da medição) (schema financeiro)
    COALESCE(nf_sum.total_nf, 0) AS valor_nf,
    
    -- Valor pago (soma de todos os pagamentos da medição) (schema financeiro)
    COALESCE(pag_sum.total_pago, 0) AS valor_pago,
    
    -- Datas de marco (milestones)
    m.data_prevista,
    m.data_envio_relatorio,
    m.data_aprovacao_cliente,
    nf_sum.data_emissao_nf_min AS data_emissao_nf, -- Primeira NF emitida
    pag_sum.data_pagamento_min AS data_pagamento, -- Primeiro pagamento
    
    -- Status calculado (baseado em milestones, não no campo status)
    -- Hierarquia: PAGA > NF > APROVADA > ENVIADA > PREVISTA
    CASE
        WHEN pag_sum.total_pago > 0 AND pag_sum.data_pagamento_min IS NOT NULL THEN 'PAGA'
        WHEN nf_sum.data_emissao_nf_min IS NOT NULL THEN 'NF'
        WHEN m.data_aprovacao_cliente IS NOT NULL THEN 'APROVADA'
        WHEN m.data_envio_relatorio IS NOT NULL THEN 'ENVIADA'
        ELSE 'PREVISTA'
    END AS status_calculado,
    
    -- Substatus (ex: DEVOLVIDA quando há glosa sem aprovação)
    m.substatus,
    
    -- Indicadores
    CASE
        WHEN m.data_envio_relatorio IS NOT NULL THEN true
        ELSE false
    END AS foi_enviada,
    
    CASE
        WHEN m.data_aprovacao_cliente IS NOT NULL THEN true
        ELSE false
    END AS foi_aprovada,
    
    -- Saldo a receber (emitido - recebido)
    COALESCE(nf_sum.total_nf, 0) - COALESCE(pag_sum.total_pago, 0) AS saldo_receber,
    
    -- Observações
    m.observacoes,
    
    -- Controle
    m.created_at,
    m.updated_at

FROM financeiro.medicoes m
INNER JOIN operacional.obras o ON m.id_obra = o.id_obra
LEFT JOIN operacional.contratos c ON m.id_contrato = c.id_contrato
LEFT JOIN operacional.dim_tipo_fornecimento tf ON o.tipo_fornecimento_id = tf.id_tipo

-- Agregar NFs (múltiplas NFs por medição) (schema financeiro)
LEFT JOIN LATERAL (
    SELECT
        id_medicao,
        SUM(valor_nf) AS total_nf,
        MIN(data_emissao_nf) AS data_emissao_nf_min,
        COUNT(*) AS qtd_nfs
    FROM financeiro.notas_fiscais
    WHERE id_medicao = m.id_medicao
    GROUP BY id_medicao
) nf_sum ON true

-- Agregar pagamentos (múltiplas parcelas por medição) (schema financeiro)
LEFT JOIN LATERAL (
    SELECT
        id_medicao,
        SUM(valor_pago) AS total_pago,
        MIN(data_pagamento) AS data_pagamento_min,
        COUNT(*) AS qtd_pagamentos
    FROM financeiro.pagamentos
    WHERE id_medicao = m.id_medicao
      AND data_pagamento IS NOT NULL -- Só pagamentos efetivados
    GROUP BY id_medicao
) pag_sum ON true;

-- Comentários
COMMENT ON VIEW vw.vw_pipeline IS 'Pipeline de medições com status calculado por milestones (datas) - schemas: financeiro + operacional';

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
