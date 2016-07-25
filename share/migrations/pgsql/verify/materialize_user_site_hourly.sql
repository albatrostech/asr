-- Verify asr:materialize_user_site_hourly on pg

BEGIN;

SELECT has_function_privilege('materialize_user_site_hourly(boolean, date, date)', 'execute');
SELECT has_function_privilege('materialize_user_site_hourly(boolean, date)', 'execute');

ROLLBACK;
