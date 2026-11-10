-- preload: pgnodemx
-- https://github.com/CrunchyData/pgnodemx
CREATE EXTENSION pgnodemx;

SELECT cgroup_mode();
SELECT * FROM proc_mountinfo() LIMIT 5;

SELECT plan(1);
SELECT is(envvar_text('PGDATA'), current_setting('data_directory'), 'environment variables are read');
SELECT * FROM finish(TRUE);
