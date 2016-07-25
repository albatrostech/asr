-- Verify asr:user-table on pg

BEGIN;

SELECT
   id,
   login,
   name,
   password,
   created,
   modified
   FROM
      "user"
   WHERE
      FALSE;

ROLLBACK;
