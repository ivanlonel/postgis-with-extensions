"""PoWA repository setup on new clusters."""

from __future__ import annotations

from typing import TYPE_CHECKING, Final

from tests._docker import run_once, start_server

if TYPE_CHECKING:
    from tests._docker import Image, Server

POWA_EXTENSIONS: Final = {
    "btree_gist",
    "pg_qualstats",
    "pg_stat_kcache",
    "pg_stat_statements",
    "pg_track_settings",
    "pg_wait_sampling",
    "powa",
}
"""Extensions the setup creates in the powa database."""


def _has_powa_database(server: Server) -> bool:
    return server.scalar("SELECT count(*) FROM pg_database WHERE datname = 'powa'") == "1"


def test_powa_database_by_default(default_server: Server, image: Image) -> None:
    """PostGIS 3.6 images set PoWA up by default; from 3.7 on, only when it's enabled."""
    assert _has_powa_database(default_server) == (image.postgis < (3, 7))


def test_powa_setup(all_server: Server) -> None:
    """Enabling PoWA creates its database, with the statistics extensions."""
    assert _has_powa_database(all_server)
    extensions = set(all_server.query("SELECT extname FROM pg_extension", database="powa"))
    assert extensions >= POWA_EXTENSIONS
    assert "hypopg" in all_server.query("SELECT extname FROM pg_extension", database="template1")


def test_remote_snapshot_and_extra_sql(image: Image) -> None:
    """POWA_LOCAL_SNAPSHOT=NO skips PoWA's own worker; POWA_EXTRA_SQL runs in the powa database."""
    server = start_server(
        image,
        env={
            "SHARED_PRELOAD_LIBRARIES": "powa",
            "POWA_LOCAL_SNAPSHOT": "NO",
            "POWA_EXTRA_SQL": "CREATE TABLE extra_sql_marker ()",
        },
    )
    try:
        preloaded = server.preloaded()
        assert "powa" not in preloaded
        assert "pg_stat_statements" in preloaded
        assert server.scalar("SELECT to_regclass('extra_sql_marker')", database="powa")
    finally:
        server.remove()


def test_standby_role_is_rejected(image: Image) -> None:
    """The removed POWA_ROLE=STANDBY mode fails initialization instead of creating a primary."""
    process = run_once(image, env={"POWA_ROLE": "STANDBY", "POWA_PRIMARY": "primary"})
    assert process.returncode != 0
    assert "POWA_ROLE=STANDBY is not supported" in process.stderr
