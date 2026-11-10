-- preload: pg_show_plans
-- pg: >=15
-- https://github.com/cybertec-postgresql/pg_show_plans
-- (On PostgreSQL 14, plan collection can only be turned on at startup: see tests/test_preload.py.)
CREATE EXTENSION pg_show_plans;

-- The image turns plan collection off (it crashes TimescaleDB inserts): turn it on for this session.
SELECT set_config('pg_show_plans.is_enabled', 'on', FALSE);

SELECT plan(1);
SELECT matches(
	(
		SELECT string_agg(plan, ' ') FROM pg_show_plans
		WHERE pid = pg_backend_pid()
	),
	'Function Scan on pg_show_plans',
	'the plans of running statements are shown'
);
SELECT * FROM finish(TRUE);
