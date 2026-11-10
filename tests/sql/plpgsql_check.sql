-- https://github.com/okbob/plpgsql_check
CREATE EXTENSION plpgsql_check;

CREATE FUNCTION broken() RETURNS integer LANGUAGE plpgsql AS $$
BEGIN
    RETURN (SELECT missing_column FROM pg_class LIMIT 1);
END
$$;

CREATE FUNCTION fine() RETURNS integer LANGUAGE plpgsql AS $$
BEGIN
    RETURN (SELECT count(*)::integer FROM pg_class);
END
$$;

CREATE FUNCTION unused_variable() RETURNS integer LANGUAGE plpgsql AS $$
DECLARE
    unused integer;
BEGIN
    RETURN 1;
END
$$;

SELECT plan(3);
SELECT is(
    (SELECT sqlstate FROM plpgsql_check_function_tb('broken()') LIMIT 1),
    '42703',
    'plpgsql_check finds the missing column'
);
SELECT is((SELECT count(*) FROM plpgsql_check_function_tb('fine()')), 0::bigint, 'valid code passes');
SELECT ok(
    (SELECT count(*) > 0 FROM plpgsql_check_function_tb('unused_variable()', extra_warnings => TRUE)),
    'unused variables are reported'
);
SELECT * FROM finish(TRUE);
