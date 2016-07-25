-- Verify asr:role-data on pg

BEGIN;

SELECT 1/COUNT(*) FROM role WHERE id = 0 AND name = 'admin';

COMMIT;
