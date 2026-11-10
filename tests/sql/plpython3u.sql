-- https://www.postgresql.org/docs/current/plpython.html
CREATE EXTENSION plpython3u;
CREATE EXTENSION hstore_plpython3u CASCADE;  -- requires hstore
CREATE EXTENSION ltree_plpython3u CASCADE;   -- requires ltree
CREATE EXTENSION jsonb_plpython3u;

CREATE FUNCTION py_version() RETURNS text
LANGUAGE plpython3u
AS $$
    import sys
    return sys.version
$$;

CREATE FUNCTION py_query() RETURNS integer
LANGUAGE plpython3u
AS $$
    plan = plpy.prepare("SELECT $1 + $2 AS total", ["integer", "integer"])
    with plpy.subtransaction():
        return plpy.execute(plan, [40, 2])[0]["total"]
$$;

CREATE FUNCTION py_series(n integer) RETURNS SETOF integer
LANGUAGE plpython3u
AS $$
    return range(n)
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

-- Untrusted Python can use the standard library.
CREATE FUNCTION py_sha256(value text) RETURNS text
LANGUAGE plpython3u
AS $$
    import hashlib
    return hashlib.sha256(value.encode()).hexdigest()
$$;

SELECT plan(7);
SELECT matches(py_version(), '^3\.', 'PL/Python runs Python 3');
SELECT is(py_query(), 42, 'PL/Python runs prepared queries');
SELECT is((SELECT count(*) FROM py_series(5)), 5::bigint, 'PL/Python returns sets');
SELECT is(py_hstore_keys('foo=>bar, baz=>NULL'::hstore), 2, 'hstore values arrive as dicts');
SELECT is(py_ltree_depth('aa.bb.cc'::ltree), 3, 'ltree values arrive as lists');
SELECT is(py_jsonb_keys('{"a": 1, "b": 2}'::jsonb), 2, 'jsonb values arrive as dicts');
SELECT is(py_sha256('abc'), encode(sha256('abc'), 'hex'), 'PL/Python imports modules');
SELECT * FROM finish(TRUE);
