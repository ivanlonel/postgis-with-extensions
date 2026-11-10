-- https://github.com/theirix/parray_gin
CREATE EXTENSION parray_gin;

CREATE TABLE parray_gin_test_table (id integer GENERATED ALWAYS AS IDENTITY, val text[]);
CREATE INDEX test_val_idx ON parray_gin_test_table USING gin (val parray_gin_ops);
INSERT INTO parray_gin_test_table (val) VALUES (ARRAY['postgres', 'postgis']);

SELECT plan(1);
SELECT is(
	-- sqlfluff can't parse parray_gin's @@> (partial match) operator, nor lay out what follows.
	(SELECT count(*) FROM parray_gin_test_table WHERE val @@> ARRAY['post']),  -- noqa: PRS, LT14
	1::bigint,
	'partial matches'
);
SELECT * FROM finish(TRUE);
