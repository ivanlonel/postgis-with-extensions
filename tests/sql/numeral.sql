-- https://github.com/df7cb/postgresql-numeral
CREATE EXTENSION numeral;

SELECT plan(5);
SELECT is(('thirty'::numeral + 'twelve'::numeral)::text, 'forty-two', 'numerals add up');
SELECT is(('six'::numeral * 'seven'::numeral)::text, 'forty-two', 'numerals multiply');
SELECT is('forty-two'::numeral::bigint, 42::bigint, 'numerals convert to integers');
SELECT is(('XIV'::roman + 'VII'::roman)::text, 'XXI', 'roman numerals add up');
SELECT is(1984::bigint::roman::text, 'MCMLXXXIV', 'integers convert to roman numerals');
SELECT * FROM finish(TRUE);
