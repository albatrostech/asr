-- Revert asr:materialize_user_site_hourly from pg

BEGIN;

DROP FUNCTION materialize_user_site_hourly(boolean, date);
DROP FUNCTION materialize_user_site_hourly(boolean, date, date);

COMMIT;
