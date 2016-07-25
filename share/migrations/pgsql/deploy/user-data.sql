-- Deploy asr:user-data to pg
-- requires: user-table

BEGIN;

INSERT INTO "user" (id, login, name, password) VALUES (0, 'admin', 'Administrator', '$PBKDF2$HMACSHA1:10000:V1vkyg==$KYm4g9zuezKKOQ2lrIapwBqoqH0=');

COMMIT;
