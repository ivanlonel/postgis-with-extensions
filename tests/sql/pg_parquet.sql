-- image: extended
-- preload: pg_parquet
-- https://github.com/CrunchyData/pg_parquet
CREATE EXTENSION pg_parquet;

CREATE TABLE products AS
SELECT
    i AS id,
    'product ' || i AS name,
    i * 1.5::float8 AS price
FROM generate_series(1, 100) AS i;
COPY products TO '/tmp/pwe_products.parquet' WITH (FORMAT parquet);
CREATE TABLE copied (LIKE products);
COPY copied FROM '/tmp/pwe_products.parquet' WITH (FORMAT parquet);

SELECT plan(4);
SELECT results_eq(
    'SELECT * FROM copied ORDER BY id',
    'SELECT * FROM products ORDER BY id',
    'rows survive a round trip through Parquet'
);
SELECT is(
    (SELECT num_rows FROM parquet.file_metadata('/tmp/pwe_products.parquet')),
    100::bigint,
    'the file metadata counts the rows'
);
SELECT set_eq(
    $$SELECT name FROM parquet.schema('/tmp/pwe_products.parquet') WHERE num_children IS NULL$$,
    ARRAY['id', 'name', 'price'],
    'the file schema has the columns'
);
SELECT matches(
    (SELECT created_by FROM parquet.file_metadata('/tmp/pwe_products.parquet')),
    '^pg_parquet',
    'pg_parquet writes the file'
);
SELECT * FROM finish(TRUE);
