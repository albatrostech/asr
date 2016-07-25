-- Verify asr:user_role-data on pg

BEGIN;

SELECT 1/COUNT(*) FROM user_role WHERE user_id = 0 AND role_id = 0;

COMMIT;
