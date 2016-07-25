-- Verify asr:role-table on pg

BEGIN;

SELECT
   id,
   name,
   description,
   created,
   modified
   FROM
      role
   WHERE
      FALSE;

ROLLBACK;
