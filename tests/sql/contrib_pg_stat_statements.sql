-- preload: pg_stat_statements
-- https://www.postgresql.org/docs/current/pgstatstatements.html
CREATE EXTENSION pg_stat_statements;

CREATE TABLE pwe_tracked AS SELECT i FROM generate_series(1, 100) AS i;
SELECT count(*) FROM pwe_tracked
WHERE i > 50;
SELECT count(*) FROM pwe_tracked
WHERE i > 70;

SELECT plan(1);
SELECT cmp_ok(
    (
        SELECT sum(calls) FROM pg_stat_statements
        WHERE query LIKE 'SELECT count(*) FROM pwe_tracked%'
    ),
    '>=',
    2::numeric,
    'statements are normalized and counted'
);
SELECT * FROM finish(TRUE);
