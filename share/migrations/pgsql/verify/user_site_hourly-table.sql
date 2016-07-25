-- Verify asr:user_site_hourly-table on pg

BEGIN;

SELECT
   id,
   local_time,
   remote_user,
   site,
   total_time,
   total_bytes
   FROM
      user_site_hourly
   WHERE
      FALSE;

ROLLBACK;
