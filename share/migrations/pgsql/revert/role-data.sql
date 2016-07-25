-- Revert asr:role-data from pg

BEGIN;

DELETE FROM "role" WHERE id = 0;

COMMIT;
