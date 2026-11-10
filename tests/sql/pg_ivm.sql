-- preload: pg_ivm
-- https://github.com/sraoss/pg_ivm
CREATE EXTENSION pg_ivm;

CREATE TABLE mytab (i integer, j integer);
INSERT INTO mytab VALUES (1, 10);
SELECT pgivm.create_immv('myview', 'SELECT i, j FROM mytab');
INSERT INTO mytab VALUES (2, 20);

SELECT plan(1);
SELECT is((SELECT count(*) FROM myview), 2::bigint, 'the view is maintained incrementally');
SELECT * FROM finish(TRUE);
