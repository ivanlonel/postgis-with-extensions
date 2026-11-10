-- preload: pg_net
-- database: net
-- https://github.com/supabase/pg_net
-- The worker only serves requests queued in pg_net.database_name, after they commit.
CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE TEMPORARY TABLE requests AS
SELECT
	net.http_get('http://127.0.0.1:8000/hello.json') AS found,
	net.http_get('http://127.0.0.1:8000/missing.json') AS missing,
	net.http_post('http://127.0.0.1:8000/hello.json', '{"a": 1}'::jsonb) AS posted;

SELECT plan(3);
SELECT ok(
	wait_until($$
		SELECT EXISTS (
			SELECT FROM net._http_response AS r, requests
			WHERE r.id = requests.found AND r.status_code = 200 AND (r.content::jsonb ->> 'hello') = 'world'
		)
	$$),
	'GET requests are answered'
);
SELECT ok(
	wait_until($$
		SELECT EXISTS (
			SELECT FROM net._http_response AS r, requests
			WHERE r.id = requests.missing AND r.status_code = 404
		)
	$$),
	'HTTP errors come back as status codes'
);
SELECT ok(
	wait_until($$
		SELECT EXISTS (SELECT FROM net._http_response AS r, requests WHERE r.id = requests.posted)
	$$),
	'POST requests are sent'
);
SELECT * FROM finish(TRUE);
