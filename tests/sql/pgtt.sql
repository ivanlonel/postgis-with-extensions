-- https://github.com/darold/pgtt
CREATE EXTENSION pgtt;
LOAD 'pgtt';

CREATE GLOBAL TEMPORARY TABLE test_gtt_table (id integer, lbl text) ON COMMIT PRESERVE ROWS;
INSERT INTO test_gtt_table VALUES (1, 'one');

SELECT plan(1);
SELECT is((SELECT count(*) FROM test_gtt_table), 1::bigint, 'global temporary tables hold rows');
SELECT * FROM finish(TRUE);
