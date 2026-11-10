-- https://postgis.net/docs/Extras.html#Tiger_Geocoder
CREATE EXTENSION postgis_tiger_geocoder CASCADE;  -- requires postgis and fuzzystrmatch

CREATE TEMPORARY TABLE normalized AS
SELECT * FROM normalize_address('529 Main Street, Boston MA, 02129');

SELECT plan(7);
SELECT is((SELECT address FROM normalized), 529, 'normalize_address finds the house number');
SELECT is((SELECT streetname FROM normalized), 'Main', 'normalize_address finds the street');
SELECT is((SELECT streettypeabbrev FROM normalized), 'St', 'normalize_address abbreviates the street type');
SELECT is((SELECT stateabbrev FROM normalized), 'MA', 'normalize_address finds the state');
SELECT is((SELECT zip FROM normalized), '02129', 'normalize_address finds the ZIP code');
SELECT is(
	pprint_addy(normalize_address('529 Main Street, Boston MA, 02129')),
	'529 Main St, Boston, MA 02129',
	'pprint_addy formats addresses'
);
-- Without TIGER data loaded, geocoding finds nothing, but runs through PostGIS and fuzzystrmatch.
SELECT is_empty(
	$$SELECT * FROM geocode('529 Main Street, Boston MA, 02129')$$,
	'geocode runs'
);
SELECT * FROM finish(TRUE);
