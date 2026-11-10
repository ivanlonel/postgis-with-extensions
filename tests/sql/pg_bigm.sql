-- https://github.com/pgbigm/pg_bigm
CREATE EXTENSION pg_bigm;

CREATE TABLE pg_tools (tool text, description text);
INSERT INTO pg_tools VALUES
('pg_hint_plan', 'Tool that allows a user to specify an optimizer HINT to PostgreSQL'),
('pg_dbms_stats', 'Tool that allows a user to stabilize planner statistics in PostgreSQL'),
('pg_bigm', 'Tool that provides 2-gram full text search capability in PostgreSQL');
INSERT INTO pg_tools
SELECT
	'tool ' || i,
	'unrelated description ' || i
FROM generate_series(1, 5000) AS i;
CREATE INDEX pg_tools_idx ON pg_tools USING gin (description gin_bigm_ops);
ANALYZE pg_tools;
SELECT set_config('enable_seqscan', 'off', FALSE);

SELECT plan(4);
SELECT is(
	(
		SELECT tool FROM pg_tools
		WHERE description LIKE likequery('full text search')
	),
	'pg_bigm',
	'bigram search finds the row'
);
SELECT matches(
	plan_of($$SELECT tool FROM pg_tools WHERE description LIKE likequery('full text search')$$),
	'pg_tools_idx',
	'bigram searches use the GIN index'
);
SELECT is(show_bigm('pg'), ARRAY[' p', 'g ', 'pg'], 'strings split into bigrams');
SELECT ok(bigm_similarity('PostgreSQL', 'PostgreSOL') > 0.5, 'similar strings are similar');
SELECT * FROM finish(TRUE);
