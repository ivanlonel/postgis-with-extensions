-- Use, with the new image, the objects tests/upgrade/seed.sql created with the previous one.
SELECT ST_AsText(geom) FROM places;
SELECT h3_lat_lng_to_cell(geom, 6) FROM places;

SELECT (standardize_address(
	'us_lex', 'us_gaz', 'us_rules', 'One Devonshire Place, PH 301', 'Boston, MA 02109'
)).house_num;
SELECT pprint_addy(normalize_address('1 Devonshire Place, Boston, MA 02109'));

INSERT INTO readings VALUES (now(), 2.0);
SELECT count(*) FROM readings;

SELECT id FROM items
ORDER BY embedding <-> '[3,1,2]' LIMIT 1;

SELECT * FROM pgr_dijkstra(
	'SELECT 1 AS id, 1 AS source, 2 AS target, 1.0 AS cost',
	1, 2
);
