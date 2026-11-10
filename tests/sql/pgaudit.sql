-- preload: pgaudit
-- https://github.com/pgaudit/pgaudit
CREATE EXTENSION pgaudit;

SELECT set_config('pgaudit.log', 'all, -misc', FALSE);
SELECT set_config('pgaudit.log_level', 'notice', FALSE);
CREATE TABLE audited (id integer);
