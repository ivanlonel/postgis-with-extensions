-- preload: timescaledb
-- https://github.com/timescale/timescaledb
CREATE EXTENSION timescaledb;

CREATE TABLE conditions (
	time timestamptz NOT NULL,
	location text NOT NULL,
	temperature double precision,
	humidity double precision
);

SELECT create_hypertable('conditions', 'time');

INSERT INTO conditions (time, location, temperature, humidity)
VALUES (now(), 'office', 70.0, 50.0);

-- Compression is a Timescale License feature.
ALTER TABLE conditions SET (timescaledb.compress);

SELECT plan(1);
SELECT is(
	(
		SELECT count(*)
		FROM (
			SELECT
				location,
				time_bucket('15 minutes', time) AS fifteen_min
			FROM conditions
			WHERE time > now() - interval '3 hours'
			GROUP BY fifteen_min, location
		) AS buckets
	),
	1::bigint,
	'time buckets aggregate the hypertable'
);
SELECT * FROM finish(TRUE);
