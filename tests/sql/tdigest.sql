-- https://github.com/tvondra/tdigest
CREATE EXTENSION tdigest;

CREATE TABLE digests AS
SELECT tdigest(x, 100) AS digest FROM generate_series(1, 100000) AS x;

SELECT plan(3);
SELECT ok(
	(SELECT abs(tdigest_percentile(x, 100, 0.95) - 95000) < 1000 FROM generate_series(1, 100000) AS x),
	'percentiles are estimated'
);
SELECT ok(
	(SELECT abs(tdigest_percentile(digest, 0.5) - 50000) < 1000 FROM digests),
	'stored digests answer percentiles'
);
SELECT ok(
	(SELECT abs(tdigest_percentile_of(digest, 25000) - 0.25) < 0.01 FROM digests),
	'stored digests rank values'
);
SELECT * FROM finish(TRUE);
