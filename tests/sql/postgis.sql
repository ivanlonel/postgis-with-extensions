-- https://github.com/postgis/postgis
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;
CREATE EXTENSION postgis_sfcgal;
CREATE EXTENSION postgis_topology;

SELECT PostGIS_Full_Version();

SELECT plan(14);

-- Geometry, GEOS and PROJ.
SELECT is(ST_Area(ST_MakeEnvelope(0, 0, 2, 2)), 4::float8, 'geometries are measured');
SELECT is(
    ST_Area(ST_Intersection(ST_MakeEnvelope(0, 0, 2, 2), ST_MakeEnvelope(1, 1, 3, 3))),
    1::float8,
    'GEOS computes overlays'
);
SELECT ok(
    ST_Equals(ST_GeomFromText('POLYGON((0 0, 2 0, 2 2, 0 2, 0 0))'), ST_MakeEnvelope(0, 0, 2, 2)),
    'WKT is parsed'
);
SELECT is(
    round(ST_X(ST_Transform(ST_SetSRID(ST_Point(180, 0), 4326), 3857))::numeric, 2),
    20037508.34,
    'PROJ transforms coordinates'
);
SELECT is(
    round(ST_Distance('POINT(0 0)'::geography, 'POINT(1 0)'::geography)),
    111319::float8,
    'geography measures on the spheroid'
);

-- Spatial indexes.
CREATE TABLE points AS
SELECT
    i AS id,
    ST_SetSRID(ST_Point(i % 100, i / 100), 4326) AS geom
FROM generate_series(0, 9999) AS i;
CREATE INDEX points_geom_idx ON points USING gist (geom);
ANALYZE points;
SELECT is(
    (
        SELECT count(*) FROM points
        WHERE ST_Intersects(geom, ST_MakeEnvelope(10, 10, 12, 12, 4326))
    ),
    9::bigint,
    'spatial queries find what they look for'
);
SELECT matches(
    plan_of('SELECT * FROM points WHERE ST_Intersects(geom, ST_MakeEnvelope(10, 10, 12, 12, 4326))'),
    'points_geom_idx',
    'spatial queries use the GiST index'
);

-- Raster, and GDAL behind it.
SELECT set_config('postgis.gdal_enabled_drivers', 'GTiff', FALSE);
CREATE TABLE rasters AS
SELECT
    ST_SetValue(
        ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1, -1, 0, 0, 4326), '8BUI'::text, 0), 1, 3, 4, 42
    ) AS rast;
SELECT is((SELECT ST_Value(rast, 1, 3, 4) FROM rasters), 42::float8, 'raster cells hold values');
SELECT is(
    (SELECT (ST_SummaryStats(rast)).max FROM rasters),
    42::float8,
    'raster statistics are computed'
);
SELECT is(
    (SELECT ST_Value(ST_FromGDALRaster(ST_AsGDALRaster(rast, 'GTiff')), 1, 3, 4) FROM rasters),
    42::float8,
    'rasters round-trip through GDAL'
);

-- SFCGAL.
SELECT isnt(postgis_sfcgal_version(), NULL, 'SFCGAL is available');
SELECT is(
    ST_GeometryType(CG_Extrude(ST_MakeEnvelope(0, 0, 1, 1), 0, 0, 1)),
    'ST_PolyhedralSurface',
    'SFCGAL extrudes polygons'
);

-- Topology.
SELECT topology.CreateTopology('test_topology', 4326);
SELECT topology.TopoGeo_AddLineString('test_topology', ST_GeomFromText('LINESTRING(0 0, 1 0, 1 1)', 4326));
SELECT topology.TopoGeo_AddLineString('test_topology', ST_GeomFromText('LINESTRING(1 1, 0 1, 0 0)', 4326));
SELECT is((
    SELECT count(*) FROM test_topology.face
    WHERE face_id > 0
), 1::bigint, 'topologies build faces');
SELECT is_empty(
    $$SELECT * FROM topology.ValidateTopology('test_topology')$$,
    'topologies are valid'
);
SELECT * FROM finish(TRUE);
