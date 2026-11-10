-- preload: pglogical, pglogical_ticker
-- pg: <=17
-- https://salsa.debian.org/postgresql/pg-fact-loader
CREATE EXTENSION pg_fact_loader CASCADE;

SELECT fact_loader.worker();
SELECT * FROM fact_loader.subscription();
SELECT * FROM fact_loader.subscription_rel();
