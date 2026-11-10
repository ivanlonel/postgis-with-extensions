-- https://github.com/pramsey/pgsql-http
CREATE EXTENSION http;

SELECT plan(2);
SELECT is(urlencode('my special string''s & things?'), 'my+special+string%27s+%26+things%3F', 'urlencode');
SELECT is((http_header('Authorization', 'Bearer token')).field, 'Authorization', 'http_header');
SELECT * FROM finish(TRUE);
