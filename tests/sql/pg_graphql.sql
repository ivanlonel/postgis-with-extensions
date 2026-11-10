-- https://github.com/supabase/pg_graphql
CREATE EXTENSION pg_graphql;

SELECT plan(1);
SELECT is(
	graphql.resolve($$ { __typename } $$) -> 'data' ->> '__typename', 'Query', 'GraphQL queries resolve'
);
SELECT * FROM finish(TRUE);
