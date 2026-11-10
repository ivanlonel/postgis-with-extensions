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

	# as an array reference
	for (@$arg) {
		$result .= $_;
	}

	# also works as a string
	$result .= $arg;

	return $result;
$$ LANGUAGE plperl;

SELECT plan(1);
SELECT matches(
	concat_array_elements(ARRAY['PL', '/', 'Perl']), '^PL/Perl', 'PL/Perl functions run'
);
SELECT * FROM finish(TRUE);
