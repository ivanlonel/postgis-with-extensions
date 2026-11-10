-- https://github.com/pllua/pllua
CREATE EXTENSION pllua;
CREATE EXTENSION plluau;
CREATE EXTENSION hstore_pllua CASCADE;  -- requires hstore

CREATE FUNCTION lua_add(a integer, b integer) RETURNS integer LANGUAGE pllua AS $$
    return a + b
$$;

CREATE FUNCTION lua_query() RETURNS integer LANGUAGE pllua AS $$
    return spi.execute("SELECT 40 + 2 AS total")[1].total
$$;

CREATE FUNCTION lua_hstore_get(value hstore, key text) RETURNS text LANGUAGE pllua
TRANSFORM FOR TYPE hstore
AS $$
    return value[key]
$$;

-- Untrusted Lua can reach the environment.
CREATE FUNCTION lua_getenv(name text) RETURNS text LANGUAGE plluau AS $$
    return os.getenv(name)
$$;

SELECT plan(4);
SELECT is(lua_add(1, 2), 3, 'PL/Lua functions run');
SELECT is(lua_query(), 42, 'PL/Lua runs queries');
SELECT is(lua_hstore_get('a=>1, b=>2'::hstore, 'b'), '2', 'hstore values arrive as tables');
SELECT is(lua_getenv('PGDATA'), current_setting('data_directory'), 'PL/LuaU reaches the environment');
SELECT * FROM finish(TRUE);
