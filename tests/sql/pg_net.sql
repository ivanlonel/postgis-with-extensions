-- preload: pg_net
-- https://github.com/supabase/pg_net
CREATE EXTENSION pg_net;

SELECT plan(1);
SELECT cmp_ok(net.http_get('http://127.0.0.1:9'), '>', 0::bigint, 'requests are queued');
SELECT * FROM finish(TRUE);
