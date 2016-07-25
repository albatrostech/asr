-- Revert asr:user-data from pg

BEGIN;

DELETE FROM "user" WHERE id = 0;

COMMIT;
