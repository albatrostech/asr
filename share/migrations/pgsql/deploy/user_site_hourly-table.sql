-- Deploy asr:user_site_hourly-table to pg

BEGIN;

CREATE TABLE user_site_hourly (
   id BIGSERIAL NOT NULL PRIMARY KEY,
   local_time TIMESTAMP WITHOUT TIME ZONE NOT NULL,
   remote_user VARCHAR NOT NULL,
   site VARCHAR NOT NULL,
   total_time BIGINT NOT NULL,
   total_bytes BIGINT NOT NULL
);

COMMIT;
