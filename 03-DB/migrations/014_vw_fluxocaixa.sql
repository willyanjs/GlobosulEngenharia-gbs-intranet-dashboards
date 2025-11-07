-- =====================================================
-- View: 014_vw_fluxocaixa.sql
-- Sprint: 2 - Medições
-- Descrição: Fluxo de caixa mensal no schema vw com KPIs
-- Data: 06/11/2025 (refatorado para schemas)
-- =====================================================

-- View de fluxo de caixa consolidado por mês (schema vw)
-- KPIs: DSO, Taxa de Aprovação, % Glosa
-- CRÍTICO: Usa schemas qualificados (financeiro, operacional)
CREATE OR REPLACE VIEW vw.vw_fluxocaixa AS
WITH medicoes_mes AS (
    -- Medições agrupadas por mês (schema financeiro)
    SELECT
        DATE_TRUNC('month', m.competencia)::DATE AS mes,
        m.id_medicao,
        m.valor_previsto,
        m.valor_glosado,
        m.valor_aprovado,
        m.data_envio_relatorio,
        m.data_aprovacao_cliente
    FROM financeiro.medicoes m
),

nfs_medicoes AS (
    -- NFs por medição com data de emissão (schema financeiro)
    SELECT
        mm.mes,
        nf.id_medicao,
        nf.numero_nf,
        nf.valor_nf,
        nf.data_emissao_nf
    FROM financeiro.notas_fiscais nf
    INNER JOIN medicoes_mes mm ON nf.id_medicao = mm.id_medicao
),

pagamentos_nfs AS (
    -- Pagamentos por NF com DSO calculado (schema financeiro)
    SELECT
        nm.mes,
        p.numero_nf,
        p.valor_pago,
        p.data_pagamento,
        nm.data_emissao_nf,
        -- DSO individual: dias entre emissão NF e pagamento
        CASE
            WHEN p.data_pagamento IS NOT NULL AND nm.data_emissao_nf IS NOT NULL
            THEN (p.data_pagamento - nm.data_emissao_nf)::INTEGER
            ELSE NULL
        END AS dias_dso
    FROM financeiro.pagamentos p
    INNER JOIN nfs_medicoes nm ON p.numero_nf = nm.numero_nf
    WHERE p.data_pagamento IS NOT NULL -- Só pagamentos efetivados
)

SELECT
    -- Mês de referência
    mm.mes,
    
    -- Valores agregados
    -- Previsto: soma de todas as medições do mês
    COALESCE(SUM(mm.valor_previsto), 0) AS previsto,
    
    -- Emitido: soma de todas as NFs das medições do mês
    COALESCE(SUM(nm.valor_nf), 0) AS emitido,
    
    -- Recebido: soma de todos os pagamentos das NFs das medições do mês
    COALESCE(SUM(pn.valor_pago), 0) AS recebido,
    
    -- Saldo a receber: emitido - recebido
    COALESCE(SUM(nm.valor_nf), 0) - COALESCE(SUM(pn.valor_pago), 0) AS saldo,
    
    -- % Recebido: (recebido / emitido) * 100
    CASE
        WHEN SUM(nm.valor_nf) > 0
        THEN ROUND((SUM(pn.valor_pago) / SUM(nm.valor_nf)) * 100, 2)
        ELSE 0
    END AS perc_recebido,
    
    -- DSO: média ponderada de dias (emissão NF → pagamento)
    -- DSO = ROUND(SUM(dias * valor_pago) / SUM(valor_pago))
    CASE
        WHEN SUM(pn.valor_pago) > 0
        THEN ROUND(SUM(pn.dias_dso * pn.valor_pago) / SUM(pn.valor_pago))
        ELSE NULL
    END AS dso,
    
    -- Taxa de aprovação: (COUNT aprovadas / COUNT enviadas+) * 100
    -- Enviadas+ = medições com data_envio_relatorio OU com NF/pagamento
    CASE
        WHEN COUNT(CASE WHEN mm.data_envio_relatorio IS NOT NULL THEN 1 END) > 0
        THEN ROUND(
            (COUNT(CASE WHEN mm.data_aprovacao_cliente IS NOT NULL THEN 1 END)::NUMERIC /
             COUNT(CASE WHEN mm.data_envio_relatorio IS NOT NULL THEN 1 END)::NUMERIC) * 100,
            2
        )
        ELSE 0
    END AS taxa_aprovacao,
    
    -- % Glosa: (SUM glosa / SUM enviado) * 100
    -- Enviado = valor_previsto das medições com data_envio_relatorio
    CASE
        WHEN SUM(CASE WHEN mm.data_envio_relatorio IS NOT NULL THEN mm.valor_previsto ELSE 0 END) > 0
        THEN ROUND(
            (SUM(CASE WHEN mm.data_envio_relatorio IS NOT NULL THEN mm.valor_glosado ELSE 0 END) /
             SUM(CASE WHEN mm.data_envio_relatorio IS NOT NULL THEN mm.valor_previsto ELSE 0 END)) * 100,
            2
        )
        ELSE 0
    END AS perc_glosa,
    
    -- Contadores
    COUNT(DISTINCT mm.id_medicao) AS qtd_medicoes,
    COUNT(DISTINCT nm.numero_nf) AS qtd_nfs,
    COUNT(DISTINCT pn.numero_nf) AS qtd_pagamentos_distintos,
    
    -- Medições por status (calculado)
    COUNT(CASE WHEN mm.data_envio_relatorio IS NULL THEN 1 END) AS qtd_previstas,
    COUNT(CASE
        WHEN mm.data_envio_relatorio IS NOT NULL
         AND mm.data_aprovacao_cliente IS NULL
        THEN 1
    END) AS qtd_enviadas,
    COUNT(CASE WHEN mm.data_aprovacao_cliente IS NOT NULL THEN 1 END) AS qtd_aprovadas

FROM medicoes_mes mm
LEFT JOIN nfs_medicoes nm ON mm.id_medicao = nm.id_medicao
LEFT JOIN pagamentos_nfs pn ON nm.numero_nf = pn.numero_nf

GROUP BY mm.mes
ORDER BY mm.mes DESC;

-- Comentários
COMMENT ON VIEW vw.vw_fluxocaixa IS 'Fluxo de caixa mensal consolidado com KPIs (DSO, taxa aprovação, % glosa) - schema: financeiro';

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
