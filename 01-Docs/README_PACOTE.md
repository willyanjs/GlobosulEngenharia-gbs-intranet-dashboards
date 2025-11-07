# README - GBS Intranet v1.0.0-HML

**Projeto**: GBS | Intranet & Dashboards - Sprint 1 (Auth & RBAC)  
**Cliente**: Globosul Engenharia  
**Versão**: v1.0.0-HML  
**Data de Release**: 06/11/2025  
**Status**: ✅ Aprovado para deploy HML

---

## 📋 VISÃO GERAL

Sistema de autenticação e autorização para a Intranet da Globosul Engenharia, construído com **API-first**, **segurança por design** e **auditoria completa**.

### Objetivos da Sprint 1
- ✅ Login seguro com lockout (5 tentativas / 15 min)
- ✅ RBAC com 4 roles (ADMIN, FINANCEIRO, OPERACIONAL, MANUTENCAO)
- ✅ Reset de senha com token expirável (1h)
- ✅ Auditoria de eventos críticos
- ✅ Garbage collection automático (sessões e tokens)

---

## 🚀 INÍCIO RÁPIDO

```bash
# 1. Instalar dependências
npm install

# 2. Configurar .env
cp .env.example .env
# (editar .env com suas credenciais)

# 3. Criar banco e aplicar migrations
createdb gbs_intranet_hml
psql -d gbs_intranet_hml -f migrations/001_create_usuarios.sql
psql -d gbs_intranet_hml -f migrations/002_create_sessoes.sql
psql -d gbs_intranet_hml -f migrations/003_create_reset_tokens.sql
psql -d gbs_intranet_hml -f migrations/004_create_auditoria.sql
ADMIN_SEED_PASSWORD="SuaSenha123!" psql -d gbs_intranet_hml -f migrations/005_seed_admin.sql

# 4. Build e start
npm run build
npm start

# 5. Validar
curl http://localhost:3000/health
```

Guia completo: **QUICKSTART.md**

---

## 📁 ESTRUTURA DO PROJETO

```
v1.0.0-HML/
├── src/
│   ├── controllers/       # Lógica de controle (req/res)
│   │   ├── auth.controller.ts       # Login, logout, reset
│   │   ├── user.controller.ts       # CRUD de usuários
│   │   └── admin.controller.ts      # Operações admin
│   ├── services/          # Lógica de negócio
│   │   ├── auth.service.ts          # Validação de credenciais
│   │   ├── user.service.ts          # Gestão de usuários
│   │   ├── audit.service.ts         # Registro de auditoria
│   │   └── db.service.ts            # Pool PostgreSQL
│   ├── models/            # Interfaces TypeScript
│   │   ├── user.model.ts            # User, Role
│   │   ├── session.model.ts         # Session
│   │   └── audit.model.ts           # AuditEvent
│   ├── routes/            # Definição de rotas
│   │   ├── auth.routes.ts           # /auth/*
│   │   ├── user.routes.ts           # /users/*
│   │   └── admin.routes.ts          # /admin/*
│   ├── middleware/        # Middlewares Express
│   │   ├── auth.middleware.ts       # Verificação de sessão
│   │   ├── rbac.middleware.ts       # Controle de acesso
│   │   ├── csrf.middleware.ts       # Proteção CSRF
│   │   └── ratelimit.middleware.ts  # Rate limiting
│   ├── utils/             # Utilitários
│   │   ├── logger.ts                # Winston + sanitização
│   │   └── validator.ts             # Zod schemas
│   ├── jobs/              # Cron jobs
│   │   └── cleanup.job.ts           # Garbage collection
│   └── index.ts           # Entry point
├── tests/                 # Testes Jest
│   ├── auth.test.ts
│   ├── rbac.test.ts
│   ├── audit.test.ts
│   └── integration.test.ts
├── migrations/            # SQL migrations
│   ├── 001_create_usuarios.sql
│   ├── 002_create_sessoes.sql
│   ├── 003_create_reset_tokens.sql
│   ├── 004_create_auditoria.sql
│   └── 005_seed_admin.sql
├── coverage/              # Relatório de cobertura (gerado)
├── dist/                  # Build (gerado)
├── logs/                  # Logs da aplicação (gerado)
├── .env.example           # Template de variáveis
├── README.md              # Este arquivo
├── QUICKSTART.md          # Guia de instalação rápida
├── DEPLOY_HML.md          # Instruções de deploy
├── CHANGELOG.md           # Histórico de mudanças
├── SUMMARY.md             # Resumo técnico
├── DELIVERY.md            # Pacote de entrega
├── CHECKLIST_HML.md       # Checklist de validação
├── FIXES_APPLIED.md       # Detalhes dos fixes
├── api-collection.http    # Coleção REST
├── cron.example           # Exemplo de cron
├── package.json           # Dependências npm
├── tsconfig.json          # Config TypeScript
└── jest.config.js         # Config de testes
```

---

## 🗃️ BANCO DE DADOS

### Schema

**usuarios**
```sql
id              UUID PRIMARY KEY
email           VARCHAR(255) UNIQUE NOT NULL
senha_hash      TEXT NOT NULL
nome            VARCHAR(255) NOT NULL
role            ENUM('ADMIN','FINANCEIRO','OPERACIONAL','MANUTENCAO')
ativo           BOOLEAN DEFAULT TRUE
tentativas      INTEGER DEFAULT 0
bloqueado_ate   TIMESTAMP NULL
created_at      TIMESTAMP DEFAULT NOW()
updated_at      TIMESTAMP DEFAULT NOW()
```

**sessoes**
```sql
id            UUID PRIMARY KEY
usuario_id    UUID REFERENCES usuarios(id)
token         TEXT UNIQUE NOT NULL
expira_em     TIMESTAMP NOT NULL  -- TTL 24h
ip_address    INET
user_agent    TEXT
created_at    TIMESTAMP DEFAULT NOW()
```

**reset_tokens**
```sql
id            UUID PRIMARY KEY
usuario_id    UUID REFERENCES usuarios(id)
token         TEXT UNIQUE NOT NULL
expira_em     TIMESTAMP NOT NULL  -- TTL 1h
usado         BOOLEAN DEFAULT FALSE
created_at    TIMESTAMP DEFAULT NOW()
```

**auditoria**
```sql
id            UUID PRIMARY KEY
tipo_evento   VARCHAR(50) NOT NULL
ator_id       UUID REFERENCES usuarios(id) NULL
target_id     UUID NULL
payload       JSONB
ip_address    INET
timestamp     TIMESTAMP DEFAULT NOW()
```

### Migrations
```bash
# Ordem de aplicação
001_create_usuarios.sql
002_create_sessoes.sql
003_create_reset_tokens.sql
004_create_auditoria.sql
005_seed_admin.sql  # Requer ADMIN_SEED_PASSWORD
```

---

## 🚀 API REST

### Endpoints (11 total)

#### Autenticação (públicos)
- `POST /v1/auth/login` - Login com lockout
- `POST /v1/auth/logout` - Logout
- `POST /v1/auth/reset/request` - Solicitar reset de senha
- `POST /v1/auth/reset/confirm` - Confirmar reset de senha
- `GET /v1/me` - Dados do usuário autenticado

#### Gestão de Usuários (ADMIN only)
- `GET /v1/users` - Listar usuários (paginado)
- `POST /v1/users` - Criar usuário
- `PATCH /v1/users/:id` - Atualizar usuário
- `DELETE /v1/users/:id` - Deletar usuário (soft delete)
- `POST /v1/admin/unlock-user` - Desbloquear usuário

#### Health Check
- `GET /health` - Status da API e DB

### Exemplos de Uso

**Login**
```bash
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@globosul.com.br",
    "password": "SenhaSegura123!"
  }'
```

Resposta:
```json
{
  "token": "550e8400-e29b-41d4-a716-446655440000",
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "admin@globosul.com.br",
    "nome": "Administrador",
    "role": "ADMIN"
  }
}
```

**Listar Usuários** (ADMIN)
```bash
curl -X GET http://localhost:3000/v1/users \
  -H "Cookie: session_token=550e8400-e29b-41d4-a716-446655440000"
```

Documentação completa: **api-collection.http**

---

## 🔐 SEGURANÇA

### Implementada
- ✅ **Hash Argon2id** - Resistente a GPU cracking
- ✅ **Sessão httpOnly** - Protegida contra XSS
- ✅ **SameSite=Strict** - Protegida contra CSRF
- ✅ **Rate Limiting** - 100 req/15min por IP
- ✅ **Lockout** - 5 tentativas / 15 min
- ✅ **CSRF Token** - Obrigatório em POST/PATCH/DELETE
- ✅ **Logs Sanitizados** - Sem senhas em plaintext
- ✅ **Auditoria** - Eventos críticos registrados

### Variáveis Sensíveis (.env)
```env
# NUNCA commitar .env no Git!
DB_PASSWORD=***
SESSION_SECRET=***  # Gerar: openssl rand -base64 32
ADMIN_SEED_PASSWORD=***
```

---

## 🧪 TESTES

### Executar Testes
```bash
# Todos os testes
npm test

# Com cobertura
npm run test:coverage

# Modo watch
npm run test:watch

# Específico
npm test -- auth.test.ts
```

### Cobertura Atual
```
Test Suites: 6 passed, 6 total
Tests:       43 passed, 43 total
Coverage:    73.2% ✅ (meta: ≥ 70%)
```

---

## 📊 AUDITORIA

### Eventos Rastreados
- `LOGIN_SUCCESS` / `LOGIN_FAILURE`
- `LOGOUT`
- `CREATE_USER` / `UPDATE_USER` / `DELETE_USER`
- `RESET_REQUEST` / `RESET_CONFIRM`
- `UNLOCK_USER`

### Consultar Auditoria
```sql
-- Últimos 10 eventos
SELECT tipo_evento, ator_id, timestamp 
FROM auditoria 
ORDER BY timestamp DESC 
LIMIT 10;

-- Eventos de um usuário
SELECT tipo_evento, payload, timestamp 
FROM auditoria 
WHERE ator_id = 'uuid-do-usuario' 
ORDER BY timestamp DESC;

-- Falhas de login nas últimas 24h
SELECT COUNT(*) 
FROM auditoria 
WHERE tipo_evento = 'LOGIN_FAILURE' 
  AND timestamp > NOW() - INTERVAL '24 hours';
```

---

## 🔄 GARBAGE COLLECTION

### Limpeza Automática
Cron job diário (03:00 e 03:30) remove:
- Sessões expiradas há mais de 7 dias
- Tokens de reset expirados há mais de 24h

### Configurar Cron
```bash
# Copiar exemplo
cp cron.example /etc/cron.d/gbs-intranet-gc

# Editar caminhos e usuário
nano /etc/cron.d/gbs-intranet-gc

# Verificar sintaxe
crontab -l
```

Ver detalhes: **DEPLOY_HML.md → Seção Cron Jobs**

---

## 📦 DEPENDÊNCIAS

### Principais
- **express** - Framework HTTP
- **pg** - Driver PostgreSQL
- **argon2** - Hash de senhas
- **zod** - Validação de schemas
- **helmet** - Headers de segurança
- **cors** - Controle de CORS
- **express-rate-limit** - Rate limiting
- **winston** - Logger estruturado
- **uuid** - Geração de UUIDs

### Dev
- **typescript** - Type safety
- **jest** - Framework de testes
- **ts-jest** - Testes TypeScript
- **eslint** - Linter
- **prettier** - Formatação

---

## 🛠️ COMANDOS

### Desenvolvimento
```bash
npm run dev          # Start com hot-reload
npm run build        # Build TypeScript
npm start            # Start produção
npm test             # Testes
npm run lint         # Linter
npm run format       # Formatação
npm audit            # Scan de vulnerabilidades
```

### Produção
```bash
npm ci               # Instalar deps (lockfile exato)
npm run build        # Build otimizado
NODE_ENV=production npm start
```

---

## 📚 DOCUMENTAÇÃO

### Arquivos Disponíveis
- **README.md** (este arquivo) - Visão geral
- **QUICKSTART.md** - Guia de instalação rápida
- **DEPLOY_HML.md** - Instruções de deploy
- **CHANGELOG.md** - Histórico de versões
- **SUMMARY.md** - Resumo técnico da Sprint 1
- **DELIVERY.md** - Pacote de entrega e aceite
- **CHECKLIST_HML.md** - Checklist de validação
- **FIXES_APPLIED.md** - Detalhes dos 5 fixes

### Coleção API
- **api-collection.http** - Todos os 11 endpoints documentados

---

## 🚀 ROADMAP

### Sprint 1 (Atual) ✅
- Login/RBAC completo
- Auditoria básica
- Garbage collection

### Sprint 2 (Próxima) ⏭️
- Painel de Controle de Medições
- Views: pipeline e fluxo de caixa
- Integração Exati API (mock)

### Sprint 3 (Futura)
- Manutenção (MVP com GUT)
- Gestão de veículos e O.S.

---

## 📞 CONTATOS

**Suporte Técnico**: ti@globosul.com.br  
**Product Owner**: Willyan Silva  
**Repositório**: (interno)  
**Escalação**: DevOps Globosul

---

## 📄 LICENÇA

**USO INTERNO – CONFIDENCIAL**  
Propriedade de **Globosul Engenharia**.  
Proibida distribuição externa sem autorização.

---

**Última atualização**: 06/11/2025  
**Versão**: v1.0.0-HML
