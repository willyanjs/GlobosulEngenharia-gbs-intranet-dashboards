-- HOTFIX 011: triggers idempotentes para financeiro.glosas
-- Pré-condições
DO $do$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname='financeiro') THEN
    RAISE EXCEPTION 'Schema "financeiro" não existe.';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_class
    WHERE relname='glosas' AND relnamespace='financeiro'::regnamespace
  ) THEN
    RAISE EXCEPTION 'Tabela "financeiro.glosas" não existe.';
  END IF;
  -- Garante que as funções criadas na 011 existem
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc
    WHERE pronamespace='financeiro'::regnamespace AND proname='update_glosas_timestamp'
  ) THEN
    RAISE EXCEPTION 'Função financeiro.update_glosas_timestamp() ausente.';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc
    WHERE pronamespace='financeiro'::regnamespace AND proname='sync_glosa_to_medicao'
  ) THEN
    RAISE EXCEPTION 'Função financeiro.sync_glosa_to_medicao() ausente.';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc
    WHERE pronamespace='financeiro'::regnamespace AND proname='sync_glosa_delete_to_medicao'
  ) THEN
    RAISE EXCEPTION 'Função financeiro.sync_glosa_delete_to_medicao() ausente.';
  END IF;
END
$do$;

-- trg_glosas_updated_at (BEFORE UPDATE)
DO $do$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgrelid='financeiro.glosas'::regclass
      AND tgname='trg_glosas_updated_at'
  ) THEN
    EXECUTE $ddl$
      CREATE TRIGGER trg_glosas_updated_at
      BEFORE UPDATE ON financeiro.glosas
      FOR EACH ROW
      EXECUTE FUNCTION financeiro.update_glosas_timestamp();
    $ddl$;
  END IF;
END
$do$;

-- trg_glosas_sync_medicao (AFTER INSERT OR UPDATE)
DO $do$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgrelid='financeiro.glosas'::regclass
      AND tgname='trg_glosas_sync_medicao'
  ) THEN
    EXECUTE $ddl$
      CREATE TRIGGER trg_glosas_sync_medicao
      AFTER INSERT OR UPDATE ON financeiro.glosas
      FOR EACH ROW
      EXECUTE FUNCTION financeiro.sync_glosa_to_medicao();
    $ddl$;
  END IF;
END
$do$;

-- trg_glosas_sync_medicao_delete (AFTER DELETE)
DO $do$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgrelid='financeiro.glosas'::regclass
      AND tgname='trg_glosas_sync_medicao_delete'
  ) THEN
    EXECUTE $ddl$
      CREATE TRIGGER trg_glosas_sync_medicao_delete
      AFTER DELETE ON financeiro.glosas
      FOR EACH ROW
      EXECUTE FUNCTION financeiro.sync_glosa_delete_to_medicao();
    $ddl$;
  END IF;
END
$do$;
