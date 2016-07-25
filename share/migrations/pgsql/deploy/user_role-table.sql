-- Deploy asr:user_role-table to pg
-- requires: user-table
-- requires: role-table

BEGIN;

CREATE TABLE user_role (
   user_id INTEGER NOT NULL REFERENCES "user" (id),
   role_id INTEGER NOT NULL REFERENCES "role" (id)
);

COMMIT;
