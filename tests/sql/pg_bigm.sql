-- https://github.com/pgbigm/pg_bigm
CREATE EXTENSION pg_bigm;

CREATE TABLE pg_tools (tool text, description text);
INSERT INTO pg_tools VALUES
('pg_hint_plan', 'Tool that allows a user to specify an optimizer HINT to PostgreSQL'),
('pg_dbms_stats', 'Tool that allows a user to stabilize planner statistics in PostgreSQL'),
('pg_bigm', 'Tool that provides 2-gram full text search capability in PostgreSQL');
CREATE INDEX pg_tools_idx ON pg_tools USING gin (description gin_bigm_ops);

SELECT plan(1);
SELECT is(
	(
		SELECT tool FROM pg_tools
		WHERE description LIKE likequery('full text search')
	),
	'pg_bigm',
	'bigram search finds the row'
);
SELECT * FROM finish(TRUE);
