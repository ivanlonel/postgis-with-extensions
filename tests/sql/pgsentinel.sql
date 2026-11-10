-- preload: pg_stat_statements, pgsentinel
-- https://github.com/pgsentinel/pgsentinel
CREATE EXTENSION pg_stat_statements;
CREATE EXTENSION pgsentinel;

-- Stay active for a few sampling periods (one second each).
SELECT pg_sleep(3);

SELECT plan(2);
SELECT ok(
	(
		SELECT count(*) > 0 FROM pg_active_session_history
		WHERE pid = pg_backend_pid()
	),
	'active sessions are sampled'
);
SELECT ok(
	(
		SELECT count(*) > 0 FROM pg_active_session_history
		WHERE pid = pg_backend_pid() AND wait_event = 'PgSleep'
	),
	'samples record what sessions wait for'
);
SELECT * FROM finish(TRUE);
