-- Deploy asr:materialize_user_site_hourly to pg
-- requires: user_site_hourly-table
-- requires: access_log-table

BEGIN;

CREATE FUNCTION materialize_user_site_hourly(boolean, date, date) RETURNS integer
LANGUAGE plpgsql
AS $_$
DECLARE
   affected_rows INT := 0;
   affected_tmp INT := 0;
   keep_detail ALIAS FOR $1;
   start_date DATE := $2;
   end_date ALIAS FOR $3;
BEGIN
   WHILE start_date < end_date + 1 LOOP
      SELECT materialize_user_site_hourly(keep_detail, start_date) INTO affected_tmp;
      affected_rows := affected_rows + affected_tmp;
      start_date := start_date + 1;
   END LOOP;

   RETURN affected_rows;
END;
$_$;

CREATE FUNCTION materialize_user_site_hourly(boolean, date) RETURNS integer
LANGUAGE plpgsql
AS $_$
DECLARE
   affected_rows INT;
   keep_detail ALIAS FOR $1;
   relevant_day ALIAS FOR $2;
BEGIN
   INSERT INTO user_site_hourly(local_time,remote_user,site,total_time,total_bytes)
   SELECT date_trunc('hour', ltime) AS local_time, COALESCE(ruser, HOST(ip)) AS remote_user, site AS site, SUM(elapsed) AS total_time, SUM(bytes) AS total_bytes
   FROM access_log
   WHERE date_trunc('day', ltime) = relevant_day AND code <> 'TCP_DENIED' AND code LIKE 'TCP_%'
   GROUP BY local_time, remote_user, site
   ORDER BY local_time, remote_user, site, total_time, total_bytes;

   IF keep_detail THEN
      UPDATE access_log AS al
      SET ush_id = ush.id
      FROM user_site_hourly AS ush
      WHERE (date_trunc('hour', local_time) = date_trunc('hour', ltime))
      AND (al.site = ush.site) AND (COALESCE(ruser,HOST(ip)) = ush.remote_user)
      AND (date_trunc('day', ltime) = relevant_day);
   ELSE
      DELETE FROM access_log WHERE date_trunc('day', ltime) = relevant_day;
   END IF;

   GET DIAGNOSTICS affected_rows = ROW_COUNT;
   RETURN affected_rows;
END;
$_$;

COMMIT;
