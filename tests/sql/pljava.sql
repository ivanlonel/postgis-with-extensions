-- image: extended
-- https://github.com/tada/pljava
-- New clusters set pljava.vmoptions, without which Java 21 doesn't start (image/initdb/z_conf.sh).
CREATE EXTENSION pljava;

CREATE FUNCTION java_max(integer, integer) RETURNS integer AS 'java.lang.Math.max' LANGUAGE java;
CREATE FUNCTION java_hex(integer) RETURNS varchar AS 'java.lang.Integer.toHexString' LANGUAGE java;
CREATE FUNCTION java_property(varchar) RETURNS varchar AS 'java.lang.System.getProperty' LANGUAGE java;

SELECT plan(3);
SELECT is(java_max(3, 7), 7, 'Java static methods run as functions');
SELECT is(java_hex(255)::text, 'ff', 'Java strings come back as text');
SELECT matches(java_property('java.version')::text, '^[0-9]+\.', 'the JVM reports its version');
SELECT * FROM finish(TRUE);
