-- https://github.com/supabase/pg_graphql
CREATE EXTENSION pg_graphql;

CREATE TABLE account (id serial PRIMARY KEY, email text NOT NULL);
INSERT INTO account (email) VALUES ('a@example.com'), ('b@example.com');

SELECT plan(3);
SELECT is(
	graphql.resolve($$ { __typename } $$) -> 'data' ->> '__typename', 'Query', 'GraphQL queries resolve'
);
SELECT is(
	jsonb_array_length(
		graphql.resolve($$ { accountCollection { edges { node { email } } } } $$)
		-> 'data' -> 'accountCollection' -> 'edges'
	),
	2,
	'tables are exposed as collections'
);
SELECT is(
	graphql.resolve(
		$$ mutation { insertIntoAccountCollection(objects: [{email: "c@example.com"}]) { affectedCount } } $$
	) -> 'data' -> 'insertIntoAccountCollection' ->> 'affectedCount',
	'1',
	'mutations write rows'
);
SELECT * FROM finish(TRUE);
