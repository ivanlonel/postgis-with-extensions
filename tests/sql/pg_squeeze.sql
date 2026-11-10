-- preload: pg_squeeze
-- https://github.com/cybertec-postgresql/pg_squeeze
CREATE EXTENSION pg_squeeze;

SELECT * FROM squeeze.tables;
SELECT squeeze.start_worker();
SELECT squeeze.stop_worker();
