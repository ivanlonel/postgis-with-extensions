-- https://github.com/okbob/plpgsql_check
CREATE EXTENSION plpgsql_check;

CREATE FUNCTION broken() RETURNS integer LANGUAGE plpgsql AS $$
BEGIN
	RETURN (SELECT missing_column FROM pg_class LIMIT 1);
END
$$;

SELECT plan(1);
SELECT ok(
	(SELECT count(*) > 0 FROM plpgsql_check_function_tb('broken()')),
	'plpgsql_check finds the missing column'
);
SELECT * FROM finish(TRUE);
