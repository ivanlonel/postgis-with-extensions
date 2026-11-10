"""
Clusters created by the previously published image keep working with the image under test.

The previous image creates every extension it offers, each in a database of its own, plus the
objects of ``upgrade/seed.sql``. The image under test then starts on the same volume.
"""

from __future__ import annotations

import tomllib
from dataclasses import dataclass
from typing import TYPE_CHECKING, Final

import pytest

from tests._docker import Image, docker, scratch_volume, start_server
from tests.conftest import TESTS_DIR

if TYPE_CHECKING:
    from collections.abc import Iterator

    from tests._docker import Server

UPGRADE_DIR: Final = TESTS_DIR / "upgrade"
"""Seed and verification scripts, mounted at ``/tests/upgrade``."""

NOT_SEEDED: Final = {
    "pg_cron": "can only be created in cron.database_name",
}
"""Extensions the seeding skips, with the reason."""


@dataclass(frozen=True, slots=True, kw_only=True)
class Upgrade:
    """The image under test, running on a cluster the previous image created."""

    server: Server
    """The server started from the image under test."""

    volume: str
    """The cluster's volume."""

    seeded: dict[str, str]
    """Extensions the previous image created, mapped to their databases."""

    preloaded: list[str]
    """shared_preload_libraries under the previous image."""


def _old_image_reference(image: Image, config: pytest.Config) -> str:
    reference = config.getoption("--old-image")
    if isinstance(reference, str) and reference:
        return reference
    with (UPGRADE_DIR / "old-images.toml").open("rb") as file:
        pinned = tomllib.load(file)
    if str(image.pg_major) not in pinned:
        pytest.skip(f"no previous image for PostgreSQL {image.pg_major}")
    return pinned[str(image.pg_major)]


def _library_path(probin: str, libdir: str) -> str:
    """
    Resolve a ``pg_proc.probin`` value the way the server's dynamic loader does.

    :param probin: The library a C function lives in: ``$libdir/name``, a bare name looked up in
        ``dynamic_library_path`` (``$libdir`` by default), or an absolute path.
    :param libdir: The server's library directory.
    :return: The shared library's file path.
    """
    path = probin.replace("$libdir", libdir)
    if "/" not in path:
        path = f"{libdir}/{path}"
    return path if path.endswith(".so") else f"{path}.so"


def _seed(server: Server) -> dict[str, str]:
    """
    Create every available extension in a database of its own.

    :param server: The server running the previous image.
    :return: The extensions created, mapped to their databases.
    """
    names = [
        name
        for name in server.query("SELECT name FROM pg_available_extensions ORDER BY name")
        if name not in NOT_SEEDED
    ]
    script = "\n".join(
        f'CREATE DATABASE "u_{name}";\n\\connect "u_{name}"\n'
        f'CREATE EXTENSION IF NOT EXISTS "{name}" CASCADE;\n\\connect postgres'
        for name in names
    )
    # Without ON_ERROR_STOP: an extension the previous image couldn't create alone is just skipped.
    server.exec("psql", "--no-psqlrc", "--quiet", "--dbname", "postgres", stdin=script)
    report = "\n".join(
        f"\\connect \"u_{name}\"\nSELECT '{name}' FROM pg_extension WHERE extname = '{name}';"
        for name in names
    )
    created = server.exec(
        "psql", "--no-psqlrc", "--quiet", "-At", "--dbname", "postgres", stdin=report
    )
    return {name: f"u_{name}" for name in created.stdout.split()}


@pytest.fixture(scope="module")
def upgrade(image: Image, pytestconfig: pytest.Config) -> Iterator[Upgrade]:
    """
    Create a cluster with the previous image, then start the image under test on it.

    :param image: The image under test.
    :param pytestconfig: The pytest configuration.
    :yield: The upgraded server and what the previous image left behind.
    """
    reference = _old_image_reference(image, pytestconfig)
    docker("pull", reference)
    mounts = {str(UPGRADE_DIR): "/tests/upgrade"}
    with scratch_volume() as volume:
        old = start_server(Image.inspect(reference), role="old", volume=volume, mounts=mounts)
        try:
            seeded = _seed(old)
            old.query("CREATE DATABASE upgrade")
            process = old.psql("--file", "/tests/upgrade/seed.sql", database="upgrade")
            assert process.returncode == 0, process.stderr
            preloaded = old.preloaded()
            old.stop()
        finally:
            old.remove()
        new = start_server(image, role="new", volume=volume, mounts=mounts)
        try:
            yield Upgrade(server=new, volume=volume, seeded=seeded, preloaded=preloaded)
        finally:
            new.remove()


def test_preloaded_libraries_are_kept(upgrade: Upgrade) -> None:
    """The new image preloads exactly what the cluster's configuration says, as before."""
    assert upgrade.server.preloaded() == upgrade.preloaded


def test_referenced_libraries_exist(upgrade: Upgrade) -> None:
    """Every shared library the existing databases' functions point to is still installed."""
    allowed = {
        line.strip()
        for line in (UPGRADE_DIR / "allowed-breaks.txt").read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.startswith("#")
    }
    script = "\n".join(
        f'\\connect "{database}"\n'
        f"SELECT DISTINCT '{name}', probin FROM pg_proc WHERE probin IS NOT NULL;"
        for name, database in upgrade.seeded.items()
    )
    rows = upgrade.server.exec(
        "psql", "--no-psqlrc", "--quiet", "-At", "--dbname", "postgres", stdin=script
    ).stdout.splitlines()
    libdir = upgrade.server.image.libdir
    references = {tuple(row.split("|", 1)) for row in rows if "|" in row}
    paths = {(name, _library_path(probin, libdir)) for name, probin in references}
    present = set(
        upgrade.server.exec(
            "bash",
            "-c",
            'for path; do [[ -e "$path" ]] && echo "$path"; done; true',
            "_",
            *sorted({path for _, path in paths}),
        ).stdout.split()
    )
    missing = sorted(
        (name, path) for name, path in paths if path not in present and name not in allowed
    )
    assert not missing, f"libraries referenced by existing databases are gone: {missing}"


def test_seeded_objects_work(upgrade: Upgrade) -> None:
    """The objects created with the previous image can be used."""
    process = upgrade.server.psql("--file", "/tests/upgrade/verify.sql", database="upgrade")
    assert process.returncode == 0, f"{process.stdout}\n{process.stderr}"


def test_variable_adds_to_the_existing_list(upgrade: Upgrade, image: Image) -> None:
    """
    SHARED_PRELOAD_LIBRARIES adds to the cluster's own list without dropping anything.

    The extended list names each library once, though the old configuration may repeat some.
    """
    upgrade.server.stop()
    server = start_server(
        image,
        role="extended",
        volume=upgrade.volume,
        env={"SHARED_PRELOAD_LIBRARIES": "pg_stat_monitor"},
    )
    try:
        assert server.preloaded() == [*dict.fromkeys(upgrade.preloaded), "pg_stat_monitor"]
    finally:
        server.remove()
