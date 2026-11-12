-- image: extended
-- preload: vectorize
-- database: cron
-- https://github.com/ChuckHend/pg_vectorize
-- pg_vectorize requires pg_cron, so it lives in pg_cron's database, where its background worker
-- connects. Embeddings come from tests/sql/lib/embeddings.py, a fake of the service its
-- sentence-transformers models call (see tests/conftest.py), which turns texts into bag-of-words
-- vectors: the row closest to a query is the one sharing the most words with it.
CREATE EXTENSION IF NOT EXISTS vectorize CASCADE;

CREATE TABLE pwe_products (
    product_id integer PRIMARY KEY,
    product_name text NOT NULL,
    description text NOT NULL,
    last_updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO pwe_products (product_id, product_name, description) VALUES
(1, 'Pencil', 'Utensil used for writing on paper'),
(2, 'Laptop stand', 'Elevated platform for laptops'),
(3, 'Phone charger', 'Cable that charges mobile phones');
SELECT vectorize.table(
    job_name => 'pwe_products',
    relation => 'pwe_products',
    primary_key => 'product_id',
    columns => ARRAY['product_name', 'description'],
    transformer => 'sentence-transformers/all-MiniLM-L6-v2',
    schedule => 'realtime'
);

SELECT plan(3);
SELECT ok(
    wait_until('SELECT count(*) = 3 FROM vectorize._embeddings_pwe_products', '120 seconds'),
    'the background worker embeds every row'
);
SELECT results_eq(
    $$
        SELECT search_results ->> 'product_name'
        FROM vectorize.search(
            job_name => 'pwe_products',
            query => 'charger for mobile phones',
            return_columns => ARRAY['product_name'],
            num_results => 1
        )
    $$,
    ARRAY['Phone charger'],
    'searches rank the closest row first'
);
INSERT INTO pwe_products (product_id, product_name, description) VALUES
(4, 'Desk lamp', 'Light for reading at a desk');
SELECT ok(
    wait_until('SELECT count(*) = 4 FROM vectorize._embeddings_pwe_products', '120 seconds'),
    'new rows get embedded too'
);
SELECT * FROM finish(TRUE);
