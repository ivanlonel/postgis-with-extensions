-- image: extended
-- preload: pg_duckdb
-- https://github.com/duckdb/pg_duckdb
-- pgTAP's functions can't check DuckDB's results directly: DuckDB doesn't run inside functions
-- (duckdb.unsafe_allow_execution_inside_functions), nor queries mixing its functions with
-- PostgreSQL-only ones. So DuckDB's queries run on their own, their results go into psql variables
-- (\gset), and a plan goes through a file (\o) that the server reads back.
CREATE EXTENSION pg_duckdb;

CREATE TABLE sales AS
SELECT
    i AS id,
    i % 4 AS region,
    i AS amount
FROM generate_series(1, 1000) AS i;

SET duckdb.force_execution = TRUE;
\o /tmp/pwe_duckdb_plan.txt
EXPLAIN (COSTS OFF) SELECT region, sum(amount) FROM sales GROUP BY region;
\o
SELECT string_agg(region || ':' || total, ' ' ORDER BY region) AS duckdb_sums
FROM (SELECT region, sum(amount) AS total FROM sales GROUP BY region) AS s \gset
RESET duckdb.force_execution;

SELECT count(*) AS duckdb_csv_rows FROM read_csv('/tests/sql/data/bulk.csv', header := FALSE) \gset
SELECT duckdb.raw_query($$COPY (SELECT 42 AS answer) TO '/tmp/pwe_duckdb.parquet' (FORMAT parquet)$$);
SELECT r['answer']::integer AS duckdb_answer FROM read_parquet('/tmp/pwe_duckdb.parquet') AS r \gset

SELECT plan(4);
SELECT matches(pg_read_file('/tmp/pwe_duckdb_plan.txt'), 'DuckDB', 'DuckDB runs analytical queries');
SELECT is(:'duckdb_sums'::text, '0:125500 1:124750 2:125000 3:125250', 'DuckDB aggregates PostgreSQL tables');
SELECT is(:'duckdb_csv_rows'::text, '3', 'DuckDB reads CSV files');
SELECT is(:'duckdb_answer'::text, '42', 'DuckDB writes and reads Parquet files');
SELECT * FROM finish(TRUE);
