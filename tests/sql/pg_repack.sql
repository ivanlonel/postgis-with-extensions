-- https://github.com/reorg/pg_repack
CREATE EXTENSION pg_repack;

SELECT
	repack.version(),
	repack.version_sql();
