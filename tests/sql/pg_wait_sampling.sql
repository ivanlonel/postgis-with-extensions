-- preload: pg_wait_sampling
-- https://github.com/postgrespro/pg_wait_sampling
CREATE EXTENSION pg_wait_sampling;

WITH t AS (SELECT sum(0) FROM pg_wait_sampling_current)

SELECT sum(0) FROM generate_series(1, 2), t;
