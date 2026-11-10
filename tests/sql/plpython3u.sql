-- https://www.postgresql.org/docs/current/plpython.html
CREATE EXTENSION plpython3u;
CREATE EXTENSION hstore_plpython3u CASCADE;  -- requires hstore
CREATE EXTENSION ltree_plpython3u CASCADE;   -- requires ltree
CREATE EXTENSION jsonb_plpython3u;

CREATE FUNCTION py_version() RETURNS text
LANGUAGE plpython3u
AS $$
	import sys

	with plpy.subtransaction():
		plpy.info('UPDATE tbl SET {} = {} WHERE key = {}'.format(
			plpy.quote_ident('Test Column'),
			plpy.quote_nullable(None),
			plpy.quote_literal('test value')
		))

	return sys.version
$$;

-- One function per transform: hstore and ltree values arrive as Python dicts and lists.
CREATE FUNCTION py_hstore_keys(value hstore) RETURNS integer
LANGUAGE plpython3u
TRANSFORM FOR TYPE hstore
AS $$
	return len(value)
$$;

CREATE FUNCTION py_ltree_depth(value ltree) RETURNS integer
LANGUAGE plpython3u
TRANSFORM FOR TYPE ltree
AS $$
	return len(value)
$$;

CREATE FUNCTION py_jsonb_keys(value jsonb) RETURNS integer
LANGUAGE plpython3u
TRANSFORM FOR TYPE jsonb
AS $$
	return len(value)
$$;

SELECT plan(4);
SELECT matches(py_version(), '^3\.', 'PL/Python runs Python 3');
SELECT is(py_hstore_keys('foo=>bar, baz=>NULL'::hstore), 2, 'hstore values arrive as dicts');
SELECT is(py_ltree_depth('aa.bb.cc'::ltree), 3, 'ltree values arrive as lists');
SELECT is(py_jsonb_keys('{"a": 1, "b": 2}'::jsonb), 2, 'jsonb values arrive as dicts');
SELECT * FROM finish(TRUE);
