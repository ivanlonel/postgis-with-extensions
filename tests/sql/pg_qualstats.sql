-- preload: pg_qualstats
-- https://github.com/powa-team/pg_qualstats
CREATE EXTENSION pg_qualstats;

SELECT set_config('pg_qualstats.sample_rate', '1', FALSE);
CREATE TABLE quals AS
SELECT
	i AS id,
	i % 10 AS bucket
FROM generate_series(1, 10000) AS i;
SELECT count(*) FROM quals
WHERE bucket = 3;

SELECT plan(2);
SELECT ok(
	(
		SELECT count(*) > 0 FROM pg_qualstats
		WHERE lrelid = 'quals'::regclass
	),
	'predicates are sampled'
);
SELECT matches(
	(pg_qualstats_index_advisor(min_filter => 50) -> 'indexes')::text,
	'quals USING btree \(bucket\)',
	'missing indexes are suggested'
);
SELECT * FROM finish(TRUE);
