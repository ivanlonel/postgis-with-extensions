-- preload: pg_stat_log
-- pg: >=18
-- https://github.com/fabriziomello/pg_stat_log
CREATE EXTENSION pg_stat_log;

-- Only messages that reach the log count: a warning does, an error caught by pgTAP wouldn't.
DO $$
BEGIN
    RAISE WARNING 'pwe warning' USING ERRCODE = '01P01';
END
$$;

SELECT plan(1);
SELECT cmp_ok(
    (
        SELECT sum(count) FROM pg_stat_log
        WHERE database_name = current_database() AND elevel = 'WARNING' AND sqlerrcode = '01P01'
    ),
    '>=',
    1::numeric,
    'logged messages are counted by level and SQLSTATE'
);
SELECT * FROM finish(TRUE);
