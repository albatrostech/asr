-- Deploy asr:user-table to pg
-- requires: setmodified

BEGIN;

CREATE TABLE "user" (
   id SERIAL NOT NULL PRIMARY KEY,
   login VARCHAR(64) NOT NULL UNIQUE,
   name VARCHAR(255),
   password VARCHAR(128) NOT NULL,
   created TIMESTAMP without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
   modified TIMESTAMP without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER setmodified BEFORE INSERT OR UPDATE ON "user" FOR EACH ROW EXECUTE PROCEDURE setmodified();

COMMIT;
