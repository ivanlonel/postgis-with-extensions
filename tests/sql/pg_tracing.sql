-- preload: pg_tracing
-- https://github.com/DataDog/pg_tracing
CREATE EXTENSION pg_tracing;

-- Trace every statement of this session.
SELECT set_config('pg_tracing.sample_rate', '1.0', FALSE);
SELECT count(*) FROM pg_class;

SELECT plan(1);
SELECT ok((SELECT count(*) > 0 FROM pg_tracing_consume_spans), 'statements are traced as spans');
SELECT * FROM finish(TRUE);
