-- https://github.com/petere/plsh
CREATE EXTENSION plsh;

CREATE FUNCTION concat_plsh(text, text) RETURNS text AS '
#!/bin/sh
echo "$1$2"
' LANGUAGE plsh;

CREATE FUNCTION count_lines(text) RETURNS integer AS '
#!/bin/sh
printf "%s" "$1" | wc -l
' LANGUAGE plsh;

CREATE FUNCTION failing() RETURNS text AS '
#!/bin/sh
echo "something went wrong" >&2
exit 1
' LANGUAGE plsh;

SELECT plan(3);
SELECT is(concat_plsh('It ', 'works!'), 'It works!', 'PL/sh functions run');
SELECT is(count_lines(E'a\nb\nc\n'), 3, 'PL/sh runs pipelines');
SELECT throws_like('SELECT failing()', '%something went wrong%', 'failing commands raise their error output');
SELECT * FROM finish(TRUE);
