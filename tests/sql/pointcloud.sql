-- https://github.com/pgpointcloud/pointcloud
CREATE EXTENSION pointcloud;
CREATE EXTENSION pointcloud_postgis CASCADE;  -- requires postgis

INSERT INTO pointcloud_formats (
    pcid, srid, schema) VALUES (
    1, 4326,
    '<?xml version="1.0" encoding="UTF-8"?>
<pc:PointCloudSchema xmlns:pc="http://pointcloud.org/schemas/PC/1.1"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <pc:dimension>
        <pc:position>1</pc:position>
        <pc:size>4</pc:size>
        <pc:description>X coordinate as a long integer.</pc:description>
        <pc:name>X</pc:name>
        <pc:interpretation>int32_t</pc:interpretation>
        <pc:scale>0.01</pc:scale>
    </pc:dimension>
    <pc:dimension>
        <pc:position>2</pc:position>
        <pc:size>4</pc:size>
        <pc:description>Y coordinate as a long integer.</pc:description>
        <pc:name>Y</pc:name>
        <pc:interpretation>int32_t</pc:interpretation>
        <pc:scale>0.01</pc:scale>
    </pc:dimension>
    <pc:dimension>
        <pc:position>3</pc:position>
        <pc:size>4</pc:size>
        <pc:description>Z coordinate as a long integer.</pc:description>
        <pc:name>Z</pc:name>
        <pc:interpretation>int32_t</pc:interpretation>
        <pc:scale>0.01</pc:scale>
    </pc:dimension>
    <pc:dimension>
        <pc:position>4</pc:position>
        <pc:size>2</pc:size>
        <pc:description>The intensity value is the integer representation of the pulse return magnitude.</pc:description>
        <pc:name>Intensity</pc:name>
        <pc:interpretation>uint16_t</pc:interpretation>
        <pc:scale>1</pc:scale>
    </pc:dimension>
    <pc:metadata>
        <Metadata name="compression">dimensional</Metadata>
    </pc:metadata>
</pc:PointCloudSchema>'
);

CREATE TABLE patches AS
SELECT PC_Patch(ARRAY[
    PC_MakePoint(1, ARRAY[-126.99, 45.01, 1, 0]),
    PC_MakePoint(1, ARRAY[-126.98, 45.02, 2, 0]),
    PC_MakePoint(1, ARRAY[-126.97, 45.03, 3, 0])
]) AS pa;

SELECT plan(6);
SELECT is(
    PC_Get(PC_MakePoint(1, ARRAY[-127, 45, 124.0, 4.0]), 'Intensity'),
    4::numeric,
    'points keep their dimensions'
);
SELECT is((SELECT PC_NumPoints(pa) FROM patches), 3, 'points group into patches');
SELECT is((SELECT PC_PatchAvg(pa, 'Z') FROM patches), 2::numeric, 'patch statistics are computed');
SELECT is(
    (SELECT PC_NumPoints(PC_FilterGreaterThan(pa, 'Z', 1.5)) FROM patches),
    2,
    'patches are filtered'
);
-- pointcloud_postgis
SELECT is(
    ST_X(PC_MakePoint(1, ARRAY[-127, 45, 124.0, 4.0])::geometry),
    -127::float8,
    'points convert to geometries'
);
SELECT ok(
    (SELECT PC_Intersects(pa, ST_MakeEnvelope(-127, 45, -126, 46, 4326)) FROM patches),
    'patches intersect geometries'
);
SELECT * FROM finish(TRUE);
