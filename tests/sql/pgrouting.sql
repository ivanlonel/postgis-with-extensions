-- https://github.com/pgRouting/pgrouting
CREATE EXTENSION pgrouting CASCADE;  -- requires postgis

CREATE TABLE edges (id bigint PRIMARY KEY, source bigint, target bigint, cost float, reverse_cost float);
INSERT INTO edges VALUES
(1, 1, 2, 1, 1),
(2, 2, 3, 1, -1),
(3, 3, 4, 1, 1),
(4, 1, 4, 5, 5);

SELECT plan(1);
SELECT is(
	(SELECT max(agg_cost) FROM pgr_dijkstra('SELECT id, source, target, cost, reverse_cost FROM edges', 1, 4)),
	3::float8,
	'the shortest path goes around the expensive edge'
);
SELECT * FROM finish(TRUE);
