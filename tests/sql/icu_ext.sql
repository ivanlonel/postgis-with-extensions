-- https://github.com/dverite/icu_ext
CREATE EXTENSION icu_ext;

SELECT plan(1);
SELECT ok(
	(
		SELECT count(*) > 0 FROM icu_locales_list()
		WHERE name LIKE 'pt%'
	), 'ICU locales are listed'
);
SELECT * FROM finish(TRUE);
