-- Revert asr:access_log-table from pg

BEGIN;

DROP TABLE access_log;

COMMIT;
