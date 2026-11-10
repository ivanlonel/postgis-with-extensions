-- https://github.com/RhodiumToad/ip4r
CREATE EXTENSION ip4r;

SELECT plan(2);
SELECT is((ipaddress '255.255.255.255' / 31)::text, '255.255.255.254/31', 'IPv4 prefixes');
SELECT is(
	(ipaddress 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' / 127)::text,
	'ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffe/127',
	'IPv6 prefixes'
);
SELECT * FROM finish(TRUE);
