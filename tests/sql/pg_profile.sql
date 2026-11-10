-- https://github.com/zubkov-andrei/pg_profile
CREATE EXTENSION pg_profile CASCADE;  -- requires dblink and plpgsql

-- Two samples make a report interval.
SELECT * FROM take_sample();
SELECT count(*) FROM generate_series(1, 100000);
SELECT * FROM take_sample();

SELECT plan(3);
SELECT
    is((
        SELECT count(*) FROM show_servers()
        WHERE server_name = 'local'
    ), 1::bigint, 'the local server is registered');
SELECT cmp_ok((SELECT count(*) FROM show_samples()), '>=', 2::bigint, 'samples are taken');
SELECT matches(
    get_report((SELECT min(sample) FROM show_samples()), (SELECT max(sample) FROM show_samples())),
    '<html',
    'reports are rendered'
);
SELECT * FROM finish(TRUE);
