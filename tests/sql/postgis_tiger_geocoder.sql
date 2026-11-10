-- https://postgis.net/docs/Extras.html#Tiger_Geocoder
CREATE EXTENSION postgis_tiger_geocoder CASCADE;  -- requires postgis and fuzzystrmatch

SELECT plan(1);
SELECT is(
	(normalize_address('1 Devonshire Place, Boston, MA 02109')).zip,
	'02109',
	'normalize_address finds the ZIP code'
);
SELECT * FROM finish(TRUE);
