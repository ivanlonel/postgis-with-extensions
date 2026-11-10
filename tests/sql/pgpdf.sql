-- https://github.com/Florents-Tselai/pgpdf
CREATE EXTENSION pgpdf;
CREATE TEMPORARY TABLE documents AS
SELECT '/tests/sql/data/hello.pdf'::pdf AS doc;

SELECT plan(4);
SELECT is((SELECT pdf_title(doc) FROM documents), 'PWE test', 'titles are read');
SELECT is((SELECT pdf_num_pages(doc) FROM documents), 1, 'pages are counted');
SELECT matches((SELECT doc::text FROM documents), 'Hello, PDF', 'text is extracted');
SELECT is(
    pdf_title(pg_read_binary_file('/tests/sql/data/hello.pdf')::pdf),
    'PWE test',
    'PDFs load from bytea too'
);
SELECT * FROM finish(TRUE);
