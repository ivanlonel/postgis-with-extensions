-- https://github.com/bigsmoke/pg_rowalesce
CREATE EXTENSION pg_rowalesce CASCADE;

-- The extension ships its own tests, which raise on the first failure.
CALL test__pg_rowalesce();
