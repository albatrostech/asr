-- Revert asr:user_site_hourly-table from pg

BEGIN;

DROP TABLE user_site_hourly;

COMMIT;
