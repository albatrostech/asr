-- Verify asr:setmodified on pg

BEGIN;

SELECT has_function_privilege('setmodified()', 'execute');

ROLLBACK;
