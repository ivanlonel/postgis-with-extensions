-- https://github.com/darold/pgtt
CREATE EXTENSION pgtt;
CREATE EXTENSION dblink;
LOAD 'pgtt';

CREATE GLOBAL TEMPORARY TABLE test_gtt_table (id integer, lbl text) ON COMMIT PRESERVE ROWS;
INSERT INTO test_gtt_table VALUES (1, 'one');

SELECT plan(2);
SELECT is((SELECT count(*) FROM test_gtt_table), 1::bigint, 'global temporary tables hold rows');
SELECT is(
	(
		SELECT n FROM dblink(
			format('dbname=%s', current_database()),
			$$LOAD 'pgtt'; SELECT count(*) FROM test_gtt_table$$
		) AS t (n bigint)
	),
	0::bigint,
	'other sessions see the table, empty'
);
SELECT * FROM finish(TRUE);
