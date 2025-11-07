-- =====================================================
-- Migration: 015_auth_reset_tokens_patch.sql
-- Sprint: 1 - Auth & RBAC (Hotfix)
-- Descrição: Migração de auditoria boolean para temporal + índices estáveis
-- Objetivo:
--   1) Migrar coluna boolean 'usado' para timestamps de auditoria
--   2) Padronizar índices estáveis sem funções voláteis
--   3) Garantir idempotência e ownership
-- Data: 06/11/2025
-- Versão: v1.0.0-HML
-- =====================================================

-- ============================================
-- UP: Evolução do modelo de reset_tokens
-- ============================================

-- 1) Acrescentar colunas de auditoria temporal (se não existirem)
DO $$
BEGIN
  -- Adicionar usado_em (timestamp de quando o token foi utilizado)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='auth' 
      AND table_name='reset_tokens' 
      AND column_name='usado_em'
  ) THEN
    EXECUTE 'ALTER TABLE auth.reset_tokens ADD COLUMN usado_em TIMESTAMPTZ;';
    RAISE NOTICE 'Coluna usado_em adicionada';
  ELSE
    RAISE NOTICE 'Coluna usado_em já existe';
  END IF;

  -- Adicionar revogado_em (timestamp de revogação manual)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='auth' 
      AND table_name='reset_tokens' 
      AND column_name='revogado_em'
  ) THEN
    EXECUTE 'ALTER TABLE auth.reset_tokens ADD COLUMN revogado_em TIMESTAMPTZ;';
    RAISE NOTICE 'Coluna revogado_em adicionada';
  ELSE
    RAISE NOTICE 'Coluna revogado_em já existe';
  END IF;
END $$;

-- 2) Backfill conservador: migrar dados do boolean 'usado' para 'usado_em'
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='auth' 
      AND table_name='reset_tokens' 
      AND column_name='usado'
  ) THEN
    -- Backfill: só seta usado_em se usado=true e usado_em ainda estiver nulo
    EXECUTE $SQL$
      UPDATE auth.reset_tokens
         SET usado_em = COALESCE(usado_em, NOW())
       WHERE usado = TRUE
         AND usado_em IS NULL
    $SQL$;
    RAISE NOTICE 'Backfill executado: boolean usado → timestamp usado_em';
  ELSE
    RAISE NOTICE 'Coluna usado (boolean) não existe, backfill ignorado';
  END IF;
END $$;

-- 3) Remover índices legados com predicados voláteis (se existirem)
DROP INDEX IF EXISTS auth.idx_reset_tokens_expirados;
DROP INDEX IF EXISTS idx_reset_tokens_expirados;

-- 4) Recriar índice parcial "estável" sem funções voláteis
-- Token ativo = não usado E não revogado (expiração verificada em runtime)
DROP INDEX IF EXISTS auth.idx_reset_tokens_ativos;

CREATE INDEX IF NOT EXISTS idx_reset_tokens_ativos
  ON auth.reset_tokens (id_usuario, expira_em)
  WHERE usado_em IS NULL AND revogado_em IS NULL;

-- 5) Garantir índices base (idempotente)
CREATE INDEX IF NOT EXISTS idx_reset_tokens_user_id
  ON auth.reset_tokens (id_usuario);

CREATE INDEX IF NOT EXISTS idx_reset_tokens_token
  ON auth.reset_tokens (token);

CREATE INDEX IF NOT EXISTS idx_reset_tokens_expires_at
  ON auth.reset_tokens (expira_em);

-- 6) Remover coluna legada 'usado' (boolean) após migração
-- ATENÇÃO: Executar somente após verificar que backend foi atualizado
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='auth' 
      AND table_name='reset_tokens' 
      AND column_name='usado'
  ) THEN
    EXECUTE 'ALTER TABLE auth.reset_tokens DROP COLUMN usado;';
    RAISE NOTICE 'Coluna usado (boolean) removida com sucesso';
  ELSE
    RAISE NOTICE 'Coluna usado (boolean) já foi removida';
  END IF;
END $$;

-- 7) Ownership e segurança
ALTER TABLE auth.reset_tokens OWNER TO gbs_dev;

-- 8) Comentários explicativos
COMMENT ON TABLE auth.reset_tokens 
  IS 'Tokens de reset de senha - one-time use, TTL 1 hora, auditoria temporal';

COMMENT ON COLUMN auth.reset_tokens.usado_em 
  IS 'Timestamp de quando o token foi utilizado (one-time use)';

COMMENT ON COLUMN auth.reset_tokens.revogado_em 
  IS 'Timestamp de quando o token foi revogado manualmente';

COMMENT ON COLUMN auth.reset_tokens.expira_em 
  IS 'Timestamp de expiração (TTL 1 hora). Comparação feita em runtime: WHERE expira_em > now()';

-- ============================================
-- DOWN: Rollback (best-effort)
-- ============================================

-- ATENÇÃO: Reversão completa não é possível sem perda de dados
-- Este rollback remove apenas índices e comentários

-- DROP INDEX IF EXISTS auth.idx_reset_tokens_ativos;
-- DROP INDEX IF EXISTS auth.idx_reset_tokens_expires_at;
-- DROP INDEX IF EXISTS auth.idx_reset_tokens_token;
-- DROP INDEX IF EXISTS auth.idx_reset_tokens_user_id;

-- NOTA: Não é possível recriar a coluna boolean 'usado' com dados originais
-- Para rollback completo, seria necessário:
-- 1) Backup da tabela antes da migration
-- 2) Restauração manual dos dados

-- =====================================================
-- NOTAS TÉCNICAS:
-- 
-- ✅ Idempotência: Todos os comandos verificam existência antes de executar
-- ✅ Segurança: Backfill conservador (COALESCE, não sobrescreve dados)
-- ✅ Performance: Índices parciais otimizados para tokens ativos
-- ✅ Auditoria: Timestamps permitem rastreamento completo do ciclo de vida
-- 
-- ⚠️ IMPORTANTE:
-- - Backend deve usar WHERE usado_em IS NULL para tokens não utilizados
-- - Backend deve usar WHERE expira_em > now() para tokens não expirados
-- - Backend deve setar usado_em = now() ao consumir token
-- - Backend pode setar revogado_em = now() para invalidação manual
-- 
-- 🔄 Ordem de migração (após deploy):
-- 1. Rodar esta migration no banco HML
-- 2. Atualizar backend para usar usado_em/revogado_em
-- 3. Testar fluxo completo (criar, usar, revogar tokens)
-- 4. Promover para PROD após validação
-- =====================================================

-- =====================================================
-- USO INTERNO - CONFIDENCIAL
-- Globosul Engenharia | ti@globosul.com.br
-- Versão: v1.0.0-HML
-- Ambiente: Homologação
-- Data de criação: 06/11/2025
-- Última atualização: 06/11/2025
-- =====================================================
