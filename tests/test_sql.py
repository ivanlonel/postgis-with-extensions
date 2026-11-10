"""
Run the per-extension SQL scripts of ``tests/sql``.

Each script runs with ``ON_ERROR_STOP`` in a scratch database that has pgTAP installed, so any
error fails it; pgTAP plans end with ``finish(true)``, which raises when an assertion failed.
Leading comment lines can restrict where a script runs:

``-- preload: <library>[, <library>...]``
    Skip unless the server preloads all these libraries.
``-- pg: <constraints>``
    Skip unless the PostgreSQL major matches, e.g. ``<=17``.
``-- database: cron``
    Run in pg_cron's database instead of a scratch one.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import TYPE_CHECKING, Final, Self

import pytest

from scripts.manifest import MajorRange
from tests.conftest import SQL_DIR

if TYPE_CHECKING:
    from pathlib import Path

    from tests._docker import Image, Server

_DIRECTIVE: Final = re.compile(r"--\s*(?P<key>preload|pg|database):\s*(?P<value>.*?)\s*")


@dataclass(frozen=True, slots=True, kw_only=True)
class SqlScript:
    """A SQL test script and the conditions under which it runs."""

    path: Path
    """The script file."""

    preload: frozenset[str]
    """Libraries the server must preload."""

    majors: MajorRange
    """PostgreSQL majors to run on."""

    in_cron_database: bool
    """Whether to run in pg_cron's database instead of a scratch one."""

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
        if database not in {None, "cron"}:
            msg = f"{path.name}: unsupported database directive {database!r}"
            raise ValueError(msg)
        return cls(
            path=path,
            preload=frozenset(filter(None, re.split(r"[,\s]+", directives.get("preload", "")))),
            majors=MajorRange.parse(directives.get("pg")),
            in_cron_database=database == "cron",
        )


SCRIPTS: Final = [SqlScript.parse(path) for path in sorted(SQL_DIR.glob("*.sql"))]
"""Every SQL test script."""


def _run(server: Server, script: SqlScript, database: str) -> None:
    process = server.psql("--file", f"/tests/sql/{script.path.name}", database=database)
    assert process.returncode == 0, f"{process.stdout}\n{process.stderr}"


@pytest.mark.parametrize("server_kind", ["default", "all"])
@pytest.mark.parametrize("script", SCRIPTS, ids=[script.path.stem for script in SCRIPTS])
def test_sql_script(
    request: pytest.FixtureRequest, image: Image, server_kind: str, script: SqlScript
) -> None:
    """The script runs without errors, on the default server and on the preload-everything one."""
    if image.pg_major not in script.majors:
        pytest.skip(f"not shipped for PostgreSQL {image.pg_major}")
    server: Server = request.getfixturevalue(f"{server_kind}_server")
    if missing := sorted(script.preload - set(server.preloaded())):
        pytest.skip(f"needs {', '.join(missing)} preloaded")
    if script.in_cron_database:
        database = server.setting("cron.database_name")
        server.query("CREATE EXTENSION IF NOT EXISTS pgtap", database=database)
        _run(server, script, database)
    else:
        with server.database() as database:
            _run(server, script, database)
