-- Verify asr:user_site_hourly-indexes on pg

BEGIN;

SELECT 'user_site_hourly-date_trunc-day-local_time'::regclass;
SELECT 'user_site_hourly-local_time-remote_user-site'::regclass;

ROLLBACK;
