-- https://github.com/RekGRpth/pg_curl
-- Fetch a file from the tests' local HTTP server.
CREATE EXTENSION pg_curl;

SELECT curl_easy_reset();
SELECT curl_easy_setopt_url('http://127.0.0.1:8000/hello.json');
SELECT curl_easy_perform();

SELECT plan(1);
SELECT is(
    convert_from(curl_easy_getinfo_data_in(), 'UTF8')::jsonb,
    '{"hello": "world"}'::jsonb,
    'libcurl fetches URLs'
);
SELECT * FROM finish(TRUE);
