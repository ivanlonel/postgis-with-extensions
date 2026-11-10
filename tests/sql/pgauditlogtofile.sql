-- preload: pgaudit, pgauditlogtofile
-- https://github.com/fmbiete/pgauditlogtofile
-- Each backend buffers its audit file writes until it exits: audit a session of its own.
CREATE EXTENSION pgaudit;
CREATE EXTENSION pgauditlogtofile;
CREATE EXTENSION dblink;

SELECT dblink_exec(
    format('dbname=%s', current_database()),
    'SET pgaudit.log = ddl; CREATE TABLE pwe_ddl_audited (id integer)'
);

-- The audit files: CSV, one record per line.
CREATE FUNCTION audit_log() RETURNS text LANGUAGE sql AS $$
    SELECT coalesce(string_agg(pg_read_file(current_setting('pgaudit.log_directory') || '/' || f), E'\n'), '')
    FROM pg_ls_dir(current_setting('pgaudit.log_directory'), TRUE, FALSE) AS f
    WHERE f ~ '^audit-\d{8}_\d{4}\.log$'
$$;
SELECT wait_until($$SELECT audit_log() ~ 'pwe_ddl_audited'$$, '10 seconds');

SELECT plan(2);
SELECT ok(
    EXISTS (
        SELECT FROM pg_ls_dir(current_setting('pgaudit.log_directory'), TRUE, FALSE) AS f
        WHERE f ~ '^audit-\d{8}_\d{4}\.log$'
    ),
    'audit files are named after pgaudit.log_filename'
);
SELECT matches(
    audit_log(), 'DDL"?,"?CREATE TABLE"?,[^\n]*pwe_ddl_audited', 'audit records are written to the file as CSV'
);
SELECT * FROM finish(TRUE);
