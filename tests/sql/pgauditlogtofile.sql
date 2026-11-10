-- preload: pgaudit, pgauditlogtofile
-- https://github.com/fmbiete/pgauditlogtofile
CREATE EXTENSION pgaudit;
CREATE EXTENSION pgauditlogtofile;

SELECT
	current_setting('pgaudit.log_directory'),
	current_setting('pgaudit.log_filename'),
	current_setting('pgaudit.log_rotation_age');
