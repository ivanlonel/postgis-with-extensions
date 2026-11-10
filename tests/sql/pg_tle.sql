-- preload: pg_tle
-- https://github.com/aws/pg_tle
CREATE EXTENSION pg_tle;

-- An extension installed from SQL, without files on the server.
SELECT pgtle.install_extension(
	'pwe_tle_hello',
	'1.0',
	'Says hello',
	$_pgtle_$
		CREATE FUNCTION pwe_tle_hello() RETURNS text LANGUAGE sql AS $$ SELECT 'hello from pg_tle' $$;
	$_pgtle_$
);
CREATE EXTENSION pwe_tle_hello;

SELECT plan(2);
SELECT ok(
	EXISTS (
		SELECT FROM pgtle.available_extensions()
		WHERE name = 'pwe_tle_hello'
	),
	'trusted language extensions are listed'
);
SELECT is(pwe_tle_hello(), 'hello from pg_tle', 'and created like any other');
SELECT * FROM finish(TRUE);

DROP EXTENSION pwe_tle_hello;
SELECT pgtle.uninstall_extension('pwe_tle_hello');
