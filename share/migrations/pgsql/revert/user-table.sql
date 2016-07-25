-- Revert asr:user-table from pg

BEGIN;

DROP TRIGGER setmodified ON "user";
DROP TABLE "user";

COMMIT;
