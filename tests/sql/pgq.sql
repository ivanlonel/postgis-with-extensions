-- https://github.com/pgq/pgq
-- https://github.com/pgq/pgq-node
CREATE EXTENSION pgq;
CREATE EXTENSION pgq_node;

SELECT pgq.create_queue('pwe_queue');
SELECT pgq.register_consumer('pwe_queue', 'pwe_consumer');
SELECT pgq.insert_event('pwe_queue', 'greeting', 'hello');
-- No pgqd daemon here: tick by hand, in a later transaction than the event. ticker() only ticks
-- when one is due; force_tick() makes it so.
SELECT pgq.force_tick('pwe_queue');
SELECT pgq.ticker('pwe_queue');
CREATE TEMPORARY TABLE batch AS SELECT pgq.next_batch('pwe_queue', 'pwe_consumer') AS id;
CREATE TEMPORARY TABLE events AS SELECT * FROM pgq.get_batch_events((SELECT id FROM batch));
SELECT pgq.finish_batch((SELECT id FROM batch));

SELECT plan(4);
SELECT isnt((SELECT id FROM batch), NULL, 'ticks make batches');
SELECT is((
	SELECT ev_data FROM events
	WHERE ev_type = 'greeting'
), 'hello', 'batches carry the events');
SELECT is(
	(SELECT pending_events FROM pgq.get_consumer_info('pwe_queue', 'pwe_consumer')),
	0::bigint,
	'finished batches are consumed'
);
SELECT is_empty(
	$$SELECT * FROM pgq_node.get_queue_locations('pwe_queue')$$,
	'plain queues have no cascade locations'
);
SELECT * FROM finish(TRUE);

SELECT pgq.unregister_consumer('pwe_queue', 'pwe_consumer');
SELECT pgq.drop_queue('pwe_queue');
