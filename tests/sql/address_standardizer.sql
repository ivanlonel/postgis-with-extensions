-- https://github.com/postgis/address_standardizer
CREATE EXTENSION address_standardizer;
CREATE EXTENSION address_standardizer_data_us;

CREATE TEMPORARY TABLE standardized AS
SELECT * FROM standardize_address(
	'us_lex', 'us_gaz', 'us_rules', 'One Devonshire Place, PH 301', 'Boston, MA 02109'
);
CREATE TEMPORARY TABLE parsed AS
SELECT * FROM parse_address('1 Devonshire Place, Boston, MA 02109-1234');

SELECT plan(8);
SELECT is((SELECT house_num FROM standardized), '1', 'standardize_address finds the house number');
SELECT is((SELECT name FROM standardized), 'DEVONSHIRE', 'standardize_address finds the street name');
SELECT is((SELECT suftype FROM standardized), 'PLACE', 'standardize_address finds the street type');
SELECT is((SELECT city FROM standardized), 'BOSTON', 'standardize_address finds the city');
SELECT is((SELECT postcode FROM standardized), '02109', 'standardize_address finds the postcode');
SELECT is((SELECT street FROM parsed), 'Devonshire Place', 'parse_address finds the street');
SELECT is((SELECT city FROM parsed), 'Boston', 'parse_address finds the city');
SELECT is((SELECT zipplus FROM parsed), '1234', 'parse_address finds the ZIP+4 extension');
SELECT * FROM finish(TRUE);
