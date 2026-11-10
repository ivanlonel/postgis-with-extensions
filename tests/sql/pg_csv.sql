-- https://github.com/PostgREST/pg_csv
CREATE EXTENSION pg_csv;

SELECT plan(3);
SELECT matches(
	(SELECT csv_agg(x) FROM (VALUES (1, 'one'), (2, 'two')) AS x (id, name)),
	'^id,name\r?\n1,one\r?\n2,two\r?\n?$',
	'rows aggregate to CSV with a header'
);
SELECT matches(
	(SELECT csv_agg(x) FROM (VALUES (1, 'a,b'), (2, 'say "hi"')) AS x (id, name)),
	'"a,b".*"say ""hi"""',
	'fields are quoted as needed'
);
SELECT matches(
	(SELECT csv_agg(x, csv_options(delimiter => ';')) FROM (VALUES (1, 'one')) AS x (id, name)),
	'1;one',
	'delimiters are configurable'
);
SELECT * FROM finish(TRUE);
