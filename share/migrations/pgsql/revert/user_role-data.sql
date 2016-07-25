-- Revert asr:user_role-data from pg

BEGIN;

DELETE FROM "user_role" WHERE "user_id" = 0 AND "role_id" = 0;

COMMIT;
