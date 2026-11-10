-- preload: pg_cron
-- database: cron
-- pg: >=16
-- https://github.com/CrunchyData/pg_incremental
-- Pipelines are pg_cron jobs, in pg_cron's database, where pg_cron's extension must exist (the
-- control file doesn't require it). Created, a pipeline first processes the rows already there.
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_incremental;

CREATE TABLE pwe_events (event_id bigserial PRIMARY KEY, kind text NOT NULL);
INSERT INTO pwe_events (kind)
SELECT CASE WHEN i % 3 = 0 THEN 'click' ELSE 'view' END
FROM generate_series(1, 300) AS i;
CREATE TABLE pwe_event_counts (kind text PRIMARY KEY, total bigint NOT NULL);

-- $1 and $2 bound the range of sequence values to aggregate.
SELECT incremental.create_sequence_pipeline('pwe-counts', 'pwe_events', $$
    INSERT INTO pwe_event_counts
    SELECT kind, count(*) FROM pwe_events
    WHERE event_id BETWEEN $1 AND $2
    GROUP BY kind
    ON CONFLICT (kind) DO UPDATE SET total = pwe_event_counts.total + excluded.total
$$);

SELECT plan(1);
SELECT is(
    ARRAY(
        SELECT total FROM pwe_event_counts
        ORDER BY kind
    ),
    ARRAY[100, 200]::bigint[],
    'the pipeline aggregates the existing rows'
);

SELECT incremental.drop_pipeline('pwe-counts');
DROP TABLE pwe_event_counts, pwe_events;
SELECT * FROM finish(TRUE);
