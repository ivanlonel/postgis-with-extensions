-- https://github.com/credativ/table_log
CREATE EXTENSION table_log;

CREATE TABLE public.drop_test (
	id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	col1 text NOT NULL DEFAULT '',
	col2 text NOT NULL DEFAULT '',
	col3 text NOT NULL DEFAULT ''
);

SELECT table_log_init(5, 'public', 'drop_test', 'public', 'drop_test_log');

INSERT INTO drop_test (col1, col2, col3) VALUES ('a1', 'b1', 'c1');

ALTER TABLE drop_test DROP COLUMN col2;
ALTER TABLE drop_test_log DROP COLUMN col2;

INSERT INTO drop_test (col1, col3) VALUES ('a2', 'c2');

SELECT plan(1);
SELECT is((SELECT count(*) FROM drop_test_log), 2::bigint, 'changes are logged');
SELECT * FROM finish(TRUE);
