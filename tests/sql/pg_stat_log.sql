-- preload: pg_stat_log
-- pg: >=18
-- https://github.com/fabriziomello/pg_stat_log
CREATE EXTENSION pg_stat_log;

SELECT * FROM pg_stat_log;
