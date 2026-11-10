-- https://github.com/hatarist/pg_xxhash
CREATE EXTENSION xxhash;

SELECT
	url,
	xxh32(url),
	xxh64(url),
	xxh3_64(url),
	xxh128(url),
	xxh32b(url),
	xxh64b(url),
	xxh3_64b(url),
	xxh128b(url)
FROM (SELECT 'https://example.com' AS url) AS x;
