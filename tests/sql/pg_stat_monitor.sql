-- preload: pg_stat_monitor
-- https://github.com/percona/pg_stat_monitor
CREATE EXTENSION pg_stat_monitor;

SELECT count(*) FROM pg_stat_monitor;
