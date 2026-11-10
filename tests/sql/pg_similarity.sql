-- https://github.com/eulerto/pg_similarity
CREATE EXTENSION pg_similarity;

CREATE TABLE foo (a text);
CREATE TABLE bar (b text);

INSERT INTO foo
VALUES ('Euler'), ('Oiler'), ('Euler Taveira de Oliveira'), ('Maria Taveira dos Santos'), ('Carlos Santos Silva');
INSERT INTO bar
VALUES ('Euler T. de Oliveira'), ('Euller'), ('Oliveira, Euler Taveira'), ('Sr. Oliveira');

SELECT
	a,
	b,
	cosine(a, b),
	jaro(a, b),
	euclidean(a, b),
	qgram(a, b),
	lev(a, b)
FROM foo, bar;
