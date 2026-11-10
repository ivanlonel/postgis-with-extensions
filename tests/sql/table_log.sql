-- https://github.com/credativ/table_log
CREATE EXTENSION table_log;

CREATE TABLE public.drop_test (
	id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	col1 text NOT NULL DEFAULT '',
	col2 text NOT NULL DEFAULT '',
	col3 text NOT NULL DEFAULT ''
);

-- Level 5: log old and new rows, with a sequence-numbered id and the user.
SELECT table_log_init(5, 'public', 'drop_test', 'public', 'drop_test_log');

INSERT INTO drop_test (col1, col2, col3) VALUES ('a1', 'b1', 'c1');

-- Columns can be dropped from both tables; logging carries on.
ALTER TABLE drop_test DROP COLUMN col2;
ALTER TABLE drop_test_log DROP COLUMN col2;

INSERT INTO drop_test (col1, col3) VALUES ('a2', 'c2');
UPDATE drop_test SET col1 = 'a1 updated'
WHERE col1 = 'a1';
DELETE FROM drop_test
WHERE col1 = 'a2';

SELECT plan(3);
SELECT is((SELECT count(*) FROM drop_test_log), 5::bigint, 'every change is logged');
SELECT is(
	(
		SELECT count(*) FROM drop_test_log
		WHERE trigger_mode = 'UPDATE'
	),
	2::bigint,
	'updates log the old and the new row'
);
SELECT is(
	(
		SELECT col1 FROM drop_test_log
		WHERE trigger_mode = 'DELETE'
	),
	'a2',
	'deletions keep the deleted values'
);
SELECT * FROM finish(TRUE);
