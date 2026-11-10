-- https://github.com/MobilityDB/MobilityDB
CREATE EXTENSION mobilitydb CASCADE;  -- requires postgis
CREATE EXTENSION mobilitydb_datagen;
CREATE EXTENSION dblink;

-- MobilityDB 1.3.0 builds its operator cache, in the session that creates the extension, before
-- filling the table it reads it from: there, operators like && fail with "Unknown MEOS operator"
-- (fixed upstream after 1.3.0). Other sessions are fine, so operator queries go through dblink.
CREATE FUNCTION in_new_session(query text) RETURNS bigint LANGUAGE sql AS $$
	SELECT n FROM dblink(format('dbname=%s', current_database()), query) AS t (n bigint)
$$;

-- A point moving 2 units east over two days, and a temperature rising alongside.
CREATE TABLE trips (id integer PRIMARY KEY, trip tgeompoint, temperature tfloat);
INSERT INTO trips VALUES (
	1,
	tgeompoint '[Point(0 0)@2000-01-01, Point(2 0)@2000-01-03]',
	tfloat '[10@2000-01-01, 30@2000-01-03]'
), (
	2,
	tgeompoint '[Point(50 50)@2000-01-01, Point(51 50)@2000-01-02]',
	tfloat '[0@2000-01-01, 1@2000-01-02]'
);
CREATE INDEX trips_trip_idx ON trips USING gist (trip);

SELECT plan(12);
SELECT is((
	SELECT numInstants(trip) FROM trips
	WHERE id = 1
), 2, 'temporal points keep their instants');
SELECT is((
	SELECT length(trip) FROM trips
	WHERE id = 1
), 2::float8, 'trajectories are measured');
SELECT is(
	(
		SELECT ST_AsText(valueAtTimestamp(trip, '2000-01-02')) FROM trips
		WHERE id = 1
	),
	'POINT(1 0)',
	'positions are interpolated'
);
SELECT is(
	(
		SELECT ST_AsText(trajectory(trip)) FROM trips
		WHERE id = 1
	),
	'LINESTRING(0 0,2 0)',
	'trajectories are built'
);
SELECT is(
	(
		SELECT valueAtTimestamp(temperature, '2000-01-02') FROM trips
		WHERE id = 1
	),
	20::float8,
	'temporal floats are interpolated'
);
SELECT is(
	(
		SELECT duration(trip) FROM trips
		WHERE id = 1
	),
	'2 days'::interval,
	'temporal values have a duration'
);
SELECT is(
	in_new_session($$SELECT count(*) FROM trips WHERE trip && stbox 'STBOX X((-1, -1), (1, 1))'$$),
	1::bigint,
	'temporal points are found by bounding box'
);
SELECT is(
	in_new_session('SELECT count(*) FROM trips WHERE eIntersects(trip, ST_MakeEnvelope(-1, -1, 1, 1))'),
	1::bigint,
	'spatial relationships are evaluated over time'
);
SELECT is(
	(
		SELECT ST_AsText(startValue(trip)) FROM trips
		WHERE id = 1
	),
	'POINT(0 0)',
	'temporal values start where they start'
);
SELECT is(
	(
		SELECT endTimestamp(trip) FROM trips
		WHERE id = 1
	),
	'2000-01-03'::timestamptz,
	'temporal values end when they end'
);
SELECT is(
	(
		SELECT twAvg(temperature) FROM trips
		WHERE id = 1
	),
	20::float8,
	'time-weighted averages are computed'
);
SELECT ok(
	(SELECT bool_and(random_int(1, 10) BETWEEN 1 AND 10) FROM generate_series(1, 100)),
	'the data generator stays within bounds'
);
SELECT * FROM finish(TRUE);
