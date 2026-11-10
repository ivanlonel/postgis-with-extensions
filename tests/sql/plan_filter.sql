-- preload: plan_filter
-- https://github.com/pgexperts/pg_plan_filter
-- A library, not an extension: it rejects statements whose estimated cost passes a limit.
CREATE TABLE costly AS SELECT generate_series(1, 100000) AS id;
ANALYZE costly;

SELECT set_config('plan_filter.statement_cost_limit', '500', FALSE);
SELECT plan(2);
SELECT throws_like('SELECT count(*) FROM costly', '%cost%', 'costlier statements are rejected');
SELECT lives_ok('SELECT id FROM costly LIMIT 1', 'cheaper ones run');
SELECT set_config('plan_filter.statement_cost_limit', '0', FALSE);
SELECT * FROM finish(TRUE);
