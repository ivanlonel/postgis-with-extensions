-- https://github.com/pramsey/pgsql-ogr-fdw
CREATE EXTENSION postgis;
CREATE EXTENSION ogr_fdw;

CREATE TABLE apostles (
    fid integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    geom GEOMETRY (POINT, 4326),
    joined integer,
    name text,
    height numeric,
    born date
);

INSERT INTO apostles (name, geom, joined, height, born) VALUES
('Peter', 'SRID=4326;POINT(30.31 59.93)', 1, 1.6, '1912-01-10'),
('Andrew', 'SRID=4326;POINT(-2.8 56.34)', 2, 1.8, '1911-02-11'),
('James', 'SRID=4326;POINT(-79.23 42.1)', 3, 1.72, '1910-03-12');

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
    born date
) SERVER wraparound OPTIONS (layer 'apostles');

-- A GeoJSON file, read from disk and over HTTP (GDAL's /vsicurl/).
CREATE SERVER geojson_file FOREIGN DATA WRAPPER ogr_fdw
OPTIONS (datasource '/tests/sql/data/places.geojson', format 'GeoJSON');
CREATE SERVER geojson_http FOREIGN DATA WRAPPER ogr_fdw
OPTIONS (datasource '/vsicurl/http://127.0.0.1:8000/places.geojson', format 'GeoJSON');
CREATE FOREIGN TABLE places_file (fid bigint, geom GEOMETRY (POINT, 4326), name text, population integer)
SERVER geojson_file OPTIONS (layer 'places');
CREATE FOREIGN TABLE places_http (fid bigint, geom GEOMETRY (POINT, 4326), name text, population integer)
SERVER geojson_http OPTIONS (layer 'places');

SELECT plan(6);
SELECT is((SELECT count(*) FROM apostles_fdw), 3::bigint, 'OGR reads PostgreSQL layers');
SELECT is((
    SELECT name FROM apostles_fdw
    WHERE joined = 1
), 'Peter', 'OGR pushes filters down');
SELECT ok(
    (
        SELECT ST_Equals(geom, 'SRID=4326;POINT(30.31 59.93)') FROM apostles_fdw
        WHERE joined = 1
    ),
    'OGR reads geometries'
);
SELECT is((SELECT sum(population) FROM places_file), 17663222::bigint, 'OGR reads GeoJSON files');
SELECT is(
    (
        SELECT name FROM places_file
        WHERE ST_X(geom) < -45
    ),
    'Sao Paulo',
    'GeoJSON geometries are read'
);
SELECT is((SELECT count(*) FROM places_http), 2::bigint, 'OGR reads files over HTTP');
SELECT * FROM finish(TRUE);
