-- https://github.com/jirutka/smlar
CREATE EXTENSION smlar;

CREATE TABLE baskets (id integer PRIMARY KEY, items integer[] NOT NULL);
INSERT INTO baskets
SELECT
    i,
    ARRAY[i % 10, i % 7, i % 5]
FROM generate_series(1, 5000) AS i;
CREATE INDEX baskets_items_idx ON baskets USING gist (items _int4_sml_ops);
ANALYZE baskets;
SELECT set_config('smlar.threshold', '0.8', FALSE);
SELECT set_config('enable_seqscan', 'off', FALSE);

SELECT plan(3);
SELECT ok(
    abs(smlar('{1,2,3}'::integer[], '{2,3,4}'::integer[]) - 2 / 3.0) < 0.0001,
    'array similarity is the cosine of their sets'
);
SELECT ok(
    (
        SELECT count(*) > 0 FROM baskets
        WHERE items % '{1,2,3}'::integer[]
    ),
    'similar arrays are found'
);
SELECT matches(
    plan_of($$SELECT id FROM baskets WHERE items % '{1,2,3}'::integer[]$$),
    'baskets_items_idx',
    'similarity searches use the index'
);
SELECT * FROM finish(TRUE);
