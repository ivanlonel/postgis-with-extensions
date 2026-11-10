-- https://github.com/theory/pg-semver
CREATE EXTENSION semver;

SELECT plan(1);
SELECT is(
	(
		SELECT max(v::semver)::text
		FROM unnest(ARRAY[
			'1.2.2', '0.2.2', '0.0.0', '0.1.999', '9999.9999999.823823', '1.0.0-beta1',
			'1.0.0-beta2', '1.0.0', '1.0.0-1', '1.0.0-alpha+d34dm34t', '1.0.0+d34dm34t',
			'20110204.0.0', '1.0.0-alpha.0a', '1.0.0+010', '1.0.0+alpha.010', '1.0.0-0AEF'
		]) AS v
	),
	'20110204.0.0',
	'versions sort semantically'
);
SELECT * FROM finish(TRUE);
