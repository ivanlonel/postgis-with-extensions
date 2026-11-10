-- https://github.com/credativ/toastinfo
CREATE EXTENSION toastinfo;

CREATE TABLE t (a text, b text);

INSERT INTO t VALUES ('null', NULL);
INSERT INTO t VALUES ('default', 'default');

ALTER TABLE t ALTER COLUMN b SET STORAGE EXTERNAL;
INSERT INTO t VALUES ('external-200', repeat('x', 200));
INSERT INTO t VALUES ('external-10000', repeat('x', 10000));

ALTER TABLE t ALTER COLUMN b SET STORAGE EXTENDED;
INSERT INTO t VALUES ('extended-10000', repeat('x', 10000));
INSERT INTO t VALUES ('extended-1000000', repeat('x', 1000000));

ALTER TABLE t ALTER COLUMN b SET COMPRESSION lz4;
INSERT INTO t VALUES ('lz4-1000000', repeat('x', 1000000));

SELECT plan(1);
SELECT results_eq(
	'SELECT a, pg_toastinfo(b) FROM t ORDER BY a COLLATE "C"',
	$$VALUES
		('default', 'short inline varlena'),
		('extended-10000', 'long inline varlena, compressed (pglz)'),
		('extended-1000000', 'toasted varlena, compressed (pglz)'),
		('external-10000', 'toasted varlena, uncompressed'),
		('external-200', 'long inline varlena, uncompressed'),
		('lz4-1000000', 'toasted varlena, compressed (lz4)'),
		('null', 'null')$$,
	'values report how they are stored'
);
SELECT * FROM finish(TRUE);
