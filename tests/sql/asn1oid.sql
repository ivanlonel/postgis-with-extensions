-- https://github.com/df7cb/pgsql-asn1oid
CREATE EXTENSION asn1oid;

SELECT plan(1);
SELECT is('1.3.6.1.4.1'::asn1oid::text, '1.3.6.1.4.1', 'asn1oid round-trips');
SELECT * FROM finish(TRUE);
