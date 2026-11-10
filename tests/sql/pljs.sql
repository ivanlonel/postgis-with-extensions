-- https://github.com/plv8/pljs
CREATE EXTENSION pljs;

DO $$ pljs.elog(NOTICE, "Hello, World!") $$ LANGUAGE pljs;

CREATE FUNCTION pljs_add(a integer, b integer) RETURNS integer LANGUAGE pljs AS $$
	return a + b;
$$;

SELECT plan(1);
SELECT is(pljs_add(1, 2), 3, 'PL/JS functions run');
SELECT * FROM finish(TRUE);
