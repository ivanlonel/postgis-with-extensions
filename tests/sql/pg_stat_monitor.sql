-- preload: pg_stat_monitor
-- https://github.com/percona/pg_stat_monitor
CREATE EXTENSION pg_stat_monitor;

CREATE TABLE pwe_monitored AS SELECT i FROM generate_series(1, 1000) AS i;
SELECT count(*) FROM pwe_monitored;
SELECT count(*) FROM pwe_monitored;

SELECT plan(2);
SELECT ok(
    (
        SELECT count(*) > 0 FROM pg_stat_monitor
        WHERE query LIKE '%FROM pwe_monitored%'
    ),
    'statements are tracked'
);
SELECT cmp_ok(
    (
        SELECT sum(calls) FROM pg_stat_monitor
        WHERE query LIKE 'SELECT count(*) FROM pwe_monitored%'
    ),
    '>=',
    2::numeric,
    'calls are counted'
);
SELECT * FROM finish(TRUE);
