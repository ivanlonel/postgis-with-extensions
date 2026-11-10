-- https://github.com/RhodiumToad/ip4r
CREATE EXTENSION ip4r;

CREATE TABLE networks (id integer PRIMARY KEY, net iprange);
INSERT INTO networks
SELECT
	i,
	format('10.%s.%s.0/24', i / 256, i % 256)::iprange
FROM generate_series(0, 9999) AS i;
CREATE INDEX networks_net_idx ON networks USING gist (net);
ANALYZE networks;

SELECT plan(6);
SELECT is((ipaddress '255.255.255.255' / 31)::text, '255.255.255.254/31', 'IPv4 prefixes');
SELECT is(
	(ipaddress 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' / 127)::text,
	'ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffe/127',
	'IPv6 prefixes'
);
-- (The linter can't parse ip4r's >>= (contains or equals) operator, nor lay out what follows.)
SELECT ok(ip4r '10.0.0.0/8' >>= ip4 '10.1.2.3', 'ranges contain addresses');  -- noqa: PRS
SELECT is(family(ipaddress '::1'), 6, 'address families are told apart');
SELECT is(
	(SELECT id FROM networks WHERE net >>= ipaddress '10.3.7.42'),  -- noqa: PRS, LT14
	775,
	'the network holding an address is found'
);
SELECT matches(
	plan_of($$SELECT id FROM networks WHERE net >>= ipaddress '10.3.7.42'$$),
	'networks_net_idx',
	'containment searches use the GiST index'
);
SELECT * FROM finish(TRUE);
