-- preload: plprofiler
-- conflicts: plugin_debugger
-- https://github.com/bigsql/plprofiler
-- PL/pgSQL takes one instrumentation plugin: when pldebugger loads after plprofiler, as in the
-- legacy and all presets, it takes the slot and plprofiler sees nothing.
-- plprofiler decides whether to profile at the first PL/pgSQL call of each transaction (when
-- preloaded), and drops the local statistics when an unprofiled call runs: profile and check in
-- one transaction.
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

BEGIN;
SELECT fib(10);
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
COMMIT;

SELECT pl_profiler_set_enabled_local(FALSE);
