-- preload: timescaledb
-- https://github.com/timescale/timescaledb
CREATE EXTENSION timescaledb;

CREATE TABLE conditions (
	time timestamptz NOT NULL,
	location text NOT NULL,
	temperature double precision,
	humidity double precision
);
SELECT create_hypertable('conditions', 'time', chunk_time_interval => interval '1 day');

-- Three days of readings every minute, from two places.
INSERT INTO conditions (time, location, temperature, humidity)
SELECT
	t,
	place,
	20 + 5 * sin(extract(EPOCH FROM t) / 3600),
	50
FROM generate_series('2024-01-01 00:00+00'::timestamptz, '2024-01-03 23:59+00', interval '1 minute') AS t,
	unnest(ARRAY['office', 'garage']) AS place;

-- Compression (columnstore) and continuous aggregates are Timescale License features.
ALTER TABLE conditions SET (timescaledb.compress, timescaledb.compress_segmentby = 'location');
SELECT compress_chunk(c) FROM show_chunks('conditions') AS c;

CREATE MATERIALIZED VIEW conditions_hourly WITH (timescaledb.continuous) AS
SELECT
	location,
	time_bucket(interval '1 hour', time) AS bucket,
	avg(temperature) AS avg_temperature
FROM conditions
GROUP BY bucket, location
WITH NO DATA;
CALL refresh_continuous_aggregate('conditions_hourly', NULL, NULL);

-- Policies are jobs; run one by hand, dropping readings over a year old.
CREATE TABLE old_readings (time timestamptz NOT NULL, reading integer);
SELECT create_hypertable('old_readings', 'time', chunk_time_interval => interval '1 day');
INSERT INTO old_readings VALUES ('2020-01-01 12:00+00', 1), ('2020-01-05 12:00+00', 2);
CREATE TEMPORARY TABLE jobs AS
SELECT add_retention_policy('old_readings', drop_after => interval '1 year') AS retention;
-- (CALL takes no subquery argument.)
DO $$
DECLARE
	job integer;
BEGIN
	SELECT retention INTO job FROM jobs;
	CALL run_job(job);
END
$$;

-- And have the scheduler run a job of our own.
CREATE TABLE ticks (at timestamptz NOT NULL DEFAULT now());
CREATE PROCEDURE tick(job_id integer, config jsonb) LANGUAGE plpgsql AS $$
BEGIN
	INSERT INTO ticks DEFAULT VALUES;
END
$$;
INSERT INTO jobs (retention) SELECT add_job('tick', interval '1 second');

SELECT plan(7);
SELECT is((SELECT count(*) FROM show_chunks('conditions')), 3::bigint, 'rows are split into chunks');
SELECT is((SELECT count(*) FROM conditions), 8640::bigint, 'compressed chunks are queried');
SELECT ok(
	(
		SELECT bool_and(is_compressed) FROM timescaledb_information.chunks
		WHERE hypertable_name = 'conditions'
	),
	'chunks are compressed'
);
SELECT is((SELECT count(*) FROM conditions_hourly), 144::bigint, 'continuous aggregates are refreshed');
SELECT is(
	(
		SELECT count(*) FROM conditions
		WHERE location = 'office' AND time >= '2024-01-02' AND time < '2024-01-03'
	),
	1440::bigint,
	'compressed rows are filtered'
);
SELECT is((SELECT count(*) FROM show_chunks('old_readings')), 0::bigint, 'retention policies drop old chunks');
SELECT ok(wait_until('SELECT count(*) > 0 FROM ticks'), 'the job scheduler runs jobs');
SELECT * FROM finish(TRUE);

SELECT delete_job(max(retention)) FROM jobs;
