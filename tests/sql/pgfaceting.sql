-- https://github.com/cybertec-postgresql/pgfaceting
CREATE EXTENSION pgfaceting CASCADE;  -- requires roaringbitmap

CREATE TYPE mimetype AS ENUM (
    'application/pdf', 'text/html', 'image/jpeg', 'image/png', 'application/msword', 'text/csv',
    'application/zip', 'application/vnd.ms-powerpoint'
);

CREATE TABLE documents (
    id int4 PRIMARY KEY,
    created timestamptz NOT NULL,
    finished timestamptz,
    category_id int4,
    tags text[],
    type mimetype,
    size int8,
    title text
);

INSERT INTO documents (id, created, finished, category_id, tags, type, size, title) VALUES
(
    1,
    '2010-01-01 00:00:42+02',
    '2010-01-01 09:45:29+02',
    8,
    '{blue,burlywood,antiquewhite,olive}',
    'application/pdf',
    71205,
    'Interracial marriage Science Research'
),
(
    2,
    '2010-01-01 00:00:37+02',
    '2010-01-01 03:55:08+02',
    12,
    '{lightcoral,bisque,blue,"aqua blue","red purple",aqua}',
    'text/html',
    682069,
    'Odour and trials'
),
(
    3,
    '2010-01-01 00:00:33+02',
    '2010-01-02 18:29:15+02',
    9,
    '{"mustard brown","very light pink"}',
    'application/pdf',
    143708,
    'Technical scale'
),
(
    4,
    '2010-01-01 00:00:35+02',
    '2010-01-02 01:12:08+02',
    24,
    '{orange,green,blue}',
    'text/html',
    280663,
    'Database of Denmark'
),
(
    5,
    '2010-01-01 00:01:06+02',
    '2010-01-01 23:18:56+02',
    24,
    '{orange,chocolate}',
    'image/jpeg',
    111770,
    'Passage to now resumed'
),
(
    6,
    '2010-01-01 00:01:05+02',
    '2010-01-01 10:25:29+02',
    8,
    '{blue,aquamarine}',
    'application/pdf',
    110809,
    'East. Mesopotamia'
),
(
    7,
    '2010-01-01 00:00:57+02',
    '2010-01-02 00:41:01+02',
    NULL,
    '{}',
    'application/pdf',
    230803,
    'Bahía de It has also conquered'
),
(
    8,
    '2010-01-01 00:01:11+02',
    '2010-01-01 14:22:11+02',
    24,
    '{blue,burlywood,"dirt brown",orange}',
    'image/jpeg',
    1304196,
    '15-fold'
),
(
    9,
    '2010-01-01 00:01:47+02',
    '2010-01-01 09:59:57+02',
    9,
    '{green,blue,orange}',
    'application/pdf',
    142410,
    'Popular Western localized function model'
),
(
    10,
    '2010-01-01 00:01:31+02',
    '2010-01-01 05:49:47+02',
    24,
    '{green,lavender,blue,orange,red,darkslateblue}',
    'text/html',
    199703,
    'Rapidly expanding Large Interior Form'
);

SELECT faceting.add_faceting_to_table(
    'documents',
    key => 'id',
    facets => ARRAY[
        faceting.datetrunc_facet('created', 'month'),
        faceting.datetrunc_facet('finished', 'month'),
        faceting.plain_facet('category_id'),
        faceting.plain_facet('type'),
        faceting.bucket_facet('size', buckets => ARRAY[0, 1000, 5000, 10000, 50000, 100000, 500000])
    ]
);

-- Changes are recorded as deltas, which maintenance merges into the facet index.
INSERT INTO documents (id, created, finished, category_id, tags, type, size, title) VALUES
(11, '2010-01-01 00:02:00+02', NULL, 24, '{blue}', 'text/csv', 1234, 'Late arrival');
CALL faceting.run_maintenance();

SELECT plan(3);
SELECT is(
    (
        SELECT sum(cardinality)::bigint
        FROM
            faceting.count_results(
                'documents'::regclass,
                filters => ARRAY[ROW('category_id', 24)]::faceting.facet_filter[]
            )
        WHERE facet_name = 'type'
    ),
    5::bigint,
    'facets count the filtered documents'
);
SELECT is(
    (
        SELECT sum(cardinality)::bigint
        FROM
            faceting.count_results(
                'documents'::regclass,
                filters => ARRAY[ROW('type', 'text/csv')]::faceting.facet_filter[]
            )
        WHERE facet_name = 'category_id'
    ),
    1::bigint,
    'new rows reach the facets'
);
SELECT ok(
    (
        SELECT count(*) > 0 FROM faceting.top_values('documents'::regclass, n => 3)
        WHERE facet_name = 'category_id'
    ),
    'top values are listed'
);
SELECT * FROM finish(TRUE);
