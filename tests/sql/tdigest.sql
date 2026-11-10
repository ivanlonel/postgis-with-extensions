-- https://github.com/tvondra/tdigest
CREATE EXTENSION tdigest;

SELECT plan(1);
SELECT ok(
	(SELECT abs(tdigest_percentile(x, 100, 0.95) - 95000) < 1000 FROM generate_series(1, 100000) AS x),
	'percentiles are estimated'
);
SELECT * FROM finish(TRUE);
