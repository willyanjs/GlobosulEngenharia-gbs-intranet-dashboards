# DEPLOY HML - GBS Intranet v1.0.1

**Ambiente**: Homologação (HML)  
**Versão**: v1.0.1-HML  
**Data**: 06/11/2025  
**Status**: ✅ Aprovado para deploy

---

## 🆕 NOVIDADES v1.0.1-HML

### Infraestrutura de Migrations Automatizada

A partir da v1.0.1-HML, as migrations são aplicadas via **script automatizado** com lint e validações obrigatórias:

✅ **Script:** `03-DB/apply_migrations.sh`  
✅ **Arquitetura:** Schemas qualificados (auth, operacional, financeiro, vw, audit)  
✅ **Proibição:** Schema `public` bloqueado  
✅ **Ordem:** Determinística (000→014)  
✅ **Log:** Gerado automaticamente em `logs/migrations.log`

**Migrations legadas arquivadas:** `99-Archive/migrations-legadas-v1.0.0/`

📖 **Ver seção:** [4.1. Aplicação de Migrations v1.0.1-HML](#41-aplicação-de-migrations-v101-hml)

---

## 📋 PRÉ-REQUISITOS

### Servidor
- Ubuntu 20.04+ (ou Debian 11+)
- Node.js 18+ instalado
- PostgreSQL 16+ instalado (**mínimo requerido**)
- npm 9+ instalado
- Git Bash ou WSL (para rodar script bash no Windows)
- Usuário com permissões sudo (para configuração inicial)

### Roles PostgreSQL (Obrigatórias para v1.0.1+)
```sql
-- Roles devem existir ANTES de aplicar migrations
gbs_admin  -- Owner de schemas e objetos
gbs_rw     -- Read-Write (aplicações que alteram dados)
gbs_ro     -- Read-Only (dashboards, consultas)
gbs_app    -- Role para backend Node.js
gbs_dev    -- Role para desenvolvimento
```

### Schemas PostgreSQL (Criados pela migration 000)
```sql
-- Schemas da arquitetura v1.0.1-HML
auth           -- Autenticação e RBAC
operacional    -- Obras, contratos, fornecimento
financeiro     -- Medições, NFs, pagamentos, glosas
vw             -- Views agregadas e KPIs
audit          -- Auditoria de eventos
staging        -- Dados temporários
comercial      -- (reservado)
programacao    -- (reservado)
```

**⚠️ CRÍTICO:** Schema `public` deve estar **BLOQUEADO** (REVOKE ALL). O script aborta se detectar objetos em `public`.

### Rede
- Porta 3000 liberada no firewall (API)
- Porta 5432 acessível para PostgreSQL (se remoto)
- Conexão HTTPS configurada (recomendado via nginx/traefik)

### Acesso
- SSH ao servidor HML
- Acesso ao banco PostgreSQL (usuário `gbs_dev` ou `gbs_admin`)
- Permissão para criar cron jobs

---

## 🚀 PASSO A PASSO

### 1. Preparar Servidor

```bash
# Conectar ao servidor HML
ssh user@hml.globosul.com.br

# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Node.js 18 (se não instalado)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verificar versões
node --version   # Deve ser >= 18.0.0
npm --version    # Deve ser >= 9.0.0
psql --version   # Deve ser >= 16.0
```

### 2. Clonar/Transferir Código

```bash
# Opção A: Clonar repositório
cd /var/www
sudo git clone <repo-url> gbs-intranet
cd gbs-intranet

# Opção B: Transferir pacote HML (OneDrive → Servidor)
# Windows (PowerShell/Command Prompt):
scp -r "C:\Users\WillyanSilva\OneDrive - Globosul Engenharia\Documentos\GBS - Intranet & Dashboards" user@hml.globosul.com.br:/var/www/gbs-intranet

# No servidor:
ssh user@hml.globosul.com.br
cd /var/www/gbs-intranet/02-Backends/gbs-intranet/v1.0.0-HML
```

### 3. Instalar Dependências

```bash
# Instalar dependências exatas (usa package-lock.json)
npm ci

# Verificar instalação
npm list --depth=0
```

### 4. Configurar Roles e Banco de Dados

```bash
# Conectar ao PostgreSQL como superusuário
sudo -u postgres psql

# Criar banco
CREATE DATABASE gbs_intranet_prod;

# Criar roles (SE NÃO EXISTIREM)
CREATE ROLE gbs_admin WITH LOGIN PASSWORD 'senha_forte_admin' SUPERUSER;
CREATE ROLE gbs_rw WITH LOGIN PASSWORD 'senha_forte_rw';
CREATE ROLE gbs_ro WITH LOGIN PASSWORD 'senha_forte_ro';
CREATE ROLE gbs_app WITH LOGIN PASSWORD 'senha_forte_app';
CREATE ROLE gbs_dev WITH LOGIN PASSWORD 'senha_forte_dev';

# Conceder permissões base
GRANT ALL PRIVILEGES ON DATABASE gbs_intranet_prod TO gbs_admin;
GRANT CONNECT ON DATABASE gbs_intranet_prod TO gbs_rw, gbs_ro, gbs_app, gbs_dev;

# Bloquear schema public (OBRIGATÓRIO)
\c gbs_intranet_prod
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;

# Sair
\q
```

### 4.1. Aplicação de Migrations v1.0.1-HML

**⚠️ NOVO PROCESSO:** Use o script automatizado `apply_migrations.sh`

```bash
# Navegar para diretório de migrations
cd /var/www/gbs-intranet/03-DB

# Definir DATABASE_URL
export DATABASE_URL="postgresql://gbs_dev:senha_forte_dev@localhost:5432/gbs_intranet_prod"

# Verificar permissões de execução (Linux)
chmod +x apply_migrations.sh

# Windows com Git Bash/WSL: corrigir line endings se necessário
dos2unix apply_migrations.sh  # Se disponível

# EXECUTAR SCRIPT
bash apply_migrations.sh
```

**Saída Esperada:**
```
[INFO] Iniciando aplicação de migrations...
[INFO] Verificando conexão com banco de dados...
[INFO] ✅ Conexão estabelecida com sucesso.
[INFO] Verificando schemas base obrigatórios...
[INFO] ✅ Schema 'auth' encontrado.
[INFO] ✅ Schema 'operacional' encontrado.
...
[INFO] Executando lint: verificando uso de 'public.' nas migrations...
[INFO] ✅ Nenhum uso de 'public.' detectado.
[INFO] Executando lint: verificando CREATE TABLE sem schema qualificado...
[INFO] ✅ Todas as tabelas possuem schema qualificado.
[INFO] Executando lint: verificando CREATE VIEW fora de 'vw.*'...
[INFO] ✅ Todas as views estão no schema 'vw.*'.
[INFO] Iniciando aplicação das migrations (ordem: 000 → 014)...
[INFO] [1/15] Aplicando: 000_create_schemas.sql...
[INFO] ✅ 000_create_schemas.sql aplicada com sucesso.
[INFO] [2/15] Aplicando: 001_auth_usuarios.sql...
[INFO] ✅ 001_auth_usuarios.sql aplicada com sucesso.
...
[INFO] [15/15] Aplicando: 014_vw_fluxocaixa.sql...
[INFO] ✅ 014_vw_fluxocaixa.sql aplicada com sucesso.
[INFO] Validando objetos criados...
[INFO] Schema 'auth': 3 tabelas criadas.
[INFO] Schema 'operacional': 3 tabelas criadas.
[INFO] Schema 'financeiro': 4 tabelas criadas.
[INFO] Schema 'audit': 2 tabelas criadas.
[INFO] Schema 'vw': 2 views criadas.
[INFO] 🎉 Todas as migrations foram aplicadas com sucesso!
[INFO] 📄 Log completo: logs/migrations.log
```

**Em caso de erro:**
- ❌ **Código 2:** Falha na conexão → Verificar DATABASE_URL
- ❌ **Código 3:** Uso de `public` detectado → Revisar migrations
- ❌ **Código 4:** CREATE TABLE sem schema → Adicionar schema qualificado
- ❌ **Código 5:** CREATE VIEW fora de vw.* → Mover view para schema vw
- ❌ **Código 6:** Erro na aplicação → Consultar `logs/migrations.log`

### 4.2. Validação das Migrations

```bash
# Conectar ao banco
psql "$DATABASE_URL"

# 1. Verificar objetos por schema
\dt auth.*;
\dt operacional.*;
\dt financeiro.*;
\dt audit.*;
\dv vw.*;

# 2. Verificar que public está vazio
\dt public.*;
-- Resultado esperado: "Did not find any relations."

# 3. Testar views
SELECT * FROM vw.vw_pipeline LIMIT 1;
SELECT * FROM vw.vw_fluxocaixa LIMIT 1;

# 4. Validar permissões (gbs_app)
SET ROLE gbs_app;
SELECT * FROM vw.vw_pipeline LIMIT 1;  -- ✅ Deve funcionar
CREATE VIEW vw.teste AS SELECT 1;      -- ❌ Deve falhar (permission denied)
RESET ROLE;

# 5. Contar objetos por schema
SELECT
  schemaname,
  COUNT(*) AS total_tables
FROM pg_tables
WHERE schemaname IN ('auth', 'operacional', 'financeiro', 'audit')
GROUP BY schemaname
ORDER BY schemaname;

# Resultado esperado:
-- auth         | 3
-- audit        | 2
-- financeiro   | 4
-- operacional  | 3
```

### 4.3. Anexar Log como Evidência

```bash
# Copiar log para evidências
cp 03-DB/logs/migrations.log 01-Docs/_EVIDENCIAS/migrations-v1.0.1-HML.log

# Verificar log
cat 01-Docs/_EVIDENCIAS/migrations-v1.0.1-HML.log
```

---

### 5. Configurar Variáveis de Ambiente

```bash
# Copiar template
cp .env.example .env

# Editar .env
nano .env
```

**Conteúdo `.env` (HML)**:
```env
# Ambiente
NODE_ENV=production
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=gbs_intranet_prod
DB_USER=gbs_app
DB_PASSWORD=senha_forte_app

# Session (gerar: openssl rand -base64 32)
SESSION_SECRET=wK8j3mP9nL4qR7tY2vX5zA1bC6dE8fG0

# CORS (domínios HML)
CORS_ORIGIN=https://hml.globosul.com.br,https://hml-admin.globosul.com.br

# Admin Seed (primeira execução)
ADMIN_SEED_PASSWORD=SenhaAdmin123!

# Logs
LOG_LEVEL=info
LOG_FILE=/var/log/gbs-intranet/app.log
```

**IMPORTANTE**: 
- Gerar `SESSION_SECRET` único e forte
- NUNCA usar `CORS_ORIGIN=*` em produção
- Proteger arquivo `.env` com permissões restritas:
  ```bash
  chmod 600 .env
  ```

### 6. Build da Aplicação

```bash
# Build TypeScript → JavaScript
npm run build

# Verificar build
ls dist/
# Resultado esperado: index.js, controllers/, services/, etc.
```

### 7. Testar Localmente

```bash
# Start temporário (foreground)
npm start

# Em outro terminal, testar health check
curl http://localhost:3000/health
# Resposta esperada: {"status":"ok","database":"connected"}

# Testar login admin
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@globosul.com.br",
    "password": "SenhaAdmin123!"
  }'
# Resposta esperada: {"token":"...","user":{...}}

# Se tudo OK, parar (Ctrl+C)
```

### 8. Configurar PM2 (Process Manager)

```bash
# Instalar PM2 globalmente
sudo npm install -g pm2

# Criar ecosystem file
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'gbs-intranet-hml',
    script: 'dist/index.js',
    instances: 2,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/var/log/gbs-intranet/pm2-error.log',
    out_file: '/var/log/gbs-intranet/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss',
    merge_logs: true,
    max_restarts: 10,
    min_uptime: '10s',
    max_memory_restart: '500M'
  }]
};
EOF

# Criar diretório de logs
sudo mkdir -p /var/log/gbs-intranet
sudo chown $USER:$USER /var/log/gbs-intranet

# Iniciar com PM2
pm2 start ecosystem.config.js

# Verificar status
pm2 status

# Configurar auto-start no boot
pm2 startup
# (seguir instruções exibidas)

pm2 save
```

### 9. Configurar Nginx (Proxy Reverso)

```bash
# Instalar nginx (se não instalado)
sudo apt install -y nginx

# Criar configuração
sudo nano /etc/nginx/sites-available/gbs-intranet-hml
```

**Conteúdo** (`/etc/nginx/sites-available/gbs-intranet-hml`):
```nginx
server {
    listen 80;
    server_name hml.globosul.com.br;

    # Redirecionar HTTP → HTTPS (recomendado)
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name hml.globosul.com.br;

    # Certificados SSL (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/hml.globosul.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/hml.globosul.com.br/privkey.pem;

    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logs
    access_log /var/log/nginx/gbs-intranet-hml-access.log;
    error_log /var/log/nginx/gbs-intranet-hml-error.log;

    # Proxy para API Node.js
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

```bash
# Ativar site
sudo ln -s /etc/nginx/sites-available/gbs-intranet-hml /etc/nginx/sites-enabled/

# Testar configuração
sudo nginx -t

# Recarregar nginx
sudo systemctl reload nginx
```

### 10. Configurar Cron Jobs (Garbage Collection)

```bash
# Copiar template
sudo cp cron.example /etc/cron.d/gbs-intranet-gc

# Editar cron
sudo nano /etc/cron.d/gbs-intranet-gc
```

**Conteúdo** (`/etc/cron.d/gbs-intranet-gc`):
```bash
# GBS Intranet - Garbage Collection (HML)

# Limpeza de sessões expiradas (diário às 03:00)
0 3 * * * www-data cd /var/www/gbs-intranet && /usr/bin/node dist/jobs/cleanup.job.js sessions >> /var/log/gbs-intranet/cleanup.log 2>&1

# Limpeza de tokens de reset (diário às 03:30)
30 3 * * * www-data cd /var/www/gbs-intranet && /usr/bin/node dist/jobs/cleanup.job.js reset-tokens >> /var/log/gbs-intranet/cleanup.log 2>&1
```

```bash
# Verificar sintaxe
cat /etc/cron.d/gbs-intranet-gc

# Testar manualmente
sudo -u www-data /usr/bin/node /var/www/gbs-intranet/dist/jobs/cleanup.job.js sessions

# Verificar logs
tail -f /var/log/gbs-intranet/cleanup.log
```

---

## ✅ VALIDAÇÕES PÓS-DEPLOY

### Checklist de Validação v1.0.1-HML

#### 1. Migrations (NOVO)
```bash
# Verificar que migrations foram aplicadas
psql "$DATABASE_URL" -c "\dt auth.*; \dt operacional.*; \dt financeiro.*; \dv vw.*;"

# Contar objetos por schema
psql "$DATABASE_URL" -c "
SELECT schemaname, COUNT(*) AS total
FROM pg_tables
WHERE schemaname IN ('auth', 'operacional', 'financeiro', 'audit')
GROUP BY schemaname
UNION ALL
SELECT schemaname, COUNT(*) AS total
FROM pg_views
WHERE schemaname = 'vw'
ORDER BY schemaname;
"

# Resultado esperado:
-- auth         | 3
-- audit        | 2
-- financeiro   | 4
-- operacional  | 3
-- vw           | 2

# Verificar que public está vazio
psql "$DATABASE_URL" -c "\dt public.*;"
-- Resultado esperado: "Did not find any relations."

# Verificar log de migrations
cat 03-DB/logs/migrations.log
# Resultado esperado: "🎉 Todas as migrations foram aplicadas com sucesso!"
```

#### 2. Infraestrutura
```bash
# PM2 rodando
pm2 status
# Resultado esperado: gbs-intranet-hml | online | 2 instances

# Nginx respondendo
curl -I https://hml.globosul.com.br/health
# Resultado esperado: HTTP/2 200

# Logs sem erros
pm2 logs --lines 50
tail -f /var/log/nginx/gbs-intranet-hml-error.log
```

#### 3. API (11 endpoints)
```bash
# Health check
curl https://hml.globosul.com.br/health
# Resultado esperado: {"status":"ok","database":"connected"}

# Login admin
curl -X POST https://hml.globosul.com.br/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@globosul.com.br",
    "password": "SenhaAdmin123!"
  }'
# Resultado esperado: {"token":"...","user":{...}}

# Listar usuários (como admin)
TOKEN="<token-do-login>"
curl -X GET https://hml.globosul.com.br/v1/users \
  -H "Cookie: session_token=$TOKEN"
# Resultado esperado: [{"id":"...","email":"admin@globosul.com.br",...}]
```

#### 4. Segurança
```bash
# HTTPS ativo
curl -I https://hml.globosul.com.br/health | grep -i "strict-transport-security"
# Resultado esperado: Strict-Transport-Security presente

# CORS configurado
curl -H "Origin: https://hml.globosul.com.br" -I https://hml.globosul.com.br/health | grep -i "access-control"
# Resultado esperado: Access-Control-Allow-Origin presente

# Rate limiting
for i in {1..110}; do curl -s https://hml.globosul.com.br/health > /dev/null; done
curl https://hml.globosul.com.br/health
# Resultado esperado: 429 Too Many Requests (após 100 req)

# Lockout
for i in {1..5}; do
  curl -X POST https://hml.globosul.com.br/v1/auth/login \
    -d '{"email":"admin@globosul.com.br","password":"senha_errada"}'
done
curl -X POST https://hml.globosul.com.br/v1/auth/login \
  -d '{"email":"admin@globosul.com.br","password":"SenhaAdmin123!"}'
# Resultado esperado: {"error":"Account locked. Try again in 15 minutes."}
```

#### 5. Auditoria
```bash
# Verificar eventos
psql "$DATABASE_URL" -c "
  SELECT tipo_evento, COUNT(*) 
  FROM audit.auditoria 
  GROUP BY tipo_evento 
  ORDER BY COUNT(*) DESC;
"
# Resultado esperado: LOGIN_SUCCESS, LOGIN_FAILURE, etc.

# Verificar sanitização
psql "$DATABASE_URL" -c "
  SELECT payload 
  FROM audit.auditoria 
  WHERE tipo_evento = 'LOGIN_SUCCESS' 
  LIMIT 1;
"
# Resultado esperado: password = '[REDACTED]'
```

#### 6. Cron Jobs
```bash
# Aguardar execução (próximo 03:00 ou 03:30)
# Ou testar manualmente:
sudo -u www-data /usr/bin/node /var/www/gbs-intranet/dist/jobs/cleanup.job.js sessions

# Verificar logs
tail -20 /var/log/gbs-intranet/cleanup.log
# Resultado esperado: "Sessões expiradas removidas: X"
```

---

## 🔒 SEGURANÇA

### Checklist de Segurança HML

- [x] `.env` com permissões 600
- [x] `SESSION_SECRET` único e forte (32+ chars)
- [x] Senha admin NÃO hardcoded
- [x] CORS configurado para domínios HML específicos
- [x] HTTPS ativo (Let's Encrypt)
- [x] Headers de segurança (nginx)
- [x] Firewall configurado (UFW)
- [x] PostgreSQL com senha forte
- [x] Logs sanitizados (sem senhas)
- [x] Rate limiting ativo
- [x] Lockout funcionando
- [x] Schema `public` bloqueado (**NOVO v1.0.1**)
- [x] Migrations com lint obrigatório (**NOVO v1.0.1**)

### Hardening Adicional (Recomendado)

```bash
# Configurar firewall (UFW)
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable

# Restringir acesso SSH (apenas IPs da Globosul)
sudo nano /etc/ssh/sshd_config
# Adicionar: AllowUsers user@ip_globosul
sudo systemctl restart sshd

# Configurar fail2ban (proteção contra brute force SSH)
sudo apt install -y fail2ban
sudo systemctl enable fail2ban

# Atualizar sistema automaticamente
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## 🔄 BACKUP E RECUPERAÇÃO

### Backup do Banco de Dados

```bash
# Backup manual (incluindo todos os schemas)
pg_dump -U gbs_dev gbs_intranet_prod \
  --schema=auth \
  --schema=operacional \
  --schema=financeiro \
  --schema=vw \
  --schema=audit \
  > backup-$(date +%Y%m%d).sql

# Backup completo (todos os schemas)
pg_dump -U gbs_dev gbs_intranet_prod > backup-full-$(date +%Y%m%d).sql

# Backup automático (cron diário às 02:00)
echo "0 2 * * * postgres pg_dump -U gbs_dev gbs_intranet_prod | gzip > /backups/gbs-intranet-\$(date +\%Y\%m\%d).sql.gz" | sudo tee -a /etc/cron.d/gbs-backup
```

### Recuperação
```bash
# Restaurar de backup
psql -U gbs_dev -d gbs_intranet_prod < backup-20251106.sql

# Ou de backup comprimido
gunzip -c backup-20251106.sql.gz | psql -U gbs_dev -d gbs_intranet_prod
```

---

## 📊 MONITORAMENTO

### Logs Importantes

```bash
# Logs da aplicação (PM2)
pm2 logs gbs-intranet-hml --lines 100

# Logs do nginx
tail -f /var/log/nginx/gbs-intranet-hml-access.log
tail -f /var/log/nginx/gbs-intranet-hml-error.log

# Logs de cleanup
tail -f /var/log/gbs-intranet/cleanup.log

# Logs de migrations (v1.0.1+)
tail -f 03-DB/logs/migrations.log

# Logs do PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-16-main.log
```

### Métricas

```bash
# Status PM2 (CPU, memória)
pm2 monit

# Status do banco (por schema)
psql "$DATABASE_URL" -c "
  SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
  FROM pg_tables
  WHERE schemaname IN ('auth', 'operacional', 'financeiro', 'audit')
  ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"

# Conexões ativas
psql "$DATABASE_URL" -c "
  SELECT COUNT(*) AS active_connections 
  FROM pg_stat_activity 
  WHERE datname = 'gbs_intranet_prod';
"
```

---

## 🚨 TROUBLESHOOTING

### Problema: API não responde

```bash
# Verificar se PM2 está rodando
pm2 status

# Se não estiver, reiniciar
pm2 restart gbs-intranet-hml

# Verificar logs de erro
pm2 logs gbs-intranet-hml --err --lines 50
```

### Problema: "Cannot connect to database"

```bash
# Verificar se PostgreSQL está rodando
sudo systemctl status postgresql

# Testar conexão manual
psql -U gbs_dev -d gbs_intranet_prod -h localhost

# Verificar credenciais no .env
cat .env | grep DB_
```

### Problema: CORS bloqueando requisições

```bash
# Verificar configuração CORS no .env
cat .env | grep CORS_ORIGIN

# Deve incluir domínio do frontend
# Exemplo: CORS_ORIGIN=https://hml.globosul.com.br

# Reiniciar aplicação após alterar
pm2 restart gbs-intranet-hml
```

### Problema: Migrations falhando (v1.0.1+)

```bash
# Verificar log detalhado
cat 03-DB/logs/migrations.log

# Erro comum: objetos em public
# Solução: limpar public antes de rodar
psql "$DATABASE_URL" -c "
  DROP SCHEMA public CASCADE;
  CREATE SCHEMA public;
  REVOKE ALL ON SCHEMA public FROM PUBLIC;
"

# Erro comum: roles não existem
# Solução: criar roles antes de rodar (ver seção 4)

# Erro comum: CRLF no Windows
# Solução: converter line endings
dos2unix 03-DB/apply_migrations.sh
bash 03-DB/apply_migrations.sh
```

### Problema: Sessões expirando muito rápido

```bash
# Verificar TTL no código (default: 24h)
# Verificar se cron de cleanup não está rodando muito frequente
sudo cat /etc/cron.d/gbs-intranet-gc

# Verificar logs de cleanup
tail -100 /var/log/gbs-intranet/cleanup.log
```

---

## 📞 CONTATOS

**Suporte Técnico**: ti@globosul.com.br  
**DevOps Responsável**: (preencher)  
**Product Owner**: Willyan Silva  
**Escalação 24/7**: (preencher)

---

## 📝 CHECKLIST FINAL DE DEPLOY v1.0.1-HML

- [ ] Servidor preparado (Node.js 18+, PostgreSQL 16+, nginx, Git Bash/WSL)
- [ ] Código clonado/transferido
- [ ] Dependências instaladas (`npm ci`)
- [ ] Roles PostgreSQL criadas (gbs_admin, gbs_rw, gbs_ro, gbs_app, gbs_dev)
- [ ] Banco criado (`gbs_intranet_prod`)
- [ ] Schema `public` bloqueado (REVOKE ALL)
- [ ] **Migrations aplicadas via `apply_migrations.sh` (código 0)** ✨ NOVO
- [ ] **Log de migrations anexado em evidências** ✨ NOVO
- [ ] **Validação de objetos por schema (auth, operacional, financeiro, vw, audit)** ✨ NOVO
- [ ] **Confirmação de `public` vazio** ✨ NOVO
- [ ] `.env` configurado e protegido (chmod 600)
- [ ] Build executado (`npm run build`)
- [ ] PM2 configurado e rodando (2 instâncias)
- [ ] PM2 auto-start habilitado
- [ ] Nginx configurado como proxy reverso
- [ ] HTTPS ativo (certificado válido)
- [ ] Cron jobs configurados (garbage collection)
- [ ] Firewall configurado (UFW)
- [ ] Validações pós-deploy executadas
- [ ] Testes de API (11 endpoints) bem-sucedidos
- [ ] Testes de segurança (HTTPS, CORS, lockout) OK
- [ ] Backup automático configurado
- [ ] Monitoramento configurado (PM2, logs)
- [ ] Documentação atualizada
- [ ] Equipe treinada

---

## 📖 REFERÊNCIAS v1.0.1-HML

- **README_MIGRATIONS.md** → Padrões e ordem de migrations (03-DB/migrations/)
- **apply_migrations.sh** → Script de orquestração automatizada (03-DB/)
- **CHANGELOG.md** → Histórico de mudanças da v1.0.1-HML (01-Docs/)
- **CHECKS.txt** → Evidências de estrutura e validações (01-Docs/_EVIDENCIAS/)
- **migrations-v1.0.1-HML.log** → Log de execução das migrations (01-Docs/_EVIDENCIAS/)

---

**USO INTERNO – CONFIDENCIAL**  
**Globosul Engenharia**  
Última atualização: 06/11/2025 | v1.0.1-HML
