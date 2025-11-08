-- -------------------------------------------------------------------
-- HOTFIX v1.0.2-HML (010): triggers idempotentes em financeiro.pagamentos
-- Requisitos: tabela financeiro.pagamentos e funções:
--   financeiro.update_pagamentos_timestamp()
--   financeiro.update_pagamento_status_on_payment()
-- -------------------------------------------------------------------

-- Pré-checagem: aborta se faltar schema/tabela
DO $do$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname='financeiro') THEN
    RAISE EXCEPTION 'Schema "financeiro" não existe. Rode a migration base antes do HOTFIX.';
  END IF;

  IF NOT EXISTS (
      SELECT 1
      FROM pg_class c
      WHERE c.relname='pagamentos'
        AND c.relnamespace='financeiro'::regnamespace
  ) THEN
    RAISE EXCEPTION 'Tabela "financeiro.pagamentos" não existe. Rode a migration base antes do HOTFIX.';
  END IF;
END
$do$;

-- Criação idempotente das triggers
DO $do$
BEGIN
  -- trg_pagamentos_updated_at
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgrelid = 'financeiro.pagamentos'::regclass
      AND tgname  = 'trg_pagamentos_updated_at'
  ) THEN
    EXECUTE $ddl$
      CREATE TRIGGER trg_pagamentos_updated_at
      BEFORE UPDATE ON financeiro.pagamentos
      FOR EACH ROW
      EXECUTE FUNCTION financeiro.update_pagamentos_timestamp();
    $ddl$;
  END IF;

  -- trg_pagamentos_auto_status
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgrelid = 'financeiro.pagamentos'::regclass
      AND tgname  = 'trg_pagamentos_auto_status'
  ) THEN
    EXECUTE $ddl$
      CREATE TRIGGER trg_pagamentos_auto_status
      BEFORE UPDATE ON financeiro.pagamentos
      FOR EACH ROW
      EXECUTE FUNCTION financeiro.update_pagamento_status_on_payment();
    $ddl$;
  END IF;
END
$do$;
