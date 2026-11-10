"""Client programs that come with extensions: pg_repack, the pgAgent daemon and repmgr."""

from __future__ import annotations

import time
from typing import TYPE_CHECKING, Final

from tests._docker import start_server

if TYPE_CHECKING:
    from tests._docker import Image, Server

JOB_SQL: Final = """
DO $$
DECLARE
    jid integer;
BEGIN
    INSERT INTO pgagent.pga_job (jobjclid, jobname, jobenabled)
    VALUES (1, 'pwe test job', TRUE)
    RETURNING jobid INTO jid;
    INSERT INTO pgagent.pga_jobstep (jstjobid, jstname, jstenabled, jstkind, jstdbname, jstcode)
    VALUES (jid, 'insert a row', TRUE, 's', current_database(), 'INSERT INTO ran DEFAULT VALUES');
    -- Due right away, rather than at the next scheduled minute.
    UPDATE pgagent.pga_job SET jobnextrun = now() WHERE jobid = jid;
END
$$;
"""
"""A pgAgent job with one SQL step, due now."""

REPMGR_CONF: Final = """\
node_id=1
node_name='primary'
conninfo='host=/var/run/postgresql dbname=postgres user=postgres'
data_directory='{data_directory}'
"""
"""Configuration of a one-node repmgr cluster on the test server."""

REPMGR_CONF_PATH: Final = "/tmp/repmgr.conf"  # noqa: S108 -- inside the throwaway test container
"""Where repmgr's configuration is written, in the container."""


def test_pg_repack_rewrites_a_table(default_server: Server) -> None:
    """pg_repack rewrites a bloated table online, keeping its rows."""
    with default_server.database() as database:
        default_server.query("CREATE EXTENSION pg_repack", database=database)
        default_server.query(
            "CREATE TABLE bloated (id integer PRIMARY KEY, payload text);"
            " INSERT INTO bloated SELECT i, repeat('x', 100) FROM generate_series(1, 20000) AS i;"
            " DELETE FROM bloated WHERE id % 10 <> 0;",
            database=database,
        )
        size = "SELECT pg_relation_size('bloated')"
        before = int(default_server.scalar(size, database=database))
        process = default_server.exec(
            "pg_repack", "--table=public.bloated", f"--dbname={database}"
        )
        assert process.returncode == 0, process.stderr
        assert int(default_server.scalar(size, database=database)) < before / 4
        assert default_server.scalar("SELECT count(*) FROM bloated", database=database) == "2000"


def test_pgagent_runs_jobs(image: Image) -> None:
    """The pgAgent daemon picks up a due job and runs its SQL step."""
    server = start_server(image, role="pgagent")
    try:
        server.query("CREATE EXTENSION pgagent")
        server.query("CREATE TABLE ran (at timestamptz NOT NULL DEFAULT now())")
        process = server.psql(stdin=JOB_SQL)
        assert process.returncode == 0, process.stderr
        server.spawn(
            "pgagent", "-f", "-t", "1", "hostaddr=127.0.0.1 dbname=postgres user=postgres"
        )
        deadline = time.monotonic() + 120
        while server.scalar("SELECT count(*) FROM ran") == "0" and time.monotonic() < deadline:
            time.sleep(1)
        assert server.scalar("SELECT count(*) FROM ran") != "0", server.logs()
        assert server.scalar("SELECT jlgstatus FROM pgagent.pga_joblog LIMIT 1") == "s"
    finally:
        server.remove()


def test_repmgr_registers_the_primary(image: Image) -> None:
    """The repmgr command registers the server as its cluster's primary, then reports it."""
    server = start_server(image, role="repmgr", env={"SHARED_PRELOAD_LIBRARIES": "repmgr"})
    try:
        config = REPMGR_CONF.format(data_directory=server.setting("data_directory"))
        written = server.exec("sh", "-c", f"cat > {REPMGR_CONF_PATH}", stdin=config)
        assert written.returncode == 0, written.stderr
        register = server.exec("repmgr", "-f", REPMGR_CONF_PATH, "primary", "register")
        assert register.returncode == 0, register.stderr
        assert server.scalar("SELECT type FROM repmgr.nodes WHERE node_id = 1") == "primary"
        show = server.exec("repmgr", "-f", REPMGR_CONF_PATH, "cluster", "show")
        assert show.returncode == 0, show.stderr
        assert "primary" in show.stdout
    finally:
        server.remove()
