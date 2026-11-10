-- preload: pgauditlogtofile
-- https://github.com/pgaudit/pgaudit
-- Audit records go to the server log; pgauditlogtofile (which brings pgaudit) also writes them to
-- files in pgaudit.log_directory, where SQL can read them back.
CREATE EXTENSION pgaudit;
CREATE EXTENSION pgauditlogtofile;

CREATE TABLE pwe_audited (id integer);
SELECT set_config('pgaudit.log', 'read, write', FALSE);
INSERT INTO pwe_audited VALUES (1);
SELECT count(*) FROM pwe_audited;
SELECT set_config('pgaudit.log', 'none', FALSE);
SELECT count(*) FROM pwe_audited
WHERE id = 42;

CREATE FUNCTION audit_log() RETURNS text LANGUAGE sql AS $$
	SELECT coalesce(string_agg(pg_read_file(current_setting('pgaudit.log_directory') || '/' || f), E'\n'), '')
	FROM pg_ls_dir(current_setting('pgaudit.log_directory'), TRUE, FALSE) AS f
	WHERE f LIKE 'audit-%'
$$;

SELECT plan(3);
SELECT ok(wait_until($$SELECT audit_log() LIKE '%READ,SELECT%pwe_audited%'$$, '10 seconds'), 'reads are audited');
SELECT ok(wait_until($$SELECT audit_log() LIKE '%WRITE,INSERT%pwe_audited%'$$, '10 seconds'), 'writes are audited');
SELECT ok(audit_log() NOT LIKE '%WHERE id = 42%', 'statements are not audited once logging is off');
SELECT * FROM finish(TRUE);
