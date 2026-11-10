-- https://github.com/pgRouting/pgrouting
CREATE EXTENSION pgrouting CASCADE;  -- requires postgis

-- A square 1-2-3-4 with a costly diagonal 1-4; 2->3 is one-way.
CREATE TABLE edges (id bigint PRIMARY KEY, source bigint, target bigint, cost float, reverse_cost float);
INSERT INTO edges VALUES
(1, 1, 2, 1, 1),
(2, 2, 3, 1, -1),
(3, 3, 4, 1, 1),
(4, 1, 4, 5, 5);

SELECT plan(6);
SELECT is(
	(SELECT max(agg_cost) FROM pgr_dijkstra('SELECT id, source, target, cost, reverse_cost FROM edges', 1, 4)),
	3::float8,
	'Dijkstra goes around the costly edge'
);
SELECT is(
	(
		SELECT array_agg(node ORDER BY seq)
		FROM pgr_dijkstra('SELECT id, source, target, cost, reverse_cost FROM edges', 1, 4)
	),
	ARRAY[1, 2, 3, 4]::bigint[],
	'Dijkstra returns the path'
);
SELECT is(
	(SELECT max(agg_cost) FROM pgr_dijkstra('SELECT id, source, target, cost, reverse_cost FROM edges', 4, 1)),
	5::float8,
	'one-way edges are honoured'
);
SELECT is(
	(SELECT max(agg_cost) FROM pgr_bdDijkstra('SELECT id, source, target, cost, reverse_cost FROM edges', 1, 4)),
	3::float8,
	'bidirectional Dijkstra agrees'
);
SELECT is(
	(
		SELECT count(*)
		FROM pgr_drivingDistance('SELECT id, source, target, cost, reverse_cost FROM edges', 1, 2)
	),
	3::bigint,
	'driving distance reaches the nodes within the cost'
);
SELECT is(
	(SELECT sum(cost) FROM pgr_kruskal('SELECT id, source, target, cost FROM edges')),
	3::float8,
	'Kruskal finds the minimum spanning tree'
);
SELECT * FROM finish(TRUE);
