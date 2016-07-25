-- Verify asr:user-data on pg

BEGIN;

SELECT 1/COUNT(*) FROM "user" WHERE id = 0 AND login = 'admin';

COMMIT;
