"""Shared fixtures: the image under test and the servers started from it."""

from __future__ import annotations

from dataclasses import dataclass, field
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
"""``POSTGRES_DB`` of the servers running the SQL scripts, which is also their pg_cron database."""

HTTP_PORT: Final = 8000
"""Port of the HTTP server that serves ``tests/sql/data`` inside the servers, on 127.0.0.1."""

EMBEDDINGS_PORT: Final = 8001
"""Port of the fake embeddings service (``tests/sql/lib/embeddings.py``) in extended servers."""

EMBEDDINGS_OPTIONS: Final = (
    "-c",
    f"vectorize.embedding_service_url=http://127.0.0.1:{EMBEDDINGS_PORT}/v1",
)
"""
Server options pointing pg_vectorize's ``sentence-transformers/*`` models at the fake service.

Its background worker never reloads the configuration, so they're set at server start. (Its
OpenAI models can't be faked: it checks their API key against api.openai.com.)
"""


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
    return set(baseline) | provided_extensions(
        load_manifest(), image.pg_major, extended=image.extended
    )


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


def start_sql_server(image: Image, *, role: str, preload: str | None = None) -> Server:
    """
    Start a server for the SQL scripts: they're mounted, and their data is served over HTTP.

    pg_partman's background worker runs as the superuser. Its default role, partman_maintainer,
    doesn't exist on these servers, and a worker that fails to launch maintenance as that role can
    give up before a script gets to change the setting. Extended images also get a fake embeddings
    service, which pg_vectorize is pointed at.

    :param image: The image to run.
    :param role: Short name for what the server is for.
    :param preload: ``SHARED_PRELOAD_LIBRARIES``, if any.
    :return: The running server.
    """
    env = {"POSTGRES_DB": ALL_DATABASE}
    if preload:
        env["SHARED_PRELOAD_LIBRARIES"] = preload
    server = start_server(
        image,
        role=role,
        env=env,
        mounts={str(SQL_DIR): "/tests/sql"},
        command=[
            "postgres",
            "-c",
            "pg_partman_bgw.role=postgres",
            *(EMBEDDINGS_OPTIONS if image.extended else ()),
        ],
    )
    if image.extended:
        server.spawn("python3", "/tests/sql/lib/embeddings.py", str(EMBEDDINGS_PORT))
    server.spawn(
        "python3",
        "-m",
        "http.server",
        str(HTTP_PORT),
        "--bind",
        "127.0.0.1",
        "--directory",
        "/tests/sql/data",
    )
    return server


@dataclass(slots=True)
class ServerPool:
    """Servers preloading given sets of libraries, started on demand, one alive at a time."""

    image: Image
    """The image the servers run."""

    _current: tuple[frozenset[str], Server] | None = field(default=None, init=False)

    def get(self, preload: frozenset[str]) -> Server:
        """
        Get a server that preloads exactly these libraries (and those they require).

        :param preload: The libraries.
        :return: The running server, reused while the same set is asked for.
        """
        if self._current is not None and self._current[0] == preload:
            return self._current[1]
        self.close()
        role = "own." + ".".join(sorted(preload))[:40]
        server = start_sql_server(self.image, role=role, preload=",".join(sorted(preload)))
        self._current = (preload, server)
        return server

    def close(self) -> None:
        """Remove the server the pool holds, if any."""
        if self._current is not None:
            self._current[1].remove()
            self._current = None


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
    server = start_sql_server(image, role="default")
    yield server
    server.remove()


@pytest.fixture(scope="session")
def all_server(image: Image) -> Iterator[Server]:
    """
    Run the image with the ``all`` preset: every preloadable library but the opt-in ones.

    :param image: The image under test.
    :yield: The running server.
    """
    server = start_sql_server(image, role="all", preload="all")
    yield server
    server.remove()


@pytest.fixture(scope="session")
def server_pool(image: Image) -> Iterator[ServerPool]:
    """
    Provide servers preloading only what a test needs.

    :param image: The image under test.
    :yield: The pool.
    """
    pool = ServerPool(image)
    yield pool
    pool.close()
