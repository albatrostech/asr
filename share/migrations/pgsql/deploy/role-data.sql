-- Deploy asr:role-data to pg
-- requires: role-table

BEGIN;

INSERT INTO "role" (id, name, description) VALUES (0, 'admin', 'Administrator Role');

COMMIT;
