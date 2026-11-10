-- preload: pg_stat_statements, pg_stat_kcache
-- https://github.com/powa-team/pg_stat_kcache
CREATE EXTENSION pg_stat_kcache CASCADE;  -- requires pg_stat_statements

SELECT * FROM pg_stat_kcache();
