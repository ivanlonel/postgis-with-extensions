-- https://github.com/postgrespro/rum
CREATE EXTENSION rum;

CREATE TABLE test_rum (t text, a tsvector);

CREATE TRIGGER tsvectorupdate
BEFORE UPDATE OR INSERT ON test_rum
FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger('a', 'pg_catalog.english', 't');

INSERT INTO test_rum (t) VALUES ('The situation is most beautiful');
INSERT INTO test_rum (t) VALUES ('It is a beautiful');
INSERT INTO test_rum (t) VALUES ('It looks like a beautiful place');

CREATE INDEX rumidx ON test_rum USING rum (a rum_tsvector_ops);

SELECT plan(1);
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
SELECT * FROM finish(TRUE);
