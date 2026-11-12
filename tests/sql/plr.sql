-- image: extended
-- https://github.com/postgres-plr/plr
CREATE EXTENSION plr;

CREATE FUNCTION r_median(float8[]) RETURNS float8 AS 'median(arg1)' LANGUAGE plr;
CREATE FUNCTION r_slope(x float8[], y float8[]) RETURNS float8 AS 'unname(coef(lm(y ~ x))[2])' LANGUAGE plr;
CREATE FUNCTION r_version() RETURNS text AS 'R.version.string' LANGUAGE plr;

SELECT plan(3);
SELECT is(r_median(ARRAY[1, 9, 3]::float8[]), 3::float8, 'R computes medians');
SELECT is(
    round(r_slope(ARRAY[1, 2, 3, 4]::float8[], ARRAY[3, 5, 7, 9]::float8[])::numeric, 6),
    2::numeric,
    'R fits linear models'
);
SELECT matches(r_version(), '^R version [0-9]+\.', 'R reports its version');
SELECT * FROM finish(TRUE);
