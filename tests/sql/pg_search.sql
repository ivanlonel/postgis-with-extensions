-- image: extended
-- preload: pg_search
-- pg: >=15
-- https://github.com/paradedb/paradedb
CREATE EXTENSION pg_search CASCADE;  -- requires vector

CREATE TABLE items (id integer PRIMARY KEY, description text NOT NULL);
INSERT INTO items VALUES
(1, 'Ergonomic metal keyboard'),
(2, 'Plastic keyboard'),
(3, 'Sleek running shoes'),
(4, 'Metal water bottle');
CREATE INDEX items_bm25_idx ON items USING bm25 (id, description) WITH (key_field = 'id');

SELECT plan(4);
SELECT results_eq(
    $$SELECT id FROM items WHERE description ||| 'keyboard' ORDER BY id$$,
    ARRAY[1, 2],
    'searches find the rows matching a term'
);
SELECT results_eq(
    $$SELECT id FROM items WHERE description &&& 'metal keyboard' ORDER BY id$$,
    ARRAY[1],
    'searches can require every term'
);
SELECT matches(
    plan_of($$SELECT id FROM items WHERE description ||| 'keyboard'$$),
    'ParadeDB',
    'searches run on the bm25 index'
);
SELECT results_eq(
    $$SELECT id FROM items WHERE description ||| 'metal keyboard' ORDER BY pdb.score(id) DESC LIMIT 1$$,
    ARRAY[1],
    'BM25 ranks the row matching both terms first'
);
SELECT * FROM finish(TRUE);
