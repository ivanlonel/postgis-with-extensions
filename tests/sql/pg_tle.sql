-- preload: pg_tle
-- https://github.com/aws/pg_tle
CREATE EXTENSION pg_tle;

SELECT * FROM pgtle.available_extensions();
