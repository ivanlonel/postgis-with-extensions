"""
Run the per-extension SQL scripts of ``tests/sql``.

Each script runs twice: on a server preloading only what it needs (the default server when that's
nothing), which proves the extension works on its own, and on the ``all`` server, which proves it
works alongside every other preloadable library. A script runs with ``ON_ERROR_STOP`` in a scratch
database with pgTAP and ``tests/sql/lib/helpers.sql`` installed, so any error fails it; pgTAP plans
end with ``finish(true)``, which raises when an assertion failed. Leading comment lines can
restrict where a script runs:

``-- preload: <library>[, <library>...]``
    Libraries the server must preload (the ones they require come along).
``-- conflicts: <library>[, <library>...]``
    Skip on servers preloading any of these, which keep the extension from working.
``-- pg: <constraints>``
    Skip unless the PostgreSQL major matches, e.g. ``<=17``.
``-- database: cron|partman|net|sentinel``
    Run in the database a background worker uses (pg_cron's, pg_partman's, pg_net's or
    pgsentinel's) instead of a scratch one.

Scripts can fetch the files of ``tests/sql/data`` from ``http://127.0.0.1:8000/``; the scripts'
directory is mounted at ``/tests/sql``, so server-side functions can read it too.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import TYPE_CHECKING, Final, Literal, Self

import pytest

from scripts.manifest import MajorRange
from tests.conftest import SQL_DIR

if TYPE_CHECKING:
    from pathlib import Path

    from tests._docker import Image, Server
    from tests.conftest import ServerPool

_DIRECTIVE: Final = re.compile(r"--\s*(?P<key>preload|conflicts|pg|database):\s*(?P<value>.*?)\s*")

HELPERS: Final = "/tests/sql/lib/helpers.sql"
"""Functions installed in every database a script runs in."""

WORKER_DATABASES: Final = {
    "cron": "cron.database_name",
    "partman": "pg_partman_bgw.dbname",
    "net": "pg_net.database_name",
    "sentinel": "pgsentinel.db_name",
}
"""Values of the ``database`` directive, mapped to the setting naming that database."""


def _libraries(value: str | None) -> frozenset[str]:
    return frozenset(filter(None, re.split(r"[,\s]+", value or "")))


@dataclass(frozen=True, slots=True, kw_only=True)
class SqlScript:
    """A SQL test script and the conditions under which it runs."""

    path: Path
    """The script file."""

    preload: frozenset[str]
    """Libraries the server must preload."""

    conflicts: frozenset[str]
    """Preloaded libraries that keep the extension from working."""

    majors: MajorRange
    """PostgreSQL majors to run on."""

    database_setting: str | None
    """Setting naming the database to run in, or ``None`` for a scratch database."""

    @classmethod
    def parse(cls, path: Path) -> Self:
        """
        Read a script's leading directive comments.

        :param path: The script file.
        :return: The script description.
        :raise ValueError: If a directive has an unsupported value.
        """
        directives: dict[str, str] = {}
        for line in path.read_text(encoding="utf-8").splitlines():
            match = _DIRECTIVE.fullmatch(line)
            if match is None:
                break
            directives[match["key"]] = match["value"]
        database = directives.get("database")
        if database is not None and database not in WORKER_DATABASES:
            msg = f"{path.name}: unsupported database directive {database!r}"
            raise ValueError(msg)
        return cls(
            path=path,
            preload=_libraries(directives.get("preload")),
            conflicts=_libraries(directives.get("conflicts")),
            majors=MajorRange.parse(directives.get("pg")),
            database_setting=WORKER_DATABASES[database] if database else None,
        )


SCRIPTS: Final = [SqlScript.parse(path) for path in sorted(SQL_DIR.glob("*.sql"))]
"""Every SQL test script."""


def _run(server: Server, script: SqlScript, database: str) -> None:
    server.query("CREATE EXTENSION IF NOT EXISTS pgtap", database=database)
    helpers = server.psql("--file", HELPERS, database=database)
    assert helpers.returncode == 0, helpers.stderr
    process = server.psql("--file", f"/tests/sql/{script.path.name}", database=database)
    assert process.returncode == 0, f"{process.stdout}\n{process.stderr}"


@pytest.mark.parametrize("server_kind", ["own", "all"])
@pytest.mark.parametrize("script", SCRIPTS, ids=[script.path.stem for script in SCRIPTS])
def test_sql_script(
    request: pytest.FixtureRequest,
    image: Image,
    server_pool: ServerPool,
    server_kind: Literal["own", "all"],
    script: SqlScript,
) -> None:
    """The script passes on a server preloading what it needs, and alongside everything else."""
    if image.pg_major not in script.majors:
        pytest.skip(f"not shipped for PostgreSQL {image.pg_major}")
    server: Server
    if server_kind == "all":
        server = request.getfixturevalue("all_server")
        if missing := sorted(script.preload - set(server.preloaded())):
            pytest.skip(f"the all preset leaves out {', '.join(missing)}")
    elif script.preload:
        server = server_pool.get(script.preload)
    else:
        server = request.getfixturevalue("default_server")
    if conflicting := sorted(script.conflicts & set(server.preloaded())):
        pytest.skip(f"doesn't work alongside {', '.join(conflicting)}")
    if script.database_setting is not None:
        _run(server, script, server.setting(script.database_setting))
    else:
        with server.database() as database:
            _run(server, script, database)
