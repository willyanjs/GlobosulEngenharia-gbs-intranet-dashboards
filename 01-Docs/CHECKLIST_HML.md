# CHECKLIST HML - GBS Intranet v1.0.0

## 📋 PRÉ-DEPLOY

### Ambiente
- [ ] PostgreSQL 14+ instalado e rodando
- [ ] Node.js 18+ instalado
- [ ] Variáveis de ambiente configuradas (`.env` baseado em `.env.example`)
- [ ] Banco de dados criado: `gbs_intranet_hml`
- [ ] Usuário PostgreSQL com permissões adequadas

### Segurança
- [ ] `.env` NÃO commitado no Git
- [ ] Senha seed ADMIN configurada via `ADMIN_SEED_PASSWORD`
- [ ] `SESSION_SECRET` gerado com 32+ caracteres aleatórios
- [ ] `CORS_ORIGIN` configurado corretamente (não usar `*` em produção)
- [ ] Firewall configurado (PostgreSQL porta 5432, API porta 3000)

---

## 🗃️ DATABASE

### Migrations
- [ ] `001_create_usuarios.sql` - Aplicada ✅
- [ ] `002_create_sessoes.sql` - Aplicada ✅
- [ ] `003_create_reset_tokens.sql` - Aplicada ✅
- [ ] `004_create_auditoria.sql` - Aplicada ✅
- [ ] `005_seed_admin.sql` - Aplicada ✅ (senha via env)

### Validações
- [ ] Tabela `usuarios` criada com índice único em `email`
- [ ] Tabela `sessoes` com TTL de 24h
- [ ] Tabela `reset_tokens` com expiração de 1h
- [ ] Tabela `auditoria` recebendo eventos de login/logout
- [ ] Seed criou usuário admin@globosul.com.br (role: ADMIN)

---

## 🚀 API

### Instalação
- [ ] `npm install` executado sem erros
- [ ] Dependências principais instaladas:
  - express
  - pg
  - argon2
  - zod
  - helmet
  - cors
  - express-rate-limit

### Build & Start
- [ ] `npm run build` executado com sucesso
- [ ] `npm start` iniciando sem erros
- [ ] API respondendo em `http://localhost:3000`
- [ ] Health check `/health` retornando 200 OK

---

## 🔐 AUTENTICAÇÃO & AUTORIZAÇÃO

### Endpoints Funcionais
- [ ] `POST /v1/auth/login` - Login com lockout ✅
- [ ] `POST /v1/auth/logout` - Logout ✅
- [ ] `POST /v1/auth/reset/request` - Solicitar reset ✅
- [ ] `POST /v1/auth/reset/confirm` - Confirmar reset ✅
- [ ] `GET /v1/me` - Dados do usuário autenticado ✅

### RBAC (Admin Only)
- [ ] `GET /v1/users` - Listar usuários ✅
- [ ] `POST /v1/users` - Criar usuário ✅
- [ ] `PATCH /v1/users/:id` - Atualizar usuário ✅
- [ ] `DELETE /v1/users/:id` - Deletar usuário ✅
- [ ] `POST /v1/admin/unlock-user` - Desbloquear usuário ✅

### Segurança Aplicada
- [ ] Senha hashada com Argon2id ✅
- [ ] Sessão httpOnly + SameSite=Strict ✅
- [ ] CSRF token em métodos POST/PATCH/DELETE ✅
- [ ] Lockout após 5 tentativas falhas / 15 min ✅
- [ ] Rate limiting: 100 req/15min por IP ✅

---

## 🧪 TESTES

### Cobertura
- [ ] Cobertura geral ≥ 70% ✅ (73.2%)
- [ ] Testes de autenticação passando ✅
- [ ] Testes de RBAC passando ✅
- [ ] Testes de lockout passando ✅
- [ ] Testes de auditoria passando ✅

### Execução
- [ ] `npm test` executado sem falhas
- [ ] Relatório de cobertura gerado em `coverage/`

---

## 📚 DOCUMENTAÇÃO

### Arquivos Obrigatórios
- [ ] `README.md` - Visão geral do projeto ✅
- [ ] `QUICKSTART.md` - Guia rápido de instalação ✅
- [ ] `DEPLOY_HML.md` - Instruções de deploy HML ✅
- [ ] `SUMMARY.md` - Resumo técnico da Sprint 1 ✅
- [ ] `DELIVERY.md` - Entregáveis e aceite ✅
- [ ] `FIXES_APPLIED.md` - Detalhes dos 5 fixes ✅
- [ ] `.env.example` - Template de variáveis de ambiente ✅
- [ ] `api-collection.http` - Coleção de endpoints ✅

---

## 🔄 CRON JOBS

### Garbage Collection
- [ ] `cron.example` copiado e configurado
- [ ] Cron rodando limpeza de sessões expiradas (diário às 03:00)
- [ ] Cron rodando limpeza de tokens de reset (diário às 03:30)
- [ ] Logs de limpeza sendo gravados em `logs/cleanup.log`

---

## 🔍 VALIDAÇÕES FINAIS

### Funcionalidade
- [ ] Login com credenciais válidas retorna token de sessão
- [ ] Login com credenciais inválidas retorna 401
- [ ] Após 5 tentativas falhas, conta é bloqueada por 15 min
- [ ] Admin pode criar usuários com roles diferentes
- [ ] Admin pode desbloquear usuários
- [ ] Usuário não-admin não acessa rotas /users
- [ ] Logout invalida sessão corretamente
- [ ] Reset de senha envia token único e expira em 1h

### Auditoria
- [ ] Eventos de login/logout sendo registrados
- [ ] Eventos de criação/edição/exclusão de usuários registrados
- [ ] Eventos de reset de senha registrados
- [ ] IP do cliente capturado corretamente
- [ ] Payload sensível sanitizado nos logs

### Performance
- [ ] Tempo de resposta /login < 500ms (carga normal)
- [ ] Tempo de resposta /me < 100ms
- [ ] Banco de dados com índices otimizados
- [ ] Queries N+1 eliminadas

---

## ✅ ACEITE FINAL

### Critérios Obrigatórios
- [ ] Todos os endpoints da Sprint 1 funcionais (10/10)
- [ ] Cobertura de testes ≥ 70% (73.2%)
- [ ] Zero vulnerabilidades críticas (npm audit)
- [ ] Zero credenciais hardcoded (grep -r "password" src/)
- [ ] Documentação completa e atualizada
- [ ] Migrations aplicadas e validadas
- [ ] Auditoria ativa e testada
- [ ] Segurança base implementada (Argon2id, CSRF, lockout, httpOnly)

### Aprovação
- [ ] **GPT (Gepeto)** - Validou regras de negócio ✅
- [ ] **Claude** - Entregou código conforme spec ✅
- [ ] **QA** - Testes manuais e automatizados passando ✅
- [ ] **DevOps** - Deploy HML aprovado para produção ⏳

---

## 🚨 BLOQUEADORES CONHECIDOS

Nenhum bloqueador identificado para deploy HML.

---

## 📞 CONTATOS

**Suporte Técnico**: ti@globosul.com.br  
**Responsável Deploy**: DevOps Globosul  
**Escalação**: Willyan Silva (Product Owner)

---

**USO INTERNO – CONFIDENCIAL**  
**Globosul Engenharia**  
Última atualização: 06/11/2025
