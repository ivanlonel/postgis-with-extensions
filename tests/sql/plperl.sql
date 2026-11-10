-- https://www.postgresql.org/docs/current/plperl.html
CREATE EXTENSION plperl;
CREATE EXTENSION plperlu;
CREATE EXTENSION jsonb_plperl;
CREATE EXTENSION hstore_plperl CASCADE;  -- requires hstore
CREATE EXTENSION bool_plperl;

CREATE FUNCTION concat_array_elements(text[]) RETURNS text AS $$
	my $arg = shift;
	my $result = "";
	return undef if (!defined $arg);
	for (@$arg) {
		$result .= $_;
	}
	return $result;
$$ LANGUAGE plperl;

CREATE FUNCTION perl_count_classes() RETURNS integer AS $$
	my $rv = spi_exec_query("SELECT count(*) AS n FROM pg_class WHERE relname = 'pg_class'");
	return $rv->{rows}[0]->{n};
$$ LANGUAGE plperl;

CREATE FUNCTION perl_hash_size(value jsonb) RETURNS integer
TRANSFORM FOR TYPE jsonb
AS $$
	my ($value) = @_;
	return scalar keys %$value;
$$ LANGUAGE plperl;

CREATE FUNCTION perl_hstore_get(value hstore, key text) RETURNS text
TRANSFORM FOR TYPE hstore
AS $$
	my ($value, $key) = @_;
	return $value->{$key};
$$ LANGUAGE plperl;

CREATE FUNCTION perl_negate(value boolean) RETURNS boolean
TRANSFORM FOR TYPE boolean
AS $$
	my ($value) = @_;
	return !$value;
$$ LANGUAGE plperl;

-- Untrusted Perl can load modules.
CREATE FUNCTION perl_floor(value float8) RETURNS integer AS $$
	use POSIX ();
	return POSIX::floor($_[0]);
$$ LANGUAGE plperlu;

CREATE TABLE audited (value text, changed_by text);
CREATE FUNCTION perl_stamp() RETURNS trigger AS $$
	$_TD->{new}{changed_by} = 'plperl';
	return "MODIFY";
$$ LANGUAGE plperl;
CREATE TRIGGER audited_stamp BEFORE INSERT ON audited FOR EACH ROW EXECUTE FUNCTION perl_stamp();
INSERT INTO audited (value) VALUES ('x');

SELECT plan(7);
SELECT is(concat_array_elements(ARRAY['PL', '/', 'Perl']), 'PL/Perl', 'PL/Perl functions run');
SELECT is(perl_count_classes(), 1, 'PL/Perl runs queries');
SELECT is(perl_hash_size('{"a": 1, "b": 2}'::jsonb), 2, 'jsonb values arrive as hashes');
SELECT is(perl_hstore_get('a=>1, b=>2'::hstore, 'b'), '2', 'hstore values arrive as hashes');
SELECT is(perl_negate(TRUE), FALSE, 'booleans arrive as booleans');
SELECT is(perl_floor(2.7), 2, 'PL/PerlU loads modules');
SELECT is((SELECT changed_by FROM audited), 'plperl', 'PL/Perl triggers modify rows');
SELECT * FROM finish(TRUE);
