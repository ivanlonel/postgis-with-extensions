"""Every extension the image offers can be created, with all preloadable libraries loaded."""

from __future__ import annotations

from typing import TYPE_CHECKING, Final

import pytest

from tests.conftest import ALL_DATABASE

if TYPE_CHECKING:
    from tests._docker import Server

UNCREATABLE: Final = {
    "documentdb_distributed": "needs Citus, which the image doesn't ship",
}
"""Extensions that can't be created on purpose, with the reason."""


@pytest.fixture(scope="module")
def without_scripts(all_server: Server) -> set[str]:
    """
    Find the extensions offered without any installation script.

    PostGIS's ``-3`` aliases (``postgis-3`` and the like) are such: they only serve upgrades.

    :param all_server: The server preloading everything.
    :return: The extension names.
    """
    return set(
        all_server.query(
            "SELECT name FROM pg_available_extensions AS e WHERE NOT EXISTS"
            " (SELECT FROM pg_available_extension_versions AS v WHERE v.name = e.name)"
        )
    )


@pytest.fixture(scope="module")
def versions_to_choose(all_server: Server) -> dict[str, str]:
    """
    Find the extensions whose control file names no default version, such as pg_proctab's.

    :param all_server: The server preloading everything.
    :return: Those extensions, mapped to their newest version.
    """
    rows = all_server.query(
        "SELECT name, max(version) FROM pg_available_extension_versions"
        " WHERE name IN (SELECT name FROM pg_available_extensions WHERE default_version IS NULL)"
        " GROUP BY name"
    )
    return dict(row.split("|", 1) for row in rows)


def test_extension_can_be_created(
    all_server: Server,
    without_scripts: set[str],
    versions_to_choose: dict[str, str],
    extension_name: str,
) -> None:
    """
    Create the extension, with its requirements, in a transaction that is rolled back.

    The extension database is also pg_cron's, which pg_cron and DocumentDB require. Rolling back
    keeps the extensions from conflicting with one another.
    """
    if extension_name in UNCREATABLE:
        pytest.skip(UNCREATABLE[extension_name])
    if extension_name.endswith("-3") and extension_name in without_scripts:
        pytest.skip("PostGIS's upgrade-only alias, which has no installation script")
    version = versions_to_choose.get(extension_name)
    clause = f" VERSION '{version}'" if version else ""
    process = all_server.psql(
        "--command",
        f'BEGIN; CREATE EXTENSION IF NOT EXISTS "{extension_name}"{clause} CASCADE; ROLLBACK;',
        database=ALL_DATABASE,
    )
    assert process.returncode == 0, process.stderr
