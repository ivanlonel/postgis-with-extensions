-- https://github.com/postgis/postgis
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;
CREATE EXTENSION postgis_sfcgal;
CREATE EXTENSION postgis_topology;

SELECT PostGIS_Full_Version();

SELECT plan(4);
SELECT is(ST_Area(ST_MakeEnvelope(0, 0, 2, 2)), 4::float8, 'geometry functions work');
SELECT is(ST_Width(ST_MakeEmptyRaster(10, 20, 0, 0, 1)), 10, 'raster functions work');
SELECT isnt(postgis_sfcgal_version(), NULL, 'SFCGAL is available');
SELECT cmp_ok(topology.CreateTopology('test_topology', 4326), '>', 0, 'topologies can be created');
SELECT * FROM finish(TRUE);
