=====================================================
README_MIGRATIONS.md - ATUALIZAÇÃO v1.0.2-HML
Data: 06/11/2025
=====================================================

📝 ADICIONAR MIGRATION 018 NA ORDEM DE EXECUÇÃO
===============================================

SUBSTITUIR a seção "Ordem de Execução" por:

```
000_create_schemas.sql
001_auth_usuarios.sql
002_auth_sessoes.sql
003_auth_reset_tokens.sql
004_audit_core.sql
005_operacional_dim_tipo_fornecimento.sql
006_operacional_obras.sql
007_operacional_contratos.sql
008_financeiro_medicoes.sql
009_financeiro_notas_fiscais.sql
010_financeiro_pagamentos.sql
011_financeiro_glosas.sql
012_audit_auditoria_fin.sql
013_vw_pipeline.sql
014_vw_fluxocaixa.sql
015_auth_reset_tokens_patch.sql
016_cleanup_reset_tokens_indexes.sql
017_operacional_dim_tipo_fornecimento_cleanup.sql
018_operacional_obras_cleanup.sql
```

=====================================================

📝 ADICIONAR NA SEÇÃO "Novidades v1.0.2-HML"
===========================================

APÓS "Migration 017 (Nova)", ADICIONAR:

### Migration 006 (Hotfix)
- ✅ Índices com `IF NOT EXISTS` (idempotência total)
- ✅ Owner explícito `OWNER TO gbs_dev` (tabela + função)
- ✅ Delimitadores nominais `$fn$` e `$do$`
- ✅ Trigger idempotente (verificação pg_trigger)
- ✅ Sem breaking changes

### Migration 018 (Nova)
- 🧹 Limpeza de índice redundante em `operacional.obras`
- ✅ Remove `idx_obras_codigo` (redundante com UNIQUE)
- ✅ Mantém índices úteis (implantacao, cliente, tipo_fornecimento, ativo, gate_ativo)
- ✅ Garante constraint UNIQUE com índice automático
- ✅ Delimitador nominal `$do$`
- ✅ Feedback via `RAISE NOTICE`

=====================================================

📝 ATUALIZAR SEÇÃO "Verificar Índices (v1.0.2+)"
================================================

ADICIONAR após a verificação de dim_tipo_fornecimento:

```sql
-- Listar índices de operacional.obras (após 018)
SELECT indexname 
FROM pg_indexes 
WHERE schemaname = 'operacional' 
  AND tablename = 'obras'
ORDER BY indexname;
-- Esperado: obras_pkey, obras_codigo_obra_key, idx_obras_implantacao, idx_obras_cliente, 
--           idx_obras_tipo_fornecimento, idx_obras_ativo, idx_obras_gate_ativo
```

=====================================================

📝 ATUALIZAR HISTÓRICO DE VERSÕES
==================================

SUBSTITUIR linha de v1.0.2-HML por:

| v1.0.2-HML | 06/11/2025 | Hotfix 004+005+006 (idempotência), novas 016+017+018 (cleanup índices), delimitadores nominais |

=====================================================
USO INTERNO - CONFIDENCIAL
Globosul Engenharia | ti@globosul.com.br
Data: 06/11/2025
=====================================================
