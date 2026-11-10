-- preload: pgmemcache
-- https://github.com/ohmu/pgmemcache
-- No memcached server runs in the tests: this proves the client library loads and is driven.
CREATE EXTENSION pgmemcache;

SELECT plan(2);
SELECT lives_ok($$SELECT memcache_server_add('127.0.0.1:11211')$$, 'servers are added');
SELECT is(memcache_get('pwe-missing-key'), NULL, 'reads without a reachable server find nothing');
SELECT * FROM finish(TRUE);
