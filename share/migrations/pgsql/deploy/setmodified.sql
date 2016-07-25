-- Deploy asr:setmodified to pg

BEGIN;

CREATE OR REPLACE FUNCTION setmodified() RETURNS TRIGGER AS
$$
BEGIN
  NEW.modified := CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMIT;
