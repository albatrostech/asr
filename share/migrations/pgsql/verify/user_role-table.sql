-- Verify asr:user_role-table on pg

BEGIN;

SELECT
   user_id,
   role_id
   FROM
      user_role
   WHERE
      FALSE;

ROLLBACK;
