-- =====================================================
-- Migration: 001_auth_usuarios.sql
-- Sprint: 1 - Auth & RBAC
-- Descrição: Tabela de usuários no schema auth
-- Data: 06/11/2025 (refatorado para schemas)
-- Versão: v1.0.2-HML (corrigido: trigger idempotente + OWNER)
-- =====================================================

-- ============================================
-- UP: Criação do ENUM e Tabela de Usuários
-- ============================================

-- ENUM para roles (papéis) - idempotente
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    WHERE t.typname = 'role_usuario'
      AND t.typnamespace = 'auth'::regnamespace
  ) THEN
    CREATE TYPE auth.role_usuario AS ENUM (
      'ADMIN',
      'FINANCEIRO',
      'OPERACOES',
      'GESTOR_OBRAS',
      'MANUTENCAO',
      'CONSULTA'
    );
  END IF;
END$$;

-- Garantir que todos os valores existem (sem erro se já existirem)
ALTER TYPE auth.role_usuario ADD VALUE IF NOT EXISTS 'ADMIN';
ALTER TYPE auth.role_usuario ADD VALUE IF NOT EXISTS 'FINANCEIRO';
ALTER TYPE auth.role_usuario ADD VALUE IF NOT EXISTS 'OPERACOES';
ALTER TYPE auth.role_usuario ADD VALUE IF NOT EXISTS 'GESTOR_OBRAS';
ALTER TYPE auth.role_usuario ADD VALUE IF NOT EXISTS 'MANUTENCAO';
ALTER TYPE auth.role_usuario ADD VALUE IF NOT EXISTS 'CONSULTA';

-- Tabela de usuários (schema auth)
CREATE TABLE IF NOT EXISTS auth.usuarios (
    id_usuario UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Credenciais
    email VARCHAR(255) NOT NULL UNIQUE,
    senha_hash TEXT NOT NULL, -- Argon2id
    
    -- Dados pessoais
    nome_completo VARCHAR(255) NOT NULL,
    telefone VARCHAR(20),
    
    -- Controle de acesso
    role auth.role_usuario NOT NULL DEFAULT 'CONSULTA',
    ativo BOOLEAN NOT NULL DEFAULT true,
    
    -- Lockout (proteção brute-force)
    tentativas_login INTEGER NOT NULL DEFAULT 0,
    bloqueado_ate TIMESTAMPTZ,
    
    -- Auditoria
    ultimo_login TIMESTAMPTZ,
    ultimo_ip INET,
    
    -- Controle
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices otimizados
CREATE INDEX IF NOT EXISTS idx_usuarios_email 
    ON auth.usuarios(email);

CREATE INDEX IF NOT EXISTS idx_usuarios_role 
    ON auth.usuarios(role);

CREATE INDEX IF NOT EXISTS idx_usuarios_ativo 
    ON auth.usuarios(ativo);

CREATE INDEX IF NOT EXISTS idx_usuarios_bloqueado 
    ON auth.usuarios(bloqueado_ate) 
    WHERE bloqueado_ate IS NOT NULL;

-- Comentários
COMMENT ON TABLE auth.usuarios IS 'Usuários do sistema - autenticação e RBAC';
COMMENT ON COLUMN auth.usuarios.senha_hash IS 'Hash Argon2id da senha';
COMMENT ON COLUMN auth.usuarios.tentativas_login IS 'Contador de tentativas (reset ao sucesso)';
COMMENT ON COLUMN auth.usuarios.bloqueado_ate IS 'Timestamp até quando usuário está bloqueado (lockout)';

-- =====================================================
-- v1.0.2-HML — Bloco idempotente para função/trigger
-- =====================================================

-- Função: atualiza updated_at antes de UPDATE
CREATE OR REPLACE FUNCTION auth.update_usuarios_timestamp()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$fn$;

-- Ownership explícito
ALTER FUNCTION auth.update_usuarios_timestamp() OWNER TO gbs_dev;

-- Trigger: criar somente se ainda não existir
DO $do$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trg_usuarios_updated_at'
      AND tgrelid = 'auth.usuarios'::regclass
  ) THEN
    CREATE TRIGGER trg_usuarios_updated_at
      BEFORE UPDATE ON auth.usuarios
      FOR EACH ROW
      EXECUTE FUNCTION auth.update_usuarios_timestamp();
  END IF;
END
$do$;

-- ============================================
-- DOWN: Rollback
-- ============================================

-- DROP TRIGGER IF EXISTS trg_usuarios_updated_at ON auth.usuarios;
-- DROP FUNCTION IF EXISTS auth.update_usuarios_timestamp();
-- DROP INDEX IF EXISTS idx_usuarios_bloqueado;
-- DROP INDEX IF EXISTS idx_usuarios_ativo;
-- DROP INDEX IF EXISTS idx_usuarios_role;
-- DROP INDEX IF EXISTS idx_usuarios_email;
-- DROP TABLE IF EXISTS auth.usuarios CASCADE;
-- DROP TYPE IF EXISTS auth.role_usuario CASCADE;

-- =====================================================
-- NOTA v1.0.2-HML:
-- Corrigido CREATE TYPE para padrão idempotente com DO $ ... END$
-- Adicionados ALTER TYPE ... ADD VALUE IF NOT EXISTS para garantir valores
-- Trigger agora é idempotente (verificação de existência antes de criar)
-- Função possui OWNER TO gbs_dev explícito
-- Isso permite re-execução da migration sem erros
-- =====================================================

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- =====================================================
