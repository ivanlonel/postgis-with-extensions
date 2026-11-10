-- https://github.com/df7cb/postgresql-numeral
CREATE EXTENSION numeral;

SELECT plan(4);
SELECT is(('thirty'::numeral + 'twelve'::numeral)::text, 'forty-two', 'numerals add up');
SELECT is('forty-two'::numeral::integer, 42, 'numerals convert to integers');
SELECT is(('XIV'::roman + 'VII'::roman)::text, 'XXI', 'roman numerals add up');
SELECT is(1984::roman::text, 'MCMLXXXIV', 'integers convert to roman numerals');
SELECT * FROM finish(TRUE);
