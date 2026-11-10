-- https://github.com/postgis/address_standardizer
CREATE EXTENSION address_standardizer;
CREATE EXTENSION address_standardizer_data_us;

SELECT plan(2);
SELECT is(
	(standardize_address(
		'us_lex', 'us_gaz', 'us_rules', 'One Devonshire Place, PH 301', 'Boston, MA 02109'
	)).house_num,
	'1',
	'standardize_address finds the house number'
);
SELECT is(
	(parse_address('1 Devonshire Place PH 301, Boston, MA 02109')).city,
	'Boston',
	'parse_address finds the city'
);
SELECT * FROM finish(TRUE);
