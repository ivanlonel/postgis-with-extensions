-- preload: pg_wait_sampling
-- https://github.com/postgrespro/pg_wait_sampling
CREATE EXTENSION pg_wait_sampling;

SELECT pg_sleep(1);

SELECT plan(2);
SELECT ok(
	(
		SELECT count(*) > 0 FROM pg_wait_sampling_profile
		WHERE pid = pg_backend_pid() AND event = 'PgSleep'
	),
	'waits are sampled into the profile'
);
SELECT ok(
	(
		SELECT count(*) > 0 FROM pg_wait_sampling_history
		WHERE pid = pg_backend_pid() AND event = 'PgSleep'
	),
	'waits are kept in the history'
);
SELECT * FROM finish(TRUE);
