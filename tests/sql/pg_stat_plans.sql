-- preload: pg_stat_plans
-- pg: >=16
-- https://github.com/pganalyze/pg_stat_plans
CREATE EXTENSION pg_stat_plans;

SELECT count(*) FROM pg_stat_plans;
