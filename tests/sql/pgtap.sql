-- https://github.com/theory/pgtap
-- The test runner creates pgTAP in every scratch database.
SELECT plan(1);
SELECT has_extension('pgtap', 'pgTAP is installed');
SELECT * FROM finish(TRUE);
