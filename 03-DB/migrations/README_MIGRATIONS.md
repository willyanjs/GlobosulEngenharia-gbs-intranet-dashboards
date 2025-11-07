# Migrations – v1.0.2-HML

**Projeto:** GBS | Intranet & Dashboards  
**Versão:** v1.0.2-HML  
**Banco:** gbs_intranet_prod (PostgreSQL 16+)  
**Última atualização:** 06/11/2025

---

## 📋 Ordem de Execução

As migrations devem ser aplicadas **estritamente nesta ordem**:

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

---

## 🆕 Novidades v1.0.2-HML

### Migration 004 (Hotfix)
- ✅ Índices com `IF NOT EXISTS` (idempotência total)
- ✅ Owner explícito `OWNER TO gbs_dev`
- ✅ Sem breaking changes

### Migration 005 (Hotfix)
- ✅ Índices com `IF NOT EXISTS` (idempotência total)
- ✅ Owner explícito `OWNER TO gbs_dev` (tabela + função)
- ✅ Delimitadores nominais `$fn$` e `$do$`
- ✅ Trigger idempotente (verificação pg_trigger)
- ✅ Sem breaking changes

### Migration 016 (Nova)
- 🧹 Limpeza de índices legados em `auth.reset_tokens`
- ✅ Remove duplicatas: `idx_reset_tokens_expira`, `idx_reset_tokens_usuario`, `idx_reset_tokens_usado`
- ✅ Garante índices padrão: `idx_reset_tokens_user_id`, `idx_reset_tokens_expires_at`
- ✅ Delimitador nominal `$do$`
- ✅ Feedback via `RAISE NOTICE`

### Migration 017 (Nova)
- 🧹 Limpeza de índice redundante em `operacional.dim_tipo_fornecimento`
- ✅ Remove `idx_dim_tipo_fornecimento_codigo` (redundante com UNIQUE)
- ✅ Mantém `idx_dim_tipo_fornecimento_ativo` (útil para filtros)
- ✅ Garante constraint UNIQUE com índice automático
- ✅ Delimitador nominal `$do# Migrations – v1.0.2-HML

**Projeto:** GBS | Intranet & Dashboards  
**Versão:** v1.0.2-HML  
**Banco:** gbs_intranet_prod (PostgreSQL 16+)  
**Última atualização:** 06/11/2025

---

## 📋 Ordem de Execução

As migrations devem ser aplicadas **estritamente nesta ordem**:

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

---

## 🆕 Novidades v1.0.2-HML

### Migration 004 (Hotfix)
- ✅ Índices com `IF NOT EXISTS` (idempotência total)
- ✅ Owner explícito `OWNER TO gbs_dev`
- ✅ Sem breaking changes

### Migration 005 (Hotfix)
- ✅ Índices com `IF NOT EXISTS` (idempotência total)
- ✅ Owner explícito `OWNER TO gbs_dev` (tabela + função)
- ✅ Delimitadores nominais `$fn$` e `$do$`
- ✅ Trigger idempotente (verificação pg_trigger)
- ✅ Sem breaking changes

### Migration 016 (Nova)
- 🧹 Limpeza de índices legados em `auth.reset_tokens`
- ✅ Remove duplicatas: `idx_reset_tokens_expira`, `idx_reset_tokens_usuario`, `idx_reset_tokens_usado`
- ✅ Garante índices padrão: `idx_reset_tokens_user_id`, `idx_reset_tokens_expires_at`
- ✅ Delimitador nominal `$do$`
- ✅ Feedback via `RAISE NOTICE`


- ✅ Feedback via `RAISE NOTICE`

### Migration 018 (Nova)
- 🧹 Limpeza de índice redundante em `operacional.obras`
- ✅ Remove `idx_obras_codigo` (redundante com UNIQUE em `codigo_obra`)
- ✅ Mantém índices úteis: `idx_obras_implantacao`, `idx_obras_cliente`, `idx_obras_tipo_fornecimento`, `idx_obras_ativo`, `idx_obras_gate_ativo`
- ✅ Garante constraint UNIQUE em `codigo_obra` com índice automático `obras_codigo_obra_key`
- ✅ Delimitador nominal `$do# Migrations – v1.0.2-HML

**Projeto:** GBS | Intranet & Dashboards  
**Versão:** v1.0.2-HML  
**Banco:** gbs_intranet_prod (PostgreSQL 16+)  
**Última atualização:** 06/11/2025

---

## 📋 Ordem de Execução

As migrations devem ser aplicadas **estritamente nesta ordem**:

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

---

## 🆕 Novidades v1.0.2-HML

### Migration 004 (Hotfix)
- ✅ Índices com `IF NOT EXISTS` (idempotência total)
- ✅ Owner explícito `OWNER TO gbs_dev`
- ✅ Sem breaking changes

### Migration 005 (Hotfix)
- ✅ Índices com `IF NOT EXISTS` (idempotência total)
- ✅ Owner explícito `OWNER TO gbs_dev` (tabela + função)
- ✅ Delimitadores nominais `$fn$` e `$do$`
- ✅ Trigger idempotente (verificação pg_trigger)
- ✅ Sem breaking changes

### Migration 016 (Nova)
- 🧹 Limpeza de índices legados em `auth.reset_tokens`
- ✅ Remove duplicatas: `idx_reset_tokens_expira`, `idx_reset_tokens_usuario`, `idx_reset_tokens_usado`
- ✅ Garante índices padrão: `idx_reset_tokens_user_id`, `idx_reset_tokens_expires_at`
- ✅ Delimitador nominal `$do$`
- ✅ Feedback via `RAISE NOTICE`


- ✅ Feedback via `RAISE NOTICE`
- ✅ Idempotente: pode ser re-executada sem erros

---

## ⚙️ Padrões Obrigatórios

Todas as migrations devem seguir rigorosamente estas regras:

### 1. Schema Qualificado
- ✅ **SEMPRE** qualificar objetos com schema: `operacional.obras`, `financeiro.medicoes`
- ❌ **NUNCA** usar `public` ou objetos sem schema
- ❌ **NUNCA** usar `CREATE TABLE obras` (sem schema)

**Exemplo correto:**
```sql
CREATE TABLE IF NOT EXISTS operacional.obras (
  id_obra UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo VARCHAR(50) NOT NULL UNIQUE,
  ...
);
```

### 2. Foreign Keys Cross-Schema
Todas as FKs entre schemas diferentes devem incluir:
- `ON UPDATE CASCADE`: propaga mudanças de PK
- `ON DELETE RESTRICT`: previne exclusão acidental (ou `SET NULL` quando aplicável)

**Exemplo correto:**
```sql
ALTER TABLE financeiro.medicoes
  ADD CONSTRAINT fk_medicoes_obra
  FOREIGN KEY (id_obra)
  REFERENCES operacional.obras(id_obra)
  ON UPDATE CASCADE
  ON DELETE RESTRICT;
```

### 3. Views
- ✅ Views devem ser criadas **APENAS** no schema `vw.*`
- ❌ Views fora de `vw.*` serão rejeitadas pelo script de aplicação

**Exemplo correto:**
```sql
CREATE OR REPLACE VIEW vw.vw_pipeline AS
SELECT
  m.id_medicao,
  o.codigo_obra,
  ...
FROM financeiro.medicoes m
INNER JOIN operacional.obras o ON m.id_obra = o.id_obra;
```

### 4. Idempotência
Todas as migrations devem ser **idempotentes** e incluir seções UP e DOWN:

```sql
-- ============================================
-- UP: Criação/Alteração
-- ============================================
CREATE SCHEMA IF NOT EXISTS operacional;
CREATE TABLE IF NOT EXISTS operacional.obras (...);

-- ============================================
-- DOWN: Rollback
-- ============================================
DROP TABLE IF EXISTS operacional.obras CASCADE;
DROP SCHEMA IF EXISTS operacional CASCADE;
```

### 5. Proibição de `public`
- O schema `public` **NÃO DEVE SER UTILIZADO**
- Objetos em `public` causarão falha na aplicação do script
- O script `apply_migrations.sh` bloqueia automaticamente uso de `public`

### 6. Delimitadores Nominais (v1.0.2+)
Usar delimitadores nominais para funções e blocos DO:

```sql
-- Função PL/pgSQL
CREATE OR REPLACE FUNCTION audit.funcao()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
BEGIN
  -- corpo
  RETURN NEW;
END;
$fn$;

-- Bloco DO
DO $do$
BEGIN
  -- corpo
END
$do$;
```

---

## 🗄️ Pré-requisitos do Ambiente

### Banco de Dados
```sql
-- Nome do banco
gbs_intranet_prod

-- Versão mínima
PostgreSQL 16+
```

### Roles (Hierarquia)
```sql
-- Roles obrigatórias
gbs_admin  -- Owner de todos os schemas e objetos
gbs_rw     -- Read-Write (aplicações)
gbs_ro     -- Read-Only (consultas, dashboards)
gbs_app    -- Aplicação backend
gbs_dev    -- Desenvolvimento
```

### Schemas Base
Os seguintes schemas devem existir antes da aplicação:
```sql
auth           -- Autenticação e RBAC
operacional    -- Obras, contratos, fornecimento
financeiro     -- Medições, NFs, pagamentos, glosas
comercial      -- (reservado para futuro)
programacao    -- (reservado para futuro)
staging        -- Dados temporários/staging
vw             -- Views agregadas e KPIs
audit          -- Auditoria de eventos
```

### Revogação de `public`
```sql
-- O schema public deve estar bloqueado
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
```

---

## 📊 Tabelas por Schema

### Schema: `auth`
| Tabela | Descrição |
|--------|-----------|
| `usuarios` | Usuários do sistema (login, senha hash, RBAC) |
| `sessoes` | Sessões ativas (cookie httpOnly) |
| `reset_tokens` | Tokens de reset de senha (TTL 1h, campos temporais v1.0.2+) |

### Schema: `operacional`
| Tabela | Descrição |
|--------|-----------|
| `dim_tipo_fornecimento` | Catálogo de tipos de fornecimento (índices otimizados v1.0.2+) |
| `obras` | Obras/projetos (código, cliente, tipo) |
| `contratos` | Contratos vinculados a obras |

### Schema: `financeiro`
| Tabela | Descrição |
|--------|-----------|
| `medicoes` | Medições mensais (pipeline financeiro) |
| `notas_fiscais` | Notas fiscais emitidas (1:N com medições) |
| `pagamentos` | Pagamentos/parcelas (1:N com NFs) |
| `glosas` | Glosas/rejeições de valores (1:N com medições) |

### Schema: `audit`
| Tabela | Descrição |
|--------|-----------|
| `auditoria` | Auditoria geral (login, reset, eventos) |
| `auditoria_fin` | Auditoria financeira (CRUD + transições) |

### Schema: `vw` (Views)
| View | Descrição |
|------|-----------|
| `vw_pipeline` | Pipeline de medições com status calculado |
| `vw_fluxocaixa` | Fluxo de caixa mensal com KPIs (DSO, taxa aprovação, % glosa) |

---

## 🔑 Convenções de PK/FK

### Primary Keys
- **Formato:** `id_<nome_tabela>` (singular)
- **Tipo:** UUID (gerado via `gen_random_uuid()`) ou `bigserial`

**Exemplos:**
```sql
id_usuario UUID PRIMARY KEY DEFAULT gen_random_uuid()
id_obra UUID PRIMARY KEY DEFAULT gen_random_uuid()
id_medicao UUID PRIMARY KEY DEFAULT gen_random_uuid()
```

### Foreign Keys
- **Formato:** `fk_<tabela_origem>_<tabela_destino>`
- **Constraints:** `ON UPDATE CASCADE ON DELETE RESTRICT`

**Exemplos:**
```sql
CONSTRAINT fk_medicoes_obra
  FOREIGN KEY (id_obra)
  REFERENCES operacional.obras(id_obra)
  ON UPDATE CASCADE
  ON DELETE RESTRICT
```

---

## 🔐 Grants (DEFAULT PRIVILEGES)

As permissões são gerenciadas via `DEFAULT PRIVILEGES`:

### Schema: `vw` (Views)
```sql
-- gbs_ro, gbs_rw: SELECT (leitura)
-- gbs_admin: SELECT + CREATE VIEW (apenas admin cria views)
-- gbs_app: SELECT (leitura para API)
```

### Schema: `auth`, `operacional`, `financeiro`, `audit`
```sql
-- gbs_ro: SELECT
-- gbs_rw: SELECT, INSERT, UPDATE, DELETE + USAGE/UPDATE em sequências
-- gbs_admin: ALL PRIVILEGES
-- gbs_app: SELECT, INSERT, UPDATE, DELETE (aplicação backend)
```

---

## 🧪 Testes Rápidos (psql)

Após aplicar as migrations, execute os comandos abaixo para validação:

### 1. Listar Objetos por Schema
```bash
# Tabelas do schema auth
\dt auth.*

# Tabelas do schema operacional
\dt operacional.*

# Tabelas do schema financeiro
\dt financeiro.*

# Views do schema vw
\dv vw.*

# Verificar que public está vazio
\dt public.*
```

### 2. Testar Views
```sql
-- Pipeline de medições
SELECT * FROM vw.vw_pipeline LIMIT 1;

-- Fluxo de caixa
SELECT * FROM vw.vw_fluxocaixa LIMIT 1;
```

### 3. Validar Permissões (gbs_app)
```sql
-- Deve ter SELECT nas views
SET ROLE gbs_app;
SELECT * FROM vw.vw_pipeline LIMIT 1;  -- ✅ Sucesso

-- NÃO deve poder criar views
CREATE VIEW vw.teste AS SELECT 1;  -- ❌ Permission denied
```

### 4. Verificar FKs Cross-Schema
```sql
-- Verificar constraints de FK
SELECT
  conname AS constraint_name,
  conrelid::regclass AS table_name,
  confrelid::regclass AS referenced_table,
  confupdtype AS on_update,
  confdeltype AS on_delete
FROM pg_constraint
WHERE contype = 'f'
  AND connamespace::regnamespace::text IN ('financeiro', 'operacional')
ORDER BY conrelid::regclass;
```

### 5. Verificar Índices (v1.0.2+)
```sql
-- Listar índices de auth.reset_tokens (após 016)
SELECT indexname 
FROM pg_indexes 
WHERE schemaname = 'auth' 
  AND tablename = 'reset_tokens'
ORDER BY indexname;
-- Esperado: idx_reset_tokens_user_id, _token, _expires_at, _ativos, _pkey

-- Listar índices de operacional.dim_tipo_fornecimento (após 017)
SELECT indexname 
FROM pg_indexes 
WHERE schemaname = 'operacional' 
  AND tablename = 'dim_tipo_fornecimento'
ORDER BY indexname;
-- Esperado: dim_tipo_fornecimento_pkey, dim_tipo_fornecimento_codigo_key, idx_dim_tipo_fornecimento_ativo
```

---

## 🚨 Troubleshooting

### Erro: "permission denied for schema X"
**Causa:** Schema com owner incorreto  
**Solução:**
```sql
ALTER SCHEMA auth OWNER TO gbs_admin;
ALTER SCHEMA operacional OWNER TO gbs_admin;
ALTER SCHEMA financeiro OWNER TO gbs_admin;
ALTER SCHEMA vw OWNER TO gbs_admin;
ALTER SCHEMA audit OWNER TO gbs_admin;
```

### Erro: "relation X already exists"
**Causa:** Migration não idempotente  
**Solução:**
- Adicionar `IF NOT EXISTS` nas criações (UP)
- Adicionar `IF EXISTS` nas remoções (DOWN)
- Garantir que a migration pode ser executada múltiplas vezes sem falhar

### Erro: "violates foreign key constraint"
**Causa:** Ordem incorreta de aplicação das migrations  
**Solução:**
- Seguir **estritamente** a ordem 000→017
- Garantir que schemas base (000) são criados primeiro
- Operacional (005-007) antes de financeiro (008-011)
- Views (013-014) antes de patches (015-017)

### Erro: "cannot drop schema X because other objects depend on it"
**Causa:** Dependências de FKs ou views  
**Solução:**
```sql
-- Usar CASCADE ao remover (cuidado em produção!)
DROP TABLE operacional.obras CASCADE;
DROP SCHEMA operacional CASCADE;
```

### Erro: "public schema detected"
**Causa:** Script `apply_migrations.sh` detectou uso de schema `public`  
**Solução:**
- Remover referências a `public` nas migrations
- Qualificar todos os objetos com schema correto
- Reexecutar o script

### Erro: "DO 836" ou "syntax error" em blocos
**Causa:** Delimitadores genéricos ou numerados (corrigido em v1.0.2)  
**Solução:**
- Usar delimitadores nominais: `$do$`, `$fn$`
- Verificar UTF-8 sem BOM
- Rodar `dos2unix` nos arquivos

---

## 📦 Aplicação Automatizada

Use o script `apply_migrations.sh` (localizado em `03-DB/apply_migrations.sh`) para aplicação automatizada:

```bash
# Definir DATABASE_URL
export DATABASE_URL="postgresql://gbs_dev:senha@localhost:5432/gbs_intranet_prod"

# Aplicar migrations
cd 03-DB
bash apply_migrations.sh
```

O script realiza:
1. ✅ Pré-checagem de conexão
2. ✅ Validação de schemas base
3. ✅ Lint (bloqueio de `public` e CREATE TABLE sem schema)
4. ✅ Aplicação sequencial com log (000→017)
5. ✅ Geração de `logs/migrations.log`

---

## 📖 Referências

- **CHANGELOG.md** → Histórico de alterações do projeto
- **DEPLOY_HML.md** → Procedimentos de deploy em HML
- **QUICKSTART.md** → Guia rápido de configuração
- **API Collection** → `04-APIs/collections/`
- **FIX-002** → `01-Docs/_EVIDENCIAS/FIX-002-audit-core-hotfix.txt`
- **FIX-003** → `01-Docs/_EVIDENCIAS/FIX-003-dim-tipo-fornecimento.txt`

---

## 🔄 Histórico de Versões

| Versão | Data | Alterações |
|--------|------|------------|
| v1.0.2-HML | 06/11/2025 | Hotfix 004+005 (idempotência), novas 016+017 (cleanup índices), delimitadores nominais |
| v1.0.1-HML | 06/11/2025 | Reorganização com arquitetura de schemas, lint obrigatório, apply_migrations.sh |
| v1.0.0-HML | 05/11/2025 | Versão inicial (Sprint 1 + Sprint 2) |

---

**🔒 USO INTERNO – CONFIDENCIAL**  
**Globosul Engenharia** | ti@globosul.com.br  
Projeto: GBS | Intranet & Dashboards  
Versão: v1.0.2-HML | 06/11/2025
