-- Deploy asr:user_role-data to pg
-- requires: user_role-table

BEGIN;

INSERT INTO "user_role" (user_id, role_id) VALUES (0, 0);

COMMIT;
