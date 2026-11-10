"""Shared fixtures: the image under test and the servers started from it."""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING, Final

import pytest

from scripts.manifest import load_baseline, load_manifest, provided_extensions
from tests._docker import Image, start_server

if TYPE_CHECKING:
    from collections.abc import Iterator

    from tests._docker import Server

TESTS_DIR: Final = Path(__file__).resolve().parent
"""Directory of the test suite."""

SQL_DIR: Final = TESTS_DIR / "sql"
"""Per-extension SQL scripts, mounted at ``/tests/sql`` in the servers."""

ALL_DATABASE: Final = "extensions"
"""``POSTGRES_DB`` of the server preloading everything, which is also its pg_cron database."""


def pytest_addoption(parser: pytest.Parser) -> None:
    """
    Register the command-line options of the suite.

    :param parser: The pytest option parser.
    """
    group = parser.getgroup("postgis-with-extensions")
    group.addoption("--image", help="reference of the image under test (a local image)")
    group.addoption(
        "--old-image",
        help="image to upgrade from (default: the one pinned in tests/upgrade/old-images.toml)",
    )
    group.addoption(
        "--strict-drift",
        action="store_true",
        help="fail, instead of warning, when the image ships extensions the manifest doesn't list",
    )


def _image_reference(config: pytest.Config) -> str | None:
    reference = config.getoption("--image")
    return reference if isinstance(reference, str) else None


def expected_extensions(image: Image) -> set[str]:
    """
    List the extensions the image must offer: the pre-rewrite baseline plus the manifest.

    :param image: The image under test.
    :return: The extension names.
    """
    baseline = load_baseline(image.pg_major) or {}
    return set(baseline) | provided_extensions(load_manifest(), image.pg_major)


def pytest_generate_tests(metafunc: pytest.Metafunc) -> None:
    """
    Parametrize ``extension_name`` with every extension the image under test must offer.

    :param metafunc: The test function being collected.
    """
    if "extension_name" not in metafunc.fixturenames:
        return
    reference = _image_reference(metafunc.config)
    names = sorted(expected_extensions(Image.inspect(reference))) if reference else []
    metafunc.parametrize("extension_name", names)


@pytest.fixture(scope="session")
def image(pytestconfig: pytest.Config) -> Image:
    """
    Describe the image under test.

    :param pytestconfig: The pytest configuration.
    :return: The image description.
    """
    reference = _image_reference(pytestconfig)
    if reference is None:
        pytest.skip("pass --image to run tests against an image")
    return Image.inspect(reference)


@pytest.fixture(scope="session")
def default_server(image: Image) -> Iterator[Server]:
    """
    Run the image with its default configuration.

    :param image: The image under test.
    :yield: The running server.
    """
    server = start_server(image, mounts={str(SQL_DIR): "/tests/sql"})
    yield server
    server.remove()


@pytest.fixture(scope="session")
def all_server(image: Image) -> Iterator[Server]:
    """
    Run the image with every preloadable library enabled.

    :param image: The image under test.
    :yield: The running server.
    """
    server = start_server(
        image,
        env={"SHARED_PRELOAD_LIBRARIES": "all", "POSTGRES_DB": ALL_DATABASE},
        mounts={str(SQL_DIR): "/tests/sql"},
    )
    yield server
    server.remove()
