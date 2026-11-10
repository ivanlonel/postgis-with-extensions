-- https://github.com/begriffs/pg_rational
CREATE EXTENSION pg_rational;

-- Rationals are meant for user-defined ordering: insert between two items without renumbering.
CREATE TABLE todos (title text, position rational);
INSERT INTO todos VALUES ('first', '1/2'), ('last', '2/3');
INSERT INTO todos VALUES ('middle', rational_intermediate('1/2', '2/3'));

SELECT plan(4);
SELECT is((0.263157894737::float::rational)::text, '5/19', 'floats convert to fractions');
SELECT is(('1/3'::rational + '1/6'::rational)::text, '1/2', 'fractions add up and simplify');
SELECT is(rational_intermediate('1/2', '2/3')::text, '3/5', 'the simplest fraction in between is found');
SELECT is(
	(SELECT string_agg(title, ',' ORDER BY position) FROM todos),
	'first,middle,last',
	'fractions order rows'
);
SELECT * FROM finish(TRUE);
