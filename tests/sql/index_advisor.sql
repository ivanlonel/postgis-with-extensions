-- https://github.com/supabase/index_advisor
CREATE EXTENSION index_advisor CASCADE;  -- requires hypopg

CREATE TABLE book (id integer PRIMARY KEY, title text NOT NULL);
INSERT INTO book
SELECT
    i,
    'title ' || i
FROM generate_series(1, 10000) AS i;
ANALYZE book;

CREATE TEMPORARY TABLE advice AS
SELECT * FROM index_advisor('SELECT book.id FROM book WHERE title = $1');

SELECT plan(2);
SELECT is(
    (SELECT index_statements FROM advice),
    ARRAY['CREATE INDEX ON public.book USING btree (title)'],
    'the missing index is recommended'
);
SELECT ok(
    (SELECT total_cost_after::numeric < total_cost_before::numeric FROM advice),
    'with the cost it saves'
);
SELECT * FROM finish(TRUE);
