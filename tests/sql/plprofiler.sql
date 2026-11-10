-- https://github.com/bigsql/plprofiler
CREATE EXTENSION plprofiler;

CREATE FUNCTION fib(n integer) RETURNS integer LANGUAGE plpgsql AS $$
BEGIN
	IF n < 2 THEN
		RETURN n;
	END IF;
	RETURN fib(n - 1) + fib(n - 2);
END
$$;

SELECT pl_profiler_set_enabled_local(TRUE);
SELECT fib(10);
SELECT pl_profiler_set_enabled_local(FALSE);

SELECT plan(2);
SELECT ok(
	(
		SELECT sum(exec_count) > 0 FROM pl_profiler_linestats_local()
		WHERE func_oid = 'fib(integer)'::regprocedure
	),
	'line statistics are collected'
);
SELECT ok(
	(SELECT count(*) > 0 FROM pl_profiler_callgraph_local()),
	'call graphs are collected'
);
SELECT * FROM finish(TRUE);
