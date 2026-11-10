-- preload: pgauditlogtofile
-- https://github.com/pgaudit/pgaudit
-- pgaudit writes audit records to the server log or, with pgauditlogtofile (which brings pgaudit),
-- to CSV files in pgaudit.log_directory, where SQL can read them back. Each backend buffers its
-- writes until it exits, so the audited statements run in a session of their own, through dblink.
CREATE EXTENSION pgaudit;
CREATE EXTENSION pgauditlogtofile;
CREATE EXTENSION dblink;

CREATE TABLE pwe_audited (id integer);
SELECT n FROM dblink(
	format('dbname=%s', current_database()),
	$$SET pgaudit.log = 'read, write'; INSERT INTO pwe_audited VALUES (1); SELECT count(*) FROM pwe_audited$$
) AS t (n bigint);
SELECT n FROM dblink(
	format('dbname=%s', current_database()),
	'SET pgaudit.log = none; SELECT count(*) FROM pwe_audited WHERE id = 42'
) AS t (n bigint);

-- The audit files: CSV, one record per line.
CREATE FUNCTION audit_log() RETURNS text LANGUAGE sql AS $$
	SELECT coalesce(string_agg(pg_read_file(current_setting('pgaudit.log_directory') || '/' || f), E'\n'), '')
	FROM pg_ls_dir(current_setting('pgaudit.log_directory'), TRUE, FALSE) AS f
	WHERE f LIKE 'audit-%'
$$;
SELECT wait_until($$SELECT audit_log() ~ 'pwe_audited'$$, '10 seconds');

SELECT plan(3);
SELECT matches(audit_log(), 'READ"?,"?SELECT"?,[^\n]*pwe_audited', 'reads are audited');
SELECT matches(audit_log(), 'WRITE"?,"?INSERT"?,[^\n]*pwe_audited', 'writes are audited');
SELECT doesnt_match(audit_log(), 'id = 42', 'statements are not audited once logging is off');
SELECT * FROM finish(TRUE);
