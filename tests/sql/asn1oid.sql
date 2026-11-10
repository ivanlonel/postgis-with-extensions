-- https://github.com/df7cb/pgsql-asn1oid
CREATE EXTENSION asn1oid;

CREATE TABLE oids (oid asn1oid PRIMARY KEY);
INSERT INTO oids VALUES ('1.3.6.1.4.1'), ('1.3.6.1'), ('1.3.6.1.4.1.1'), ('2.5.4.3'), ('1.3.6.1.10');

SELECT plan(4);
SELECT is('1.3.6.1.4.1'::asn1oid::text, '1.3.6.1.4.1', 'OIDs round-trip');
SELECT is(
	(SELECT string_agg(oid::text, ' ' ORDER BY oid) FROM oids),
	'1.3.6.1 1.3.6.1.4.1 1.3.6.1.4.1.1 1.3.6.1.10 2.5.4.3',
	'OIDs sort by arc, numerically'
);
SELECT is((
	SELECT count(*) FROM oids
	WHERE oid = '2.5.4.3'
), 1::bigint, 'OIDs are indexed and compared');
SELECT throws_ok($$SELECT '1.3.a'::asn1oid$$, NULL, NULL, 'malformed OIDs are rejected');
SELECT * FROM finish(TRUE);
