-- preload: powa
-- https://github.com/powa-team/powa-archivist
CREATE EXTENSION powa CASCADE;

CREATE TABLE pwe_powa_workload AS SELECT i FROM generate_series(1, 1000) AS i;
SELECT count(*) FROM pwe_powa_workload
WHERE i < 10;

SELECT powa_take_snapshot();

SELECT plan(2);
SELECT ok(
    (
        SELECT count(*) > 0 FROM powa_statements
        WHERE query LIKE '%pwe_powa_workload%'
    ),
    'snapshots archive the statements'
);
SELECT ok(
    (
        SELECT count(*) > 0 FROM powa_functions
        WHERE name = 'pg_stat_statements' AND enabled
    ),
    'statistics sources are registered'
);
SELECT * FROM finish(TRUE);
