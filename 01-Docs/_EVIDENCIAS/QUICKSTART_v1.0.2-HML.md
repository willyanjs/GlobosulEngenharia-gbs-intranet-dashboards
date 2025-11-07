# 🚀 QUICK START — v1.0.2-HML

**Versão:** v1.0.2-HML  
**Data:** 07/11/2025

---

## ⚡ APLICAÇÃO COMPLETA (RECOMENDADO)

```bash
# 1. Navegar para diretório de DB
cd "C:\Users\WillyanSilva\OneDrive - Globosul Engenharia\Documentos\GBS - Intranet & Dashboards\03-DB"

# 2. Configurar DATABASE_URL
export DATABASE_URL="postgresql://gbs_dev:senha@localhost:5432/gbs_intranet_prod"

# 3. Aplicar todas as migrations (000 → 018)
bash apply_migrations.sh

# 4. Verificar log
grep -E 'ordem:' logs/migrations.log
# Esperado: "Iniciando aplicação das migrations (ordem: 000 → 018)..."
```

---

## 🔍 VALIDAÇÕES RÁPIDAS

### Verificar índices em obras
```bash
psql "$DATABASE_URL" -tAc "
SELECT indexname 
FROM pg_indexes 
WHERE schemaname='operacional' 
  AND tablename='obras' 
ORDER BY indexname;
"
```

**Esperado (7 índices):**
- idx_obras_ativo
- idx_obras_cliente
- idx_obras_gate_ativo
- idx_obras_implantacao
- idx_obras_tipo_fornecimento
- obras_codigo_obra_key ← UNIQUE (automático)
- obras_pkey

**Ausente:**
- ❌ idx_obras_codigo (removido na 018)

---

### Testar idempotência
```bash
# Re-executar 006 (deve passar sem erros)
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -f migrations/006_operacional_obras.sql

# Re-executar 018 (deve passar sem erros)
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -f migrations/018_operacional_obras_cleanup.sql
```

---

### Verificar ownership
```bash
psql "$DATABASE_URL" -c "
SELECT 
  relname AS object,
  pg_get_userbyid(relowner) AS owner
FROM pg_class
WHERE relname IN ('obras', 'update_obras_timestamp')
  AND relnamespace = 'operacional'::regnamespace
ORDER BY relname;
"
```

**Esperado:**
- obras | gbs_dev
- update_obras_timestamp | gbs_dev

---

## 📊 DIAGNÓSTICO DE PERFORMANCE

### Tamanho dos índices
```bash
psql "$DATABASE_URL" -c "
SELECT 
  indexname,
  pg_size_pretty(pg_relation_size(
    'operacional.'||indexname
  )) AS size
FROM pg_indexes
WHERE schemaname = 'operacional'
  AND tablename = 'obras'
ORDER BY pg_relation_size('operacional.'||indexname) DESC;
"
```

---

## 🧪 TESTE FUNCIONAL (updated_at)

```bash
# 1. Criar obra de teste
psql "$DATABASE_URL" -c "
INSERT INTO operacional.obras 
  (codigo_obra, descricao, cliente, implantacao_contrato)
VALUES 
  ('OB-TEST-999', 'Teste', 'Cliente Teste', '2025-01-01')
RETURNING created_at, updated_at;
"

# 2. Aguardar 2 segundos
sleep 2

# 3. Atualizar obra
psql "$DATABASE_URL" -c "
UPDATE operacional.obras
SET descricao = 'Teste - Modificado'
WHERE codigo_obra = 'OB-TEST-999'
RETURNING created_at, updated_at;
"
# updated_at deve ser > created_at

# 4. Limpar
psql "$DATABASE_URL" -c "
DELETE FROM operacional.obras 
WHERE codigo_obra = 'OB-TEST-999';
"
```

---

## 🆘 TROUBLESHOOTING

### Erro: "relation already exists"
**Causa:** Migration já aplicada  
**Solução:** Normal, migrations são idempotentes

### Erro: "index already exists"
**Causa:** Índice já criado  
**Solução:** Verificar se migration usa `IF NOT EXISTS`

### Erro: "permission denied"
**Causa:** User sem privilégios  
**Solução:** Conectar como `gbs_dev`

### Índice idx_obras_codigo ainda presente
**Causa:** Migration 018 não foi aplicada  
**Solução:** Executar `bash apply_migrations.sh`

---

## 📚 DOCUMENTAÇÃO COMPLETA

| Arquivo | Localização |
|---------|-------------|
| **Changelog** | `01-Docs/CHANGELOG.md` |
| **Migrations README** | `03-DB/migrations/README_MIGRATIONS.md` |
| **Evidências** | `01-Docs/_EVIDENCIAS/` |
| **Estrutura** | `01-Docs/_EVIDENCIAS/TREE_MIGRATIONS_v1.0.2-HML.txt` |
| **Validações** | `01-Docs/_EVIDENCIAS/CHECKS_v1.0.2-HML.txt` |
| **Resumo Executivo** | `01-Docs/_EVIDENCIAS/RESUMO_EXECUTIVO_v1.0.2-HML.md` |

---

## ✅ CHECKLIST FINAL

- [ ] DATABASE_URL configurada
- [ ] Migrations aplicadas (000 → 018)
- [ ] Log verificado (ordem: 000 → 018)
- [ ] 7 índices em obras (idx_obras_codigo ausente)
- [ ] UNIQUE constraint obras_codigo_obra_key presente
- [ ] Trigger trg_obras_updated_at funcionando
- [ ] Owner gbs_dev em tabela e função
- [ ] Re-execução 006 sem erros
- [ ] Re-execução 018 sem erros

---

**USO INTERNO – CONFIDENCIAL**  
**Globosul Engenharia** | ti@globosul.com.br
