-- https://github.com/dverite/icu_ext
CREATE EXTENSION icu_ext;

SELECT plan(4);
SELECT ok(
    (
        SELECT count(*) > 0 FROM icu_locales_list()
        WHERE name LIKE 'pt%'
    ), 'ICU locales are listed'
);
SELECT ok(icu_compare('a', 'B', 'en') < 0, 'strings compare by locale rules');
SELECT is(icu_transform('Ångström', 'Latin-ASCII'), 'Angstrom', 'strings are transliterated');
SELECT is(icu_number_spellout(42, 'en'), 'forty-two', 'numbers are spelled out');
SELECT * FROM finish(TRUE);
