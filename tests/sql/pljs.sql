-- https://github.com/plv8/pljs
CREATE EXTENSION pljs;

DO $$ pljs.elog(NOTICE, "Hello, World!") $$ LANGUAGE pljs;

CREATE FUNCTION pljs_add(a integer, b integer) RETURNS integer LANGUAGE pljs AS $$
	return a + b;
$$;

CREATE FUNCTION pljs_query() RETURNS integer LANGUAGE pljs AS $$
	return pljs.execute("SELECT 40 + 2 AS total")[0].total;
$$;

CREATE FUNCTION pljs_keys(value jsonb) RETURNS text LANGUAGE pljs AS $$
	return Object.keys(value).sort().join(",");
$$;

SELECT plan(3);
SELECT is(pljs_add(1, 2), 3, 'PL/JS functions run');
SELECT is(pljs_query(), 42, 'PL/JS runs queries');
SELECT is(pljs_keys('{"b": 1, "a": 2}'::jsonb), 'a,b', 'jsonb values arrive as objects');
SELECT * FROM finish(TRUE);
