-- https://github.com/postgrespro/rum
CREATE EXTENSION rum;

CREATE TABLE test_rum (t text, a tsvector);

CREATE TRIGGER tsvectorupdate
BEFORE UPDATE OR INSERT ON test_rum
FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger('a', 'pg_catalog.english', 't');

INSERT INTO test_rum (t) VALUES ('The situation is most beautiful');
INSERT INTO test_rum (t) VALUES ('It is a beautiful');
INSERT INTO test_rum (t) VALUES ('It looks like a beautiful place');
INSERT INTO test_rum (t)
SELECT 'filler text number ' || i FROM generate_series(1, 5000) AS i;

CREATE INDEX rumidx ON test_rum USING rum (a rum_tsvector_ops);
ANALYZE test_rum;
SELECT set_config('enable_seqscan', 'off', FALSE);

SELECT plan(3);
SELECT is(
	(
		SELECT t FROM test_rum
		WHERE a @@ to_tsquery('english', 'beautiful | place')
		ORDER BY a <=> to_tsquery('english', 'beautiful | place')
		LIMIT 1
	),
	'It looks like a beautiful place',
	'RUM ranks the best match first'
);
SELECT is(
	(
		SELECT count(*) FROM test_rum
		WHERE a @@ to_tsquery('english', 'beautiful')
	),
	3::bigint,
	'RUM finds the matches'
);
SELECT matches(
	plan_of($$
		SELECT t FROM test_rum
		WHERE a @@ to_tsquery('english', 'beautiful | place')
		ORDER BY a <=> to_tsquery('english', 'beautiful | place')
		LIMIT 1
	$$),
	'Index Scan using rumidx',
	'RUM orders by rank in the index'
);
SELECT * FROM finish(TRUE);
