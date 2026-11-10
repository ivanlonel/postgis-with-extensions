-- preload: pg_stat_statements, pg_stat_kcache
-- https://github.com/powa-team/pg_stat_kcache
CREATE EXTENSION pg_stat_kcache CASCADE;  -- requires pg_stat_statements

SELECT sum(i) FROM generate_series(1, 2000000) AS i;

SELECT plan(2);
SELECT ok((SELECT count(*) > 0 FROM pg_stat_kcache()), 'statements get kernel statistics');
SELECT ok((SELECT sum(exec_user_time) > 0 FROM pg_stat_kcache()), 'CPU time is measured');
SELECT * FROM finish(TRUE);
