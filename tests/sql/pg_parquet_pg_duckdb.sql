-- image: extended
-- preload: pg_duckdb, pg_parquet
-- https://github.com/CrunchyData/pg_parquet
-- Both libraries take over COPY ... (FORMAT parquet). pg_parquet loads after pg_duckdb (see
-- image/preload-libraries.txt), so it gets the COPY first; DuckDB then reads its file. DuckDB's
-- result goes through a psql variable (see pg_duckdb.sql).
CREATE EXTENSION pg_parquet;
CREATE EXTENSION pg_duckdb;

CREATE TABLE numbers AS SELECT i AS n FROM generate_series(1, 10) AS i;
COPY numbers TO '/tmp/pwe_numbers.parquet' WITH (FORMAT parquet);
SELECT sum(r['n']::integer) AS duckdb_sum FROM read_parquet('/tmp/pwe_numbers.parquet') AS r \gset

SELECT plan(2);
SELECT matches(
    (SELECT created_by FROM parquet.file_metadata('/tmp/pwe_numbers.parquet')),
    'parquet-rs',
    'pg_parquet handles the COPY'
);
SELECT is(:'duckdb_sum', '55', 'DuckDB reads the file');
SELECT * FROM finish(TRUE);
