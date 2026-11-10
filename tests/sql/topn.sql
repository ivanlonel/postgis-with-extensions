-- https://github.com/citusdata/postgresql-topn
CREATE EXTENSION topn;
CREATE TABLE views (page text NOT NULL);
INSERT INTO views VALUES ('a'), ('b'), ('a'), ('c'), ('a'), ('b'), ('a'), ('a'), ('b');

CREATE TEMPORARY TABLE top AS
SELECT (topn(topn_add_agg(page), 2)).* FROM views;

SELECT plan(2);
SELECT is(
    ARRAY(
        SELECT item FROM top
        ORDER BY frequency DESC
    ),
    ARRAY['a', 'b'],
    'the most frequent items come first'
);
SELECT is(
    ARRAY(
        SELECT frequency FROM top
        ORDER BY frequency DESC
    ),
    ARRAY[5, 3]::bigint[],
    'with their counts'
);
SELECT * FROM finish(TRUE);
