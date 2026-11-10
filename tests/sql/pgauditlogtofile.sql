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

SELECT plan(2);
SELECT ok(
	wait_until(
		$$
			SELECT EXISTS (
				SELECT FROM pg_ls_dir(current_setting('pgaudit.log_directory'), TRUE, FALSE) AS f
				WHERE f ~ '^audit-\d{8}_\d{4}\.log$'
			)
		$$,
		'10 seconds'
	),
	'audit files are named after pgaudit.log_filename'
);
SELECT ok(
	wait_until(
		$$
			SELECT EXISTS (
				SELECT FROM pg_ls_dir(current_setting('pgaudit.log_directory'), TRUE, FALSE) AS f
				WHERE pg_read_file(current_setting('pgaudit.log_directory') || '/' || f)
				LIKE '%DDL,CREATE TABLE%pwe_ddl_audited%'
			)
		$$,
		'10 seconds'
	),
	'audit records are written to the file'
);
SELECT * FROM finish(TRUE);
