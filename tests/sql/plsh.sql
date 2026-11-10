-- https://github.com/petere/plsh
CREATE EXTENSION plsh;

CREATE FUNCTION concat_plsh(text, text) RETURNS text AS '
#!/bin/sh
echo "$1$2"
' LANGUAGE plsh;

SELECT plan(1);
SELECT is(concat_plsh('It ', 'works!'), 'It works!', 'PL/sh functions run');
SELECT * FROM finish(TRUE);
