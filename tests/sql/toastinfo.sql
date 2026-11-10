-- https://github.com/credativ/toastinfo
CREATE EXTENSION toastinfo;

CREATE TABLE t (a text, b text);

INSERT INTO t VALUES ('null', NULL);
INSERT INTO t VALUES ('default', 'default');

ALTER TABLE t ALTER COLUMN b SET STORAGE EXTERNAL;
INSERT INTO t VALUES ('external-10', 'external'); -- short inline varlena
INSERT INTO t VALUES ('external-200', repeat('x', 200)); -- long inline varlena, uncompressed
INSERT INTO t VALUES ('external-10000', repeat('x', 10000)); -- toasted varlena, uncompressed
INSERT INTO t VALUES ('external-1000000', repeat('x', 1000000)); -- toasted varlena, uncompressed

ALTER TABLE t ALTER COLUMN b SET STORAGE EXTENDED;
INSERT INTO t VALUES ('extended-10', 'extended'); -- short inline varlena
INSERT INTO t VALUES ('extended-200', repeat('x', 200)); -- long inline varlena, uncompressed
INSERT INTO t VALUES ('extended-10000', repeat('x', 10000)); -- long inline varlena, compressed (pglz)
INSERT INTO t VALUES ('extended-1000000', repeat('x', 1000000)); -- toasted varlena, compressed (pglz)

ALTER TABLE t ALTER COLUMN b SET COMPRESSION lz4;
INSERT INTO t VALUES ('lz4-10000', repeat('x', 10000)); -- long inline varlena, compressed (lz4)
INSERT INTO t VALUES ('lz4-1000000', repeat('x', 1000000)); -- toasted varlena, compressed (lz4)

SELECT
	a,
	length(b),
	pg_column_size(b),
	pg_toastinfo(b),
	pg_toastpointer(b)
FROM t;
