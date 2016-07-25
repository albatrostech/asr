-- Deploy asr:user_site_hourly-indexes to pg
-- requires: user_site_hourly-table

BEGIN;

CREATE INDEX "user_site_hourly-date_trunc-day-local_time" ON user_site_hourly USING btree (date_trunc('day'::text, local_time));
CREATE UNIQUE INDEX "user_site_hourly-local_time-remote_user-site" ON user_site_hourly USING BTREE (local_time, remote_user, site);

COMMIT;
