-- Deploy asr:access_log-indexes to pg
-- requires: access_log-table

BEGIN;

CREATE INDEX "access_log-date_trunc-day-ltime" ON access_log USING BTREE (date_trunc('day'::text, ltime));
CREATE INDEX "access_log-date_trunc-hour-ltime" ON access_log USING BTREE (date_trunc('hour'::text, ltime));

COMMIT;
