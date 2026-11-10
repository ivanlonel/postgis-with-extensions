-- https://www.postgresql.org/docs/current/pltcl.html
CREATE EXTENSION pltcl;
CREATE EXTENSION pltclu;

CREATE FUNCTION tcl_max(integer, integer) RETURNS integer LANGUAGE pltcl STRICT AS $$
	if {$1 > $2} {return $1}
	return $2
$$;

CREATE FUNCTION tcl_query() RETURNS integer LANGUAGE pltcl AS $$
	spi_exec "SELECT 40 + 2 AS total"
	return $total
$$;

-- Untrusted Tcl can run commands.
CREATE FUNCTION tcl_echo(text) RETURNS text LANGUAGE pltclu AS $$
	return [exec echo $1]
$$;

SELECT plan(3);
SELECT is(tcl_max(1, 2), 2, 'PL/Tcl functions run');
SELECT is(tcl_query(), 42, 'PL/Tcl runs queries');
SELECT is(tcl_echo('hello'), 'hello', 'PL/TclU runs commands');
SELECT * FROM finish(TRUE);
