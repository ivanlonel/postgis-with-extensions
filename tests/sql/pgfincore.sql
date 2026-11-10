-- https://github.com/klando/pgfincore
CREATE EXTENSION pgfincore;

CREATE TABLE cached AS
SELECT
    i,
    md5(i::text) AS hash
FROM generate_series(1, 100000) AS i;
-- Write the table out, so its pages are in the OS cache. (sqlfluff can't parse CHECKPOINT.)
CHECKPOINT;  -- noqa: PRS
SELECT count(*) FROM cached;

SELECT plan(3);
SELECT ok((SELECT os_page_size > 0 FROM pgsysconf()), 'the OS page size is reported');
SELECT ok((SELECT sum(rel_os_pages) > 0 FROM pgfincore('cached')), 'relation pages are counted');
SELECT ok((SELECT sum(pages_mem) > 0 FROM pgfincore('cached')), 'pages in the OS cache are found');
SELECT * FROM finish(TRUE);
