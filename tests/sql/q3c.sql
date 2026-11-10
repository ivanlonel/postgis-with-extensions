-- https://github.com/segasai/q3c
CREATE EXTENSION q3c;

CREATE TABLE objects (id integer PRIMARY KEY, ra double precision, declination double precision);
INSERT INTO objects
SELECT
	i,
	(i % 360)::float8,
	((i / 360) - 45)::float8
FROM generate_series(0, 32399) AS i;
CREATE INDEX objects_q3c_idx ON objects (q3c_ang2ipix(ra, declination));
ANALYZE objects;

SELECT plan(4);
SELECT is(round(q3c_dist(0, 0, 0, 1)::numeric, 6), 1.000000, 'angular distances are computed');
SELECT is(
	(
		SELECT count(*) FROM objects
		WHERE q3c_radial_query(ra, declination, 10, 0, 1.5)
	),
	9::bigint,
	'cone searches find the objects'
);
SELECT matches(
	plan_of('SELECT * FROM objects WHERE q3c_radial_query(ra, declination, 10, 0, 1.5)'),
	'objects_q3c_idx',
	'cone searches use the index'
);
SELECT is(
	(
		SELECT count(*)
		FROM objects AS a
		INNER JOIN objects AS b ON q3c_join(a.ra, a.declination, b.ra, b.declination, 0.1)
		WHERE a.id < 100
	),
	100::bigint,
	'positional joins match each object with itself'
);
SELECT * FROM finish(TRUE);
