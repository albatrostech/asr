-- Revert asr:user_site_hourly-indexes from pg

BEGIN;

DROP INDEX "user_site_hourly-date_trunc-day-local_time";
DROP INDEX "user_site_hourly-local_time-remote_user-site";

COMMIT;
