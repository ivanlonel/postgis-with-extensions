-- preload: pglogical
-- https://github.com/2ndQuadrant/pglogical
CREATE EXTENSION pglogical;

SELECT
	pglogical.pglogical_version(),
	pglogical.pglogical_version_num();
