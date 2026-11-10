-- https://github.com/postgis/h3-pg
CREATE EXTENSION h3;
CREATE EXTENSION h3_postgis CASCADE;  -- requires postgis and postgis_raster

CREATE TEMPORARY TABLE cell AS
SELECT h3_lat_lng_to_cell(ST_SetSRID(ST_Point(-46.629055, -23.559378), 4326), 9) AS h3;

SELECT plan(8);
SELECT is((SELECT h3_get_resolution(h3) FROM cell), 9, 'points map to cells of the resolution asked');
SELECT ok((SELECT h3_is_valid_cell(h3) FROM cell), 'cells are valid');
SELECT is(
	(SELECT h3_lat_lng_to_cell(h3_cell_to_lat_lng(h3), 9) = h3 FROM cell),
	TRUE,
	'a cell contains its center'
);
SELECT is(
	(SELECT count(*) FROM cell, h3_cell_to_children(h3_cell_to_parent(h3, 8), 9) AS child),
	7::bigint,
	'a hexagon has seven children'
);
SELECT is(
	(SELECT count(*) FROM cell, h3_grid_disk(h3, 1) AS neighbour),
	7::bigint,
	'a hexagon has six neighbours'
);
SELECT ok((SELECT h3_cell_area(h3, 'km^2') BETWEEN 0.05 AND 0.2 FROM cell), 'cells have an area');
SELECT is(
	(SELECT GeometryType(h3_cell_to_boundary_geometry(h3)) FROM cell),
	'POLYGON',
	'cells map to polygons'
);
SELECT ok(
	(SELECT ST_Contains(h3_cell_to_boundary_geometry(h3), h3_cell_to_geometry(h3)) FROM cell),
	'cell polygons contain their centers'
);
SELECT * FROM finish(TRUE);
