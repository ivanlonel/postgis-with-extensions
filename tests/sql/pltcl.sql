-- https://www.postgresql.org/docs/current/pltcl.html
CREATE EXTENSION pltcl;
CREATE EXTENSION pltclu;

CREATE FUNCTION tcl_max(integer, integer) RETURNS integer LANGUAGE pltcl STRICT AS $$
	if {$1 > $2} {return $1}
	return $2
$$;

SELECT plan(1);
SELECT is(tcl_max(1, 2), 2, 'PL/Tcl functions run');
SELECT * FROM finish(TRUE);
