-- preload: pg_stat_statements, pgsentinel
-- https://github.com/pgsentinel/pgsentinel
CREATE EXTENSION pg_stat_statements;
CREATE EXTENSION pgsentinel;

SELECT count(*) FROM pg_active_session_history;
