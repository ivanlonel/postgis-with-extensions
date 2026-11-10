-- https://github.com/HypoPG/hypopg
CREATE EXTENSION hypopg;

CREATE TABLE hypo AS SELECT
	id,
	'line ' || id AS val
FROM generate_series(1, 10000) AS id;
ANALYZE hypo;

CREATE FUNCTION plan_of(query text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE
	line text;
	plan text := '';
BEGIN
	FOR line IN EXECUTE 'EXPLAIN ' || query LOOP
		plan := plan || line || E'\n';
	END LOOP;
	RETURN plan;
END
$$;

SELECT * FROM hypopg_create_index('CREATE INDEX ON hypo (id)');

SELECT plan(1);
SELECT matches(
	plan_of('SELECT * FROM hypo WHERE id = 1'), 'Index', 'the planner uses the hypothetical index'
);
SELECT * FROM finish(TRUE);
