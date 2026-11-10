-- https://github.com/pramsey/pgsql-http
CREATE EXTENSION http;

SELECT plan(5);
SELECT is(urlencode('my special string''s & things?'), 'my+special+string%27s+%26+things%3F', 'urlencode');
SELECT is((http_header('Authorization', 'Bearer token')).field, 'Authorization', 'http_header');
SELECT is((SELECT status FROM http_get('http://127.0.0.1:8000/hello.json')), 200, 'GET requests');
SELECT is(
    (SELECT content::jsonb ->> 'hello' FROM http_get('http://127.0.0.1:8000/hello.json')),
    'world',
    'responses are read'
);
SELECT is((SELECT status FROM http_get('http://127.0.0.1:8000/missing.json')), 404, 'HTTP errors are reported');
SELECT * FROM finish(TRUE);
