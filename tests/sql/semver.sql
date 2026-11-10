-- https://github.com/theory/pg-semver
CREATE EXTENSION semver;

SELECT plan(5);
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
SELECT ok('1.0.0-alpha'::semver < '1.0.0'::semver, 'pre-releases sort before releases');
SELECT ok('1.10.0'::semver > '1.9.0'::semver, 'components compare numerically');
SELECT is(get_semver_major('2.3.4'::semver), 2, 'components are extracted');
SELECT throws_ok($$SELECT '1.0'::semver$$, NULL, NULL, 'incomplete versions are rejected');
SELECT * FROM finish(TRUE);
