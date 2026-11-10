-- preload: pg_cron
-- database: cron
-- https://github.com/citusdata/pg_cron
CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT plan(1);
SELECT cmp_ok(cron.schedule('nightly-vacuum', '0 3 * * *', 'VACUUM'), '>', 0::bigint, 'jobs are scheduled');
SELECT cron.unschedule('nightly-vacuum');
SELECT * FROM finish(TRUE);
