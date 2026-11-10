-- preload: pglogical, pglogical_ticker
-- pg: <=17
-- https://github.com/enova/pglogical_ticker
CREATE EXTENSION pglogical_ticker CASCADE;  -- requires pglogical

-- One ticker table per replication set of this provider node.
SELECT pglogical.create_node(node_name := 'pwe_ticker_provider', dsn := format('dbname=%s', current_database()));
SELECT pglogical_ticker.deploy_ticker_tables();
SELECT pglogical_ticker.tick();

SELECT plan(2);
SELECT is(
	(SELECT count(*) FROM pglogical_ticker."default"),
	1::bigint,
	'ticks are recorded per replication set'
);
-- The background worker ticks on its own (every pglogical_ticker.naptime, 10 seconds).
CREATE TEMPORARY TABLE first_tick AS SELECT source_time FROM pglogical_ticker."default";
SELECT pglogical_ticker.launch();
SELECT ok(
	wait_until(
		'SELECT (SELECT source_time FROM pglogical_ticker."default") > (SELECT source_time FROM first_tick)',
		'60 seconds'
	),
	'the ticker worker ticks'
);
SELECT * FROM finish(TRUE);
