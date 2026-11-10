-- preload: pg_stat_statements, pgsentinel
-- database: sentinel
-- https://github.com/pgsentinel/pgsentinel
-- The sampling worker only samples once the extension exists in its database.
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pgsentinel;

-- Samples are taken every second; wait_until sleeps between its polls.
SELECT plan(2);
SELECT ok(
    wait_until(
        $$SELECT EXISTS (SELECT FROM pg_active_session_history WHERE pid = pg_backend_pid())$$,
        '20 seconds'
    ),
    'active sessions are sampled'
);
SELECT ok(
    EXISTS (
        SELECT FROM pg_active_session_history
        WHERE pid = pg_backend_pid() AND wait_event = 'PgSleep'
    ),
    'samples record what sessions wait for'
);
SELECT * FROM finish(TRUE);
