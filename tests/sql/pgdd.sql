-- https://github.com/rustprooflabs/pgdd
CREATE EXTENSION pgdd;
CREATE TABLE documented (id integer PRIMARY KEY, note text);
COMMENT ON TABLE documented IS 'A documented table';

SELECT plan(2);
SELECT is(
    (
        SELECT description FROM dd.tables
        WHERE s_name = 'public' AND t_name = 'documented'
    ),
    'A documented table',
    'tables are listed with their comments'
);
SELECT is(
    ARRAY(
        SELECT c_name::text FROM dd.columns
        WHERE s_name = 'public' AND t_name = 'documented'
        ORDER BY c_name
    ),
    ARRAY['id', 'note'],
    'and so are their columns'
);
SELECT * FROM finish(TRUE);
