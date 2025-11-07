#!/usr/bin/env bash
###############################################################################
# GBS | Intranet & Dashboards - Migration Orchestrator
# Versão: v1.0.2-HML
# Data: 06/11/2025
# Descrição: Aplica migrations em ordem determinística com pré-checagens e lint
###############################################################################

set -euo pipefail

# ============================================
# CONFIGURAÇÃO
# ============================================
: "${DATABASE_URL:?ERRO: Defina DATABASE_URL, ex: postgresql://gbs_dev:senha@localhost:5432/gbs_intranet_prod}"

MIG_DIR="migrations"
LOG_DIR="logs"
LOG_FILE="${LOG_DIR}/migrations.log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# FUNÇÕES AUXILIARES
# ============================================
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
  echo -e "${RED}[ERRO]${NC} $1" | tee -a "$LOG_FILE" >&2
}

abort() {
  log_error "$1"
  exit "${2:-1}"
}

# ============================================
# SETUP INICIAL
# ============================================
mkdir -p "$LOG_DIR"
echo "========================================" > "$LOG_FILE"
echo "GBS Migrations - Execução iniciada" >> "$LOG_FILE"
echo "Data: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
echo "DATABASE_URL: ${DATABASE_URL%%:*}://***" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

log_info "Iniciando aplicação de migrations..."
log_info "Diretório de migrations: ${MIG_DIR}/"
log_info "Log: ${LOG_FILE}"

# ============================================
# PRÉ-CHECAGEM 1: CONEXÃO COM BANCO
# ============================================
log_info "Verificando conexão com banco de dados..."

if ! psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "SELECT current_database(), current_user, version();" >> "$LOG_FILE" 2>&1; then
  abort "Falha ao conectar no banco de dados. Verifique DATABASE_URL." 2
fi

log_info "✅ Conexão estabelecida com sucesso."

# ============================================
# PRÉ-CHECAGEM 2: SCHEMAS BASE
# ============================================
log_info "Verificando schemas base obrigatórios..."

REQUIRED_SCHEMAS=("auth" "operacional" "financeiro" "vw" "audit" "staging" "comercial" "programacao")

for schema in "${REQUIRED_SCHEMAS[@]}"; do
  if ! psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc "SELECT 1 FROM pg_namespace WHERE nspname = '${schema}';" | grep -q 1; then
    log_warn "Schema '${schema}' não encontrado. Será criado pela migration 000_create_schemas.sql"
  else
    log_info "✅ Schema '${schema}' encontrado."
  fi
done

# ============================================
# PRÉ-CHECAGEM 3: SCHEMA PUBLIC BLOQUEADO
# ============================================
log_info "Verificando se schema 'public' está bloqueado..."

PUBLIC_TABLES=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public';")

if [[ "$PUBLIC_TABLES" -gt 0 ]]; then
  log_warn "⚠️  Detectadas ${PUBLIC_TABLES} tabelas no schema 'public'."
  log_warn "⚠️  O projeto exige que 'public' esteja vazio."
  log_warn "⚠️  Revise o banco antes de prosseguir."
  # Não aborta, apenas avisa (pode ser banco novo ou em transição)
else
  log_info "✅ Schema 'public' está vazio (conforme esperado)."
fi

# ============================================
# LINT 1: PROIBIR USO DE 'public.' NAS MIGRATIONS
# ============================================
log_info "Executando lint: verificando uso de 'public.' nas migrations..."

if grep -RIl --include="*.sql" -E "\bpublic\." "$MIG_DIR" 2>/dev/null; then
  abort "ERRO: Uso de schema 'public.' detectado nas migrations. Use schemas qualificados (auth, operacional, financeiro, vw)." 3
fi

log_info "✅ Nenhum uso de 'public.' detectado."

# ============================================
# LINT 2: PROIBIR CREATE TABLE SEM SCHEMA QUALIFICADO
# ============================================
log_info "Executando lint: verificando CREATE TABLE sem schema qualificado..."

# Regex: CREATE TABLE [IF NOT EXISTS] <nome_sem_schema> (
# Detecta: CREATE TABLE obras ( ou CREATE TABLE IF NOT EXISTS obras (
# Ignora: CREATE TABLE schema.tabela (
if grep -RIl --include="*.sql" -E "CREATE[[:space:]]+TABLE[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(" "$MIG_DIR" 2>/dev/null | \
   xargs grep -E "CREATE[[:space:]]+TABLE[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(" | \
   grep -v -E "[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*"; then
  
  abort "ERRO: CREATE TABLE sem schema qualificado detectado. Use 'schema.tabela' (ex: operacional.obras)." 4
fi

log_info "✅ Todas as tabelas possuem schema qualificado."

# ============================================
# LINT 3: PROIBIR CREATE VIEW FORA DE 'vw.*'
# ============================================
log_info "Executando lint: verificando CREATE VIEW fora de 'vw.*'..."

# Detecta: CREATE [OR REPLACE] VIEW <nome> onde <nome> não começa com 'vw.'
if grep -RIl --include="*.sql" -E "CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?VIEW[[:space:]]+" "$MIG_DIR" 2>/dev/null | \
   xargs grep -E "CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?VIEW[[:space:]]+[^v]" | \
   grep -v -E "CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?VIEW[[:space:]]+vw\."; then
  
  abort "ERRO: CREATE VIEW fora do schema 'vw.*' detectado. Todas as views devem ser criadas em 'vw.*'." 5
fi

log_info "✅ Todas as views estão no schema 'vw.*'."

# ============================================
# ORDEM DETERMINÍSTICA DAS MIGRATIONS (DINÂMICA)
# ============================================
mapfile -t MIGRATION_FILES < <(ls -1 "${MIG_DIR}"/*.sql | sort)

if [[ ${#MIGRATION_FILES[@]} -eq 0 ]]; then
  abort "Nenhuma migration encontrada em ${MIG_DIR}" 7
fi

first=$(basename "${MIGRATION_FILES[0]}")
last=$(basename "${MIGRATION_FILES[-1]}")
log_info "Iniciando aplicação das migrations (ordem: ${first%%_*} → ${last%%_*})..."
echo "" >> "$LOG_FILE"

TOTAL=${#MIGRATION_FILES[@]}
COUNT=0

for MIG_PATH in "${MIGRATION_FILES[@]}"; do
  base="$(basename "$MIG_PATH")"
  COUNT=$((COUNT + 1))
  log_info "[${COUNT}/${TOTAL}] Aplicando: ${base}..."

  if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$MIG_PATH" >> "$LOG_FILE" 2>&1; then
    log_info "✅ ${base} aplicada com sucesso."
  else
    abort "ERRO: Falha ao aplicar '${base}'. Verifique o log: ${LOG_FILE}" 6
  fi
done

# ============================================
# VALIDAÇÃO PÓS-APLICAÇÃO
# ============================================
log_info "Validando objetos criados..."

# Contar tabelas por schema
for schema in "auth" "operacional" "financeiro" "audit"; do
  TABLE_COUNT=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc "SELECT COUNT(*) FROM pg_tables WHERE schemaname = '${schema}';")
  log_info "Schema '${schema}': ${TABLE_COUNT} tabelas criadas."
done

# Contar views no schema vw
VIEW_COUNT=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc "SELECT COUNT(*) FROM pg_views WHERE schemaname = 'vw';")
log_info "Schema 'vw': ${VIEW_COUNT} views criadas."

# ============================================
# SUCESSO
# ============================================
echo "" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
echo "Migrations aplicadas com sucesso!" >> "$LOG_FILE"
echo "Data: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

log_info "🎉 Todas as migrations foram aplicadas com sucesso!"
log_info "📄 Log completo: ${LOG_FILE}"
log_info ""
log_info "Próximos passos:"
log_info "  1. Verificar objetos: psql \$DATABASE_URL -c '\\dt auth.* operacional.* financeiro.*'"
log_info "  2. Testar views: psql \$DATABASE_URL -c 'SELECT * FROM vw.vw_pipeline LIMIT 1;'"
log_info "  3. Validar permissões: psql \$DATABASE_URL -c 'SET ROLE gbs_app; SELECT * FROM vw.vw_pipeline LIMIT 1;'"

exit 0

###############################################################################
# USO INTERNO – CONFIDENCIAL
# Globosul Engenharia | ti@globosul.com.br
# Projeto: GBS | Intranet & Dashboards
# Versão: v1.0.2-HML | 06/11/2025
###############################################################################
