-- image: extended
-- https://github.com/supabase/wrappers
-- The S3 wrapper reads from the tests' HTTP server, standing in for an S3-compatible service with
-- path-style URLs: s3://bucket/fruits.csv is http://127.0.0.1:8000/bucket/fruits.csv.
CREATE EXTENSION wrappers;

CREATE FOREIGN DATA WRAPPER s3_wrapper HANDLER s3_fdw_handler VALIDATOR s3_fdw_validator;
CREATE SERVER s3_server FOREIGN DATA WRAPPER s3_wrapper OPTIONS (
    aws_access_key_id 'test',
    aws_secret_access_key 'test',
    aws_region 'us-east-1',
    endpoint_url 'http://127.0.0.1:8000',
    path_style_url 'true'
);
CREATE FOREIGN TABLE fruits (id text, name text) SERVER s3_server OPTIONS (
    uri 's3://bucket/fruits.csv', format 'csv', has_header 'true'
);

SELECT plan(1);
SELECT results_eq(
    'SELECT id, name FROM fruits ORDER BY id',
    $$VALUES ('1', 'apple'), ('2', 'banana'), ('3', 'cherry')$$,
    'the S3 wrapper reads CSV objects'
);
SELECT * FROM finish(TRUE);
