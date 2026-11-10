-- preload: pg_store_plans
-- https://github.com/ossc-db/pg_store_plans
CREATE EXTENSION pg_store_plans;

-- Plans are keyed by query id.
SELECT set_config('compute_query_id', 'on', FALSE);
CREATE TABLE measured (id integer);
INSERT INTO measured SELECT generate_series(1, 100);
SELECT count(*) FROM measured
WHERE id > 50;

SELECT plan(1);
SELECT ok(
    EXISTS (
        SELECT FROM pg_store_plans
        WHERE plan LIKE '%Seq Scan%measured%'
    ),
    'the plans of executed statements are stored'
);
SELECT * FROM finish(TRUE);
