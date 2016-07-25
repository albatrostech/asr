-- Verify asr:access_log-table on pg

BEGIN;

SELECT
   ltime,
   elapsed,
   ip,
   code,
   status,
   bytes,
   method,
   protocol,
   host,
   site,
   port,
   url,
   ruser,
   peerstatus,
   peerhost,
   mime_type,
   ush_id
   FROM
      access_log
   WHERE
      FALSE;

ROLLBACK;
