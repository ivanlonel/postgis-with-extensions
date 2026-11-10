-- preload: pg_qualstats
-- https://github.com/powa-team/pg_qualstats
CREATE EXTENSION pg_qualstats;

SELECT * FROM pg_qualstats;

SELECT v
FROM json_array_elements(pg_qualstats_index_advisor(min_filter => 50) -> 'indexes') AS v
ORDER BY v::text COLLATE "C";
