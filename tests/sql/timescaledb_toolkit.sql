-- pg: >=15
-- https://github.com/timescale/timescaledb-toolkit
CREATE EXTENSION timescaledb_toolkit;

SELECT plan(1);
SELECT ok(
	(SELECT abs(approx_percentile(0.5, percentile_agg(x)) - 500) < 25 FROM generate_series(1, 1000) AS x),
	'percentiles are approximated'
);
SELECT * FROM finish(TRUE);
