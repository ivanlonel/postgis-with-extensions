-- https://github.com/theory/pgtap
-- The test runner creates pgTAP in every scratch database; these check pgTAP itself.
CREATE TABLE widgets (id integer PRIMARY KEY, name text NOT NULL);
INSERT INTO widgets VALUES (1, 'a'), (2, 'b');

SELECT plan(6);
SELECT has_extension('pgtap', 'pgTAP is installed');
SELECT has_table('widgets', 'schema assertions');
SELECT col_not_null('widgets', 'name', 'column assertions');
SELECT results_eq('SELECT id FROM widgets ORDER BY id', ARRAY[1, 2], 'result assertions');
SELECT throws_ok('INSERT INTO widgets VALUES (1, ''c'')', '23505', NULL, 'error assertions');
SELECT bag_eq('SELECT name FROM widgets', $$VALUES ('b'), ('a')$$, 'unordered result assertions');
SELECT * FROM finish(TRUE);
