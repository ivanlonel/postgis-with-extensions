-- https://github.com/supabase/pg_graphql
CREATE EXTENSION pg_graphql;

-- Inflect names as the documentation's examples do (account -> Account, insertIntoAccountCollection).
COMMENT ON SCHEMA public IS '@graphql({"inflect_names": true})';
CREATE TABLE account (id serial PRIMARY KEY, email text NOT NULL);
INSERT INTO account (email) VALUES ('a@example.com'), ('b@example.com');

-- Keep the mutation's response: its errors, if any, show in the test output.
CREATE TEMPORARY TABLE mutation AS
SELECT
	graphql.resolve(
		$$ mutation { insertIntoAccountCollection(objects: [{email: "c@example.com"}]) { affectedCount } } $$
	) AS response;
SELECT response FROM mutation;

SELECT plan(4);
SELECT is(
	graphql.resolve($$ { __typename } $$) -> 'data' ->> '__typename', 'Query', 'GraphQL queries resolve'
);
SELECT is(
	jsonb_array_length(
		graphql.resolve($$ { accountCollection { edges { node { email } } } } $$)
		-> 'data' -> 'accountCollection' -> 'edges'
	),
	3,
	'tables are exposed as collections'
);
SELECT is(
	(SELECT response -> 'data' -> 'insertIntoAccountCollection' ->> 'affectedCount' FROM mutation),
	'1',
	'mutations report what they wrote'
);
SELECT is(
	(
		SELECT count(*) FROM account
		WHERE email = 'c@example.com'
	),
	1::bigint,
	'mutations write rows'
);
SELECT * FROM finish(TRUE);
