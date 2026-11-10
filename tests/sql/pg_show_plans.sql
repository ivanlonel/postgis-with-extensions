-- preload: pg_show_plans
-- conflicts: timescaledb
-- pg: >=15
-- https://github.com/cybertec-postgresql/pg_show_plans
-- The image turns plan collection off, as it crashes inserts into TimescaleDB hypertables. Turning
-- it on, even from a session, turns it on for the whole server: hence the conflict. (On PostgreSQL
-- 14, it can only be turned on at startup: see tests/test_preload.py.)
CREATE EXTENSION pg_show_plans;

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
