-- preload: pglogical, pglogical_ticker
-- pg: <=17
-- https://github.com/enova/pglogical_ticker
CREATE EXTENSION pglogical_ticker CASCADE;  -- requires pglogical

SELECT pglogical_ticker.deploy_ticker_tables();
