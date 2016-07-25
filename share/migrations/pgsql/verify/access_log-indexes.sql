-- Verify asr:access_log-indexes on pg

BEGIN;

SELECT 'access_log-date_trunc-day-ltime'::regclass;
SELECT 'access_log-date_trunc-hour-ltime'::regclass;

ROLLBACK;
