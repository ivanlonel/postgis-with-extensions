-- https://github.com/postgis/h3-pg
CREATE EXTENSION h3;
CREATE EXTENSION h3_postgis CASCADE;  -- requires postgis and postgis_raster

SELECT plan(2);
SELECT is(
	h3_get_resolution(h3_lat_lng_to_cell(ST_Point(-46.629055, -23.559378), 6)),
	6,
	'points map to cells'
);
SELECT is(
	GeometryType(h3_cell_to_boundary_geometry('86a8100c7ffffff')),
	'POLYGON',
	'cells map to polygons'
);
SELECT * FROM finish(TRUE);
