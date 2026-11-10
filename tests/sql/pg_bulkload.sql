-- https://github.com/ossc-db/pg_bulkload
CREATE EXTENSION pg_bulkload;
CREATE TABLE loaded (id integer PRIMARY KEY, name text NOT NULL);

CREATE TEMPORARY TABLE load_result AS
SELECT * FROM pgbulkload.pg_bulkload(ARRAY[
    'TYPE=CSV',
    'INPUT=/tests/sql/data/bulk.csv',
    'OUTPUT=public.loaded',
    'WRITER=BUFFERED',
    'LOGFILE=/tmp/pwe_bulkload.log',
    'PARSE_BADFILE=/tmp/pwe_bulkload.bad',
    'DUPLICATE_BADFILE=/tmp/pwe_bulkload.dup'
]);

SELECT plan(2);
SELECT is((SELECT load_result.count FROM load_result), 3::bigint, 'the loader reports the rows it loaded');
SELECT is(
    ARRAY(
        SELECT name FROM loaded
        ORDER BY id
    ),
    ARRAY['first', 'second', 'third'],
    'they are in the table'
);
SELECT * FROM finish(TRUE);
