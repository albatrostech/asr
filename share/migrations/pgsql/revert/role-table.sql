-- Revert asr:role-table from pg

BEGIN;

DROP TRIGGER setmodified ON role;
DROP TABLE role;

COMMIT;
