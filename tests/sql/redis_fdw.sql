-- https://github.com/pg-redis-fdw/redis_fdw
-- No Redis server runs in the tests: the hiredis client must load and try to connect.
CREATE EXTENSION redis_fdw;

CREATE SERVER redis_server FOREIGN DATA WRAPPER redis_fdw OPTIONS (address '127.0.0.1', port '6379');
CREATE USER MAPPING FOR current_user SERVER redis_server;
CREATE FOREIGN TABLE redis_db0 (key text, val text) SERVER redis_server OPTIONS (database '0');

SELECT plan(1);
SELECT matches(error_of('SELECT * FROM redis_db0'), '(?i)connect', 'the client tries to connect');
SELECT * FROM finish(TRUE);
