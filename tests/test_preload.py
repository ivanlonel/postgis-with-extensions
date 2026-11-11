"""SHARED_PRELOAD_LIBRARIES handling by the entrypoint wrapper."""

from __future__ import annotations

from typing import TYPE_CHECKING

import pytest

from scripts.manifest import load_registry
from tests._docker import run_once, scratch_volume, start_server

if TYPE_CHECKING:
    from tests._docker import Image, Server


def _registry_libraries(server: Server, *, legacy_only: bool) -> list[str]:
    installed = server.libraries()
    return [
        library.name
        for library in load_registry()
        if library.name in installed and (library.legacy if legacy_only else library.in_all)
    ]


def test_default_preload(default_server: Server, image: Image) -> None:
    """PostGIS 3.6 images keep preloading the legacy list; from 3.7 on, nothing is preloaded."""
    expected = (
        [] if image.postgis >= (3, 7) else _registry_libraries(default_server, legacy_only=True)
    )
    assert default_server.preloaded() == expected


def test_all_preset(all_server: Server) -> None:
    """``all`` preloads the registry libraries the image ships, except opt-in ones, in order."""
    assert all_server.preloaded() == _registry_libraries(all_server, legacy_only=False)


def test_opt_in_library_brings_its_requirements(image: Image, default_server: Server) -> None:
    """A library outside the presets is preloaded when named, with what it requires."""
    if "pg_documentdb" not in default_server.libraries():
        pytest.skip(f"DocumentDB isn't shipped for PostgreSQL {image.pg_major}")
    opt_in = ["pg_cron", "pg_documentdb_core", "pg_documentdb", "pg_documentdb_extended_rum"]
    server = start_server(image, role="opt-in", env={"SHARED_PRELOAD_LIBRARIES": "pg_documentdb"})
    try:
        preloaded = server.preloaded()
        assert [library for library in preloaded if library in opt_in] == opt_in
        assert set(preloaded) == set(default_server.preloaded()) | set(opt_in)
        assert server.setting("documentdb.bg_worker_database_name") == server.setting(
            "cron.database_name"
        )
    finally:
        server.remove()


def test_legacy_preset(image: Image) -> None:
    """``legacy`` restores the pre-3.7 default list."""
    server = start_server(image, env={"SHARED_PRELOAD_LIBRARIES": "legacy"})
    try:
        assert server.preloaded() == _registry_libraries(server, legacy_only=True)
    finally:
        server.remove()


def test_unknown_library_fails_fast(image: Image) -> None:
    """A library the image doesn't ship stops the container with an explanation."""
    process = run_once(image, env={"SHARED_PRELOAD_LIBRARIES": "pg_stat_statements,no_such_lib"})
    assert process.returncode != 0
    assert "no shared library 'no_such_lib'" in process.stderr


def test_user_options_win(image: Image) -> None:
    """
    Options passed by the user override the defaults the wrapper adds for a library.

    The wrapper would point pg_cron at POSTGRES_DB. (Not at template1: a session pg_cron keeps
    there makes the PostGIS init script's ``CREATE DATABASE`` fail.)
    """
    server = start_server(
        image,
        env={"SHARED_PRELOAD_LIBRARIES": "pg_cron", "POSTGRES_DB": "app"},
        command=["postgres", "-c", "cron.database_name=postgres"],
    )
    try:
        assert server.setting("cron.database_name") == "postgres"
    finally:
        server.remove()


def test_show_plans_turned_on_at_startup(image: Image) -> None:
    """
    pg_show_plans, which the wrapper turns off, collects plans when turned on at startup.

    That's the only way on PostgreSQL 14; ``tests/sql/pg_show_plans.sql`` turns it on per session.
    """
    server = start_server(
        image,
        env={"SHARED_PRELOAD_LIBRARIES": "pg_show_plans"},
        command=["postgres", "-c", "pg_show_plans.is_enabled=on"],
    )
    try:
        server.query("CREATE EXTENSION pg_show_plans")
        plans = server.scalar(
            "SELECT string_agg(plan, ' ') FROM pg_show_plans WHERE pid = pg_backend_pid()"
        )
        assert "Function Scan on pg_show_plans" in plans
    finally:
        server.remove()


def test_user_preload_option_is_extended(image: Image) -> None:
    """A shared_preload_libraries option passed by the user is extended, not overridden."""
    server = start_server(
        image,
        env={"SHARED_PRELOAD_LIBRARIES": "pg_wait_sampling"},
        command=["postgres", "-c", "shared_preload_libraries=pg_stat_statements"],
    )
    try:
        assert server.preloaded() == ["pg_stat_statements", "pg_wait_sampling"]
    finally:
        server.remove()


@pytest.mark.parametrize(
    "configured",
    ["pg_stat_statements", "pg_stat_statements, citus"],
    ids=["added", "already-listed"],
)
def test_first_libraries_go_first(image: Image, configured: str) -> None:
    """
    Citus, which must load before every other library, goes ahead of a cluster's own list.

    That holds when the list already has Citus after another library, too, which wouldn't start.
    """
    with scratch_volume() as volume:
        server = start_server(image, volume=volume)
        try:
            server.query(f"ALTER SYSTEM SET shared_preload_libraries = '{configured}'")
            server.stop()
        finally:
            server.remove()

        server = start_server(image, volume=volume, env={"SHARED_PRELOAD_LIBRARIES": "citus"})
        try:
            assert server.preloaded() == ["citus", "pg_stat_statements"]
            server.query("CREATE EXTENSION citus")
        finally:
            server.remove()


def test_existing_cluster(image: Image) -> None:
    """On an existing cluster, the variable adds to the configured list; unset, nothing changes."""
    with scratch_volume() as volume:
        server = start_server(image, volume=volume)
        try:
            server.query("ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements'")
            server.stop()
        finally:
            server.remove()

        server = start_server(
            image, volume=volume, env={"SHARED_PRELOAD_LIBRARIES": "pg_wait_sampling"}
        )
        try:
            assert server.preloaded() == ["pg_stat_statements", "pg_wait_sampling"]
            server.stop()
        finally:
            server.remove()

        server = start_server(image, volume=volume)
        try:
            assert server.preloaded() == ["pg_stat_statements"]
        finally:
            server.remove()
