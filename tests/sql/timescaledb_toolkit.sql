-- pg: >=15
-- https://github.com/timescale/timescaledb-toolkit
CREATE EXTENSION timescaledb_toolkit;

CREATE TABLE readings AS
SELECT
	'2024-01-01'::timestamptz + i * interval '1 minute' AS ts,
	i::float8 AS value
FROM generate_series(1, 1000) AS i;

SELECT plan(5);
SELECT ok(
	(SELECT abs(approx_percentile(0.5, percentile_agg(value)) - 500) < 25 FROM readings),
	'percentiles are approximated'
);
SELECT is(
	(SELECT round(average(stats_agg(value))::numeric, 6) FROM readings),
	500.5::numeric,
	'statistical aggregates'
);
SELECT ok(
	(SELECT abs(distinct_count(hyperloglog(4096, value)) - 1000) < 100 FROM readings),
	'distinct counts are estimated'
);
SELECT is(
	(SELECT delta(counter_agg(ts, value)) FROM readings),
	999::float8,
	'counters are aggregated'
);
SELECT is(
	(SELECT round(average(time_weight('Linear', ts, value))::numeric, 6) FROM readings),
	500.5::numeric,
	'time-weighted averages'
);
SELECT * FROM finish(TRUE);
