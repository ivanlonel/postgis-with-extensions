-- preload: pgmemcache
-- https://github.com/ohmu/pgmemcache
CREATE EXTENSION pgmemcache;

SELECT memcache_flush_all();
SELECT memcache_stats();
