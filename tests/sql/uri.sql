-- https://github.com/petere/pguri
CREATE EXTENSION uri;
CREATE TEMPORARY TABLE links AS
SELECT 'https://user@www.example.com:8080/a/b?q=1#frag'::uri AS link;

SELECT plan(4);
SELECT is((SELECT uri_host(link) FROM links), 'www.example.com', 'hosts are parsed');
SELECT is((SELECT uri_port(link) FROM links), 8080, 'ports too');
SELECT is((SELECT uri_path(link) FROM links), '/a/b', 'and paths');
SELECT is(
    uri_normalize('HTTP://www.Example.com/a/./b/../c'::uri)::text,
    'http://www.example.com/a/c',
    'URIs are normalized'
);
SELECT * FROM finish(TRUE);
