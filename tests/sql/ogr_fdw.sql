-- https://github.com/pramsey/pgsql-ogr-fdw
CREATE EXTENSION postgis;
CREATE EXTENSION ogr_fdw;

CREATE TABLE apostles (
	fid integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	geom GEOMETRY (POINT, 4326),
	joined integer,
	name text,
	height numeric,
	born date,
	clock time,
	ts timestamp
);

INSERT INTO apostles (name, geom, joined, height, born, clock, ts) VALUES
('Peter', 'SRID=4326;POINT(30.31 59.93)', 1, 1.6, '1912-01-10', '10:10:01', '1912-01-10 10:10:01'),
('Andrew', 'SRID=4326;POINT(-2.8 56.34)', 2, 1.8, '1911-02-11', '10:10:02', '1911-02-11 10:10:02'),
('James', 'SRID=4326;POINT(-79.23 42.1)', 3, 1.72, '1910-03-12', '10:10:03', '1910-03-12 10:10:03'),
('John', 'SRID=4326;POINT(13.2 47.35)', 4, 1.45, '1909-04-01', '10:10:04', '1909-04-01 10:10:04'),
('Philip', 'SRID=4326;POINT(-75.19 40.69)', 5, 1.65, '1908-05-02', '10:10:05', '1908-05-02 10:10:05'),
('Bartholomew', 'SRID=4326;POINT(-62 18)', 6, 1.69, '1907-06-03', '10:10:06', '1907-06-03 10:10:06'),
('Thomas', 'SRID=4326;POINT(-80.08 35.88)', 7, 1.68, '1906-07-04', '10:10:07', '1906-07-04 10:10:07'),
('Matthew', 'SRID=4326;POINT(-73.67 20.94)', 8, 1.65, '1905-08-05', '10:10:08', '1905-08-05 10:10:08'),
('James Alpheus', 'SRID=4326;POINT(-84.29 34.07)', 9, 1.78, '1904-09-06', '10:10:09', '1904-09-06 10:10:09'),
('Thaddaeus', 'SRID=4326;POINT(79.13 10.78)', 10, 1.88, '1903-10-07', '10:10:10', '1903-10-07 10:10:10'),
('Simon', 'SRID=4326;POINT(-85.97 41.75)', 11, 1.61, '1902-11-08', '10:10:11', '1902-11-08 10:10:11'),
('Judas Iscariot', 'SRID=4326;POINT(35.7 32.4)', 12, 1.71, '1901-12-09', '10:10:12', '1901-12-09 10:10:12');

-- Read the table back through OGR's PostgreSQL driver.
DO $$
BEGIN
	EXECUTE format(
		'CREATE SERVER wraparound FOREIGN DATA WRAPPER ogr_fdw OPTIONS (datasource %L, format %L)',
		format('Pg:dbname=%s user=postgres', current_database()),
		'PostgreSQL'
	);
END
$$;

CREATE FOREIGN TABLE apostles_fdw (
	fid integer,
	geom GEOMETRY (POINT, 4326),
	joined integer,
	name text,
	height numeric,
	born date,
	clock time,
	ts timestamp
) SERVER wraparound OPTIONS (layer 'apostles');

SELECT plan(1);
SELECT is((SELECT count(*) FROM apostles_fdw), 12::bigint, 'OGR reads the layer');
SELECT * FROM finish(TRUE);
