-- =====================================================
-- Migration: 000_create_schemas.sql
-- Sprint: Base - Schemas
-- Descrição: Criação de schemas segmentados por domínio (idempotente)
-- Data: 06/11/2025
-- =====================================================

-- Schemas por domínio de negócio
-- Arquitetura aprovada: segmentação para segurança (RBAC) e governança

-- Schema: Autenticação e Credenciais
CREATE SCHEMA IF NOT EXISTS auth;
COMMENT ON SCHEMA auth IS 'Autenticação - usuarios, sessoes, reset_tokens';

-- Schema: Operacional (Cadastros Mestres)
CREATE SCHEMA IF NOT EXISTS operacional;
COMMENT ON SCHEMA operacional IS 'Operacional - obras, contratos, dimensões';

-- Schema: Financeiro (Pipeline de Medições)
CREATE SCHEMA IF NOT EXISTS financeiro;
COMMENT ON SCHEMA financeiro IS 'Financeiro - medicoes, NFs, pagamentos, glosas';

-- Schema: Programação (Sprint 3 - futuro)
CREATE SCHEMA IF NOT EXISTS programacao;
COMMENT ON SCHEMA programacao IS 'Programação - veículos, O.S., GUT';

-- Schema: Comercial (futuro)
CREATE SCHEMA IF NOT EXISTS comercial;
COMMENT ON SCHEMA comercial IS 'Comercial - propostas, contratos comerciais';

-- Schema: Staging (ETL/Integração)
CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS 'Staging - área temporária para ETL e integrações';

-- Schema: Auditoria
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS 'Auditoria - logs de eventos críticos e financeiros';

-- Schema: Views Consolidadas
CREATE SCHEMA IF NOT EXISTS vw;
COMMENT ON SCHEMA vw IS 'Views - consumo read-only para dashboards';

-- =====================================================
-- CRÍTICO: Schema PUBLIC permanece BLOQUEADO
-- Nenhuma tabela de negócio deve ser criada em public
-- =====================================================

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
