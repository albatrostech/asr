-- Revert asr:user_role-table from pg

BEGIN;

DROP TABLE user_role;

COMMIT;
