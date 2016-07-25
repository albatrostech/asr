-- Revert asr:access_log-indexes from pg

BEGIN;

DROP INDEX "access_log-date_trunc-day-ltime";
DROP INDEX "access_log-date_trunc-hour-ltime";

COMMIT;
