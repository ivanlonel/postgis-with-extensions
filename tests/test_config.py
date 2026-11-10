"""Configuration written on new clusters, and applied for the enabled libraries."""

from __future__ import annotations

import re
from typing import TYPE_CHECKING

from scripts.manifest import load_registry
from tests._docker import start_server
from tests.conftest import ALL_DATABASE

if TYPE_CHECKING:
    from tests._docker import Image, Server


def test_new_cluster_defaults(default_server: Server, image: Image) -> None:
    """New clusters get the logical decoding and locking defaults, plus the legacy ones on 3.6."""
    assert default_server.setting("wal_level") == "logical"
    assert default_server.setting("max_wal_senders") == "10"
    assert default_server.setting("max_replication_slots") == "10"
    assert default_server.setting("max_locks_per_transaction") == "128"
    assert "wal2json" in default_server.setting("output_plugin_libraries")
    if image.postgis >= (3, 7):
        assert default_server.setting("track_commit_timestamp") == "off"
        assert default_server.setting("max_worker_processes") == "8"
    else:
        assert default_server.setting("cron.database_name") == ALL_DATABASE
        assert default_server.setting("timescaledb.telemetry_level") == "off"
        assert default_server.setting("pg_show_plans.is_enabled") == "off"
        assert default_server.setting("track_commit_timestamp") == "on"
        preloaded = set(default_server.preloaded())
        workers = sum(library.workers for library in load_registry() if library.name in preloaded)
        assert int(default_server.setting("max_worker_processes")) == 8 + workers


def test_enabled_library_settings(all_server: Server) -> None:
    """Enabling libraries brings the settings they rely on."""
    assert all_server.setting("cron.database_name") == ALL_DATABASE
    assert all_server.setting("pg_partman_bgw.dbname") == ALL_DATABASE
    assert all_server.setting("timescaledb.telemetry_level") == "off"
    assert all_server.setting("pg_show_plans.is_enabled") == "off"
    assert all_server.setting("track_commit_timestamp") == "on"
    preloaded = set(all_server.preloaded())
    workers = sum(library.workers for library in load_registry() if library.name in preloaded)
    assert int(all_server.setting("max_worker_processes")) >= 8 + workers


def test_pg_cron_database_variable(image: Image) -> None:
    """PG_CRON_DB picks pg_cron's database."""
    server = start_server(
        image,
        env={
            "SHARED_PRELOAD_LIBRARIES": "pg_cron",
            "POSTGRES_DB": "app",
            "PG_CRON_DB": "postgres",
        },
    )
    try:
        assert server.setting("cron.database_name") == "postgres"
    finally:
        server.remove()


def test_no_remote_trust_authentication(default_server: Server) -> None:
    """pg_hba.conf trusts local connections only (the old PoWA setup trusted any IPv4 host)."""
    hba = default_server.exec("bash", "-c", 'cat "$PGDATA/pg_hba.conf"').stdout
    trusted_remote = [
        line
        for line in hba.splitlines()
        if re.match(r"\s*host", line)
        and line.split()[-1] == "trust"
        and line.split()[3] not in {"127.0.0.1/32", "::1/128"}
    ]
    assert not trusted_remote
