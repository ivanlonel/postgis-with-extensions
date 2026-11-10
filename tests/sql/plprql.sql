-- https://github.com/kaspermarstal/plprql
CREATE EXTENSION plprql;

CREATE TABLE players (name text NOT NULL, score integer NOT NULL);
INSERT INTO players VALUES ('ann', 12), ('bob', 30), ('cid', 21);
CREATE FUNCTION high_scorers(min_score integer) RETURNS TABLE (name text, score integer) LANGUAGE plprql AS $$
    from players
    filter score > $1
    sort {-score}
    select {name, score}
$$;

SELECT plan(2);
SELECT is(ARRAY(SELECT name FROM high_scorers(20)), ARRAY['bob', 'cid'], 'PRQL functions run');
SELECT matches(prql_to_sql('from players | take 1'), 'LIMIT 1', 'PRQL compiles to SQL');
SELECT * FROM finish(TRUE);
