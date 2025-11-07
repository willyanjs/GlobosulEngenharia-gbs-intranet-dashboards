# QUICKSTART - GBS Intranet v1.0.0-HML

**Objetivo**: Colocar a API rodando em menos de 10 minutos.

---

## ⚡ INSTALAÇÃO RÁPIDA

### Pré-requisitos
```bash
# Validar versões
node --version   # Precisa: v18.0.0+
npm --version    # Precisa: v9.0.0+
psql --version   # Precisa: PostgreSQL 14+
```

### Passo 1: Preparar Ambiente
```bash
# Clonar ou descompactar pacote HML
cd gbs-intranet/v1.0.0-HML

# Instalar dependências
npm install
```

### Passo 2: Configurar Banco de Dados
```bash
# Criar banco
createdb gbs_intranet_hml

# Aplicar migrations (em ordem)
psql -d gbs_intranet_hml -f migrations/001_create_usuarios.sql
psql -d gbs_intranet_hml -f migrations/002_create_sessoes.sql
psql -d gbs_intranet_hml -f migrations/003_create_reset_tokens.sql
psql -d gbs_intranet_hml -f migrations/004_create_auditoria.sql

# Seed admin (definir senha de ambiente)
ADMIN_SEED_PASSWORD="SenhaSegura123!" psql -d gbs_intranet_hml -f migrations/005_seed_admin.sql
```

### Passo 3: Configurar Variáveis de Ambiente
```bash
# Copiar template
cp .env.example .env

# Editar .env (usar editor de texto)
nano .env
```

**Variáveis obrigatórias** (`.env`):
```env
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=gbs_intranet_hml
DB_USER=seu_usuario
DB_PASSWORD=sua_senha

# Session (gerar com: openssl rand -base64 32)
SESSION_SECRET=gerar_segredo_aleatorio_32_chars

# CORS
CORS_ORIGIN=http://localhost:3000

# Admin Seed (mesma senha usada no passo 2)
ADMIN_SEED_PASSWORD=SenhaSegura123!
```

### Passo 4: Build e Start
```bash
# Build
npm run build

# Start
npm start

# Ou em desenvolvimento (com hot-reload)
npm run dev
```

### Passo 5: Validar
```bash
# Health check
curl http://localhost:3000/health

# Resposta esperada:
# {"status":"ok","database":"connected"}

# Login com admin
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@globosul.com.br",
    "password": "SenhaSegura123!"
  }'

# Resposta esperada:
# {
#   "token": "uuid-token-aqui",
#   "user": {
#     "id": "uuid",
#     "email": "admin@globosul.com.br",
#     "nome": "Administrador",
#     "role": "ADMIN"
#   }
# }
```

---

## 🧪 TESTAR A API

### Opção 1: cURL (manual)
```bash
# Login
TOKEN=$(curl -s -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@globosul.com.br","password":"SenhaSegura123!"}' \
  | jq -r '.token')

# Listar usuários (como admin)
curl -X GET http://localhost:3000/v1/users \
  -H "Cookie: session_token=$TOKEN"
```

### Opção 2: HTTPie (recomendado)
```bash
# Instalar HTTPie
pip install httpie

# Login
http POST :3000/v1/auth/login email=admin@globosul.com.br password=SenhaSegura123!

# Listar usuários (sessão salva automaticamente)
http GET :3000/v1/users --session=gbs
```

### Opção 3: Coleção REST
```bash
# Usar arquivo api-collection.http (VS Code REST Client extension)
# Ou importar em Insomnia/Postman
```

---

## 📁 ESTRUTURA DO PROJETO

```
gbs-intranet/v1.0.0-HML/
├── src/
│   ├── controllers/       # Lógica de controle (req/res)
│   ├── services/          # Lógica de negócio
│   ├── models/            # Interfaces TypeScript
│   ├── routes/            # Definição de rotas
│   ├── middleware/        # RBAC, CSRF, rate limiting
│   ├── utils/             # Logger, sanitização
│   ├── jobs/              # Garbage collection
│   └── index.ts           # Entry point
├── tests/                 # Testes automatizados
├── migrations/            # SQL migrations (5 arquivos)
├── coverage/              # Relatório de cobertura
├── dist/                  # Build (gerado pelo tsc)
├── .env.example           # Template de variáveis
├── package.json           # Dependências npm
├── tsconfig.json          # Config TypeScript
└── jest.config.js         # Config de testes
```

---

## 🔍 COMANDOS ÚTEIS

### Desenvolvimento
```bash
npm run dev          # Start com hot-reload
npm run build        # Build TypeScript → JavaScript
npm start            # Start produção (após build)
npm test             # Executar testes
npm run test:watch   # Testes em modo watch
npm run lint         # Verificar código com ESLint
npm run format       # Formatar código com Prettier
```

### Banco de Dados
```bash
# Conectar ao banco
psql -d gbs_intranet_hml

# Listar tabelas
\dt

# Ver estrutura de tabela
\d usuarios

# Contar usuários
SELECT COUNT(*) FROM usuarios;

# Ver últimos eventos de auditoria
SELECT tipo_evento, ator_id, timestamp 
FROM auditoria 
ORDER BY timestamp DESC 
LIMIT 10;
```

### Logs
```bash
# Ver logs em tempo real (se usando PM2)
pm2 logs gbs-intranet

# Ver logs de limpeza (garbage collection)
tail -f logs/cleanup.log
```

---

## 🛠️ TROUBLESHOOTING

### Erro: "Cannot connect to database"
```bash
# Verificar se PostgreSQL está rodando
sudo systemctl status postgresql

# Verificar credenciais no .env
# Testar conexão manual
psql -h localhost -U seu_usuario -d gbs_intranet_hml
```

### Erro: "Port 3000 already in use"
```bash
# Identificar processo
lsof -i :3000

# Matar processo (substituir PID)
kill -9 <PID>

# Ou mudar porta no .env
PORT=3001
```

### Erro: "Session not found"
```bash
# Limpar sessões expiradas manualmente
psql -d gbs_intranet_hml -c "DELETE FROM sessoes WHERE expira_em < NOW();"

# Ou fazer logout e login novamente
```

### Erro: "User is locked"
```bash
# Desbloquear via API (como admin)
curl -X POST http://localhost:3000/v1/admin/unlock-user \
  -H "Content-Type: application/json" \
  -H "Cookie: session_token=$ADMIN_TOKEN" \
  -d '{"userId": "uuid-do-usuario"}'

# Ou desbloquear no banco
psql -d gbs_intranet_hml -c "
  UPDATE usuarios 
  SET tentativas_login = 0, bloqueado_ate = NULL 
  WHERE email = 'usuario@exemplo.com';
"
```

### Erro de Seed: "Password not set"
```bash
# Verificar se variável de ambiente está definida
echo $ADMIN_SEED_PASSWORD

# Se não estiver, definir antes de executar seed
export ADMIN_SEED_PASSWORD="SenhaSegura123!"
psql -d gbs_intranet_hml -f migrations/005_seed_admin.sql
```

---

## 🔒 SEGURANÇA EM DESENVOLVIMENTO

### Gerar SESSION_SECRET forte
```bash
# Linux/macOS
openssl rand -base64 32

# Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

### Validar força da senha admin
```bash
# Senha deve ter:
# - Mínimo 8 caracteres
# - Pelo menos 1 maiúscula
# - Pelo menos 1 minúscula
# - Pelo menos 1 número
# - Pelo menos 1 caractere especial
```

### Limpar logs de desenvolvimento
```bash
# Remover logs locais (não versionar)
rm -rf logs/*.log

# Adicionar ao .gitignore
echo "logs/*.log" >> .gitignore
```

---

## 📚 PRÓXIMOS PASSOS

Após a API estar rodando:

1. **Explorar endpoints**: Usar coleção `api-collection.http`
2. **Criar usuários de teste**: Usar `POST /v1/users` como admin
3. **Testar RBAC**: Tentar acessar /users com usuário não-admin
4. **Ver auditoria**: Consultar tabela `auditoria` no banco
5. **Testar lockout**: Fazer 5 logins errados consecutivos
6. **Configurar cron**: Seguir instruções em `DEPLOY_HML.md`

---

## 📞 SUPORTE

**Documentação completa**: Ver `README.md`, `DEPLOY_HML.md`  
**Problemas técnicos**: ti@globosul.com.br  
**Questões de negócio**: Contatar Product Owner (Willyan Silva)

---

**USO INTERNO – CONFIDENCIAL**  
**Globosul Engenharia**  
Última atualização: 06/11/2025
