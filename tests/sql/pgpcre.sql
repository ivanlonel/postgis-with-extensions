-- https://github.com/petere/pgpcre
CREATE EXTENSION pgpcre;

SELECT plan(5);
SELECT ok('foo' ~ pcre 'o+$', 'text matches a pattern');
SELECT ok(pcre 'o+$' ~ 'foo', 'a pattern matches text');
SELECT ok(NOT 'FOO' ~ pcre 'o+$' AND 'FOO' ~ pcre '(?i)o+$', 'Perl options are honoured');
SELECT is(pcre_match('\d+-\d+', 'tel 555-1234 ext 9'), '555-1234', 'matches are extracted');
SELECT is(
    pcre_captured_substrings('(\d+)-(\d+)', 'tel 555-1234'),
    ARRAY['555', '1234'],
    'groups are captured'
);
SELECT * FROM finish(TRUE);
