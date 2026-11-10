-- preload: pglogical, pglogical_ticker
-- pg: <=17
-- https://salsa.debian.org/postgresql/pg-fact-loader
CREATE EXTENSION pg_fact_loader CASCADE;

SELECT plan(3);
SELECT is(fact_loader.worker(), FALSE, 'the worker runs, with nothing to load yet');
SELECT is_empty('SELECT * FROM fact_loader.subscription()', 'no pglogical subscription is set up');
SELECT has_table('fact_loader', 'fact_tables', 'fact tables are configured in the catalog');
SELECT * FROM finish(TRUE);
