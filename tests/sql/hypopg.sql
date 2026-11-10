-- https://github.com/HypoPG/hypopg
CREATE EXTENSION hypopg;

CREATE TABLE hypo AS SELECT
    id,
    'line ' || id AS val
FROM generate_series(1, 10000) AS id;
ANALYZE hypo;

SELECT * FROM hypopg_create_index('CREATE INDEX ON hypo (id)');

SELECT plan(4);
SELECT is((SELECT count(*) FROM hypopg_list_indexes), 1::bigint, 'hypothetical indexes are listed');
SELECT matches(
    plan_of('SELECT * FROM hypo WHERE id = 1'), 'btree_hypo_id', 'the planner uses the hypothetical index'
);
SELECT is(
    (
        SELECT count(*) FROM pg_indexes
        WHERE tablename = 'hypo'
    ),
    0::bigint,
    'hypothetical indexes are not built'
);
SELECT hypopg_reset();
SELECT doesnt_match(
    plan_of('SELECT * FROM hypo WHERE id = 1'), 'btree_hypo_id', 'hypothetical indexes are dropped'
);
SELECT * FROM finish(TRUE);
