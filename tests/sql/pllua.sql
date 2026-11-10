-- https://github.com/pllua/pllua
CREATE EXTENSION pllua;
CREATE EXTENSION plluau;
CREATE EXTENSION hstore_pllua CASCADE;  -- requires hstore

CREATE FUNCTION lua_add(a integer, b integer) RETURNS integer LANGUAGE pllua AS $$
	return a + b
$$;

SELECT plan(1);
SELECT is(lua_add(1, 2), 3, 'PL/Lua functions run');
SELECT * FROM finish(TRUE);
