-- https://github.com/plproxy/plproxy
CREATE EXTENSION plproxy;

CREATE FUNCTION get_cluster_version(cluster_name text) RETURNS integer LANGUAGE plpgsql AS $$
BEGIN
	IF cluster_name = 'testcluster' THEN
		RETURN 5;
	END IF;
	IF cluster_name = 'badcluster' THEN
		RETURN 5;
	END IF;
	RAISE EXCEPTION 'no such cluster: %', cluster_name;
END
$$;
