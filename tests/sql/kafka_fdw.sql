-- https://github.com/adjust/kafka_fdw
-- No Kafka broker runs in the tests: librdkafka must load and try to reach the brokers.
CREATE EXTENSION kafka_fdw;

CREATE SERVER kafka_server FOREIGN DATA WRAPPER kafka_fdw OPTIONS (brokers '127.0.0.1:9092');
CREATE USER MAPPING FOR PUBLIC SERVER kafka_server;
CREATE FOREIGN TABLE kafka_events (
    part integer OPTIONS (partition 'true'),
    offs bigint OPTIONS (offset 'true'),
    body text
) SERVER kafka_server OPTIONS (format 'csv', topic 'pwe_events');

SELECT plan(1);
SELECT matches(
    error_of('SELECT * FROM kafka_events WHERE part = 0 AND offs > 0 LIMIT 1'),
    '(?i)broker|transport|metadata|connect|timed out',
    'librdkafka tries to reach the brokers'
);
SELECT * FROM finish(TRUE);
