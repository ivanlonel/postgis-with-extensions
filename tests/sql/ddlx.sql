-- https://github.com/lacanoid/pgddl
CREATE EXTENSION ddlx SCHEMA pg_catalog;

CREATE TABLE ddlx_test (id integer PRIMARY KEY, name text NOT NULL DEFAULT 'none');
CREATE INDEX ddlx_test_name_idx ON ddlx_test (name);
CREATE FUNCTION ddlx_add(a integer, b integer) RETURNS integer LANGUAGE sql AS 'SELECT a + b';

SELECT plan(5);
SELECT matches(
    (
        SELECT ddlx_create(oid) FROM pg_database
        WHERE datname = current_database()
    ),
    'CREATE DATABASE',
    'ddlx_create scripts the database'
);
SELECT matches(ddlx_create('ddlx_test'::regclass), 'CREATE TABLE', 'ddlx_create scripts tables');
SELECT matches(ddlx_create('ddlx_test'::regclass), 'name text', 'with their columns');
SELECT matches(ddlx_script('ddlx_test'::regclass), 'ddlx_test_name_idx', 'and their indexes');
SELECT matches(
    ddlx_create('ddlx_add(integer,integer)'::regprocedure), 'CREATE OR REPLACE FUNCTION', 'ddlx scripts functions'
);
SELECT * FROM finish(TRUE);
