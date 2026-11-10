-- https://github.com/df7cb/postgresql-numeral
CREATE EXTENSION numeral;

SELECT plan(1);
SELECT is(('thirty'::numeral + 'twelve'::numeral)::text, 'forty-two', 'numerals add up');
SELECT * FROM finish(TRUE);
