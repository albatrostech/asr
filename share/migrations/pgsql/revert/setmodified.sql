-- Revert asr:setmodified from pg

BEGIN;

DROP FUNCTION setmodified();

COMMIT;
