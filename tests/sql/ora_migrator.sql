-- https://github.com/cybertec-postgresql/ora_migrator
-- No Oracle server runs in the tests: a migration must try to read Oracle's catalog through
-- oracle_fdw, which db_migrator drives.
CREATE EXTENSION ora_migrator CASCADE;  -- requires db_migrator and oracle_fdw

CREATE SERVER oracle FOREIGN DATA WRAPPER oracle_fdw OPTIONS (dbserver '//127.0.0.1:1521/FREEPDB1');
CREATE USER MAPPING FOR current_user SERVER oracle OPTIONS (user 'scott', password 'tiger');

SELECT plan(2);
SELECT is(
    ARRAY(
        SELECT extname::text FROM pg_extension
        WHERE extname IN ('db_migrator', 'oracle_fdw')
        ORDER BY extname
    ),
    ARRAY['db_migrator', 'oracle_fdw'],
    'the migration framework and the wrapper come along'
);
SELECT matches(
    error_of($$SELECT db_migrate_prepare(plugin => 'ora_migrator', server => 'oracle', only_schemas => '{SCOTT}')$$),
    'ORA-\d+',
    'migrations read the Oracle catalog through oracle_fdw'
);
SELECT * FROM finish(TRUE);
