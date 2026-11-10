-- https://github.com/petere/pgpcre
CREATE EXTENSION pgpcre;

SELECT plan(2);
SELECT ok('foo' ~ pcre 'o+$', 'text matches a pattern');
SELECT ok(pcre 'o+$' ~ 'foo', 'a pattern matches text');
SELECT * FROM finish(TRUE);
