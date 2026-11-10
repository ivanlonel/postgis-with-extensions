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


def test_extension_can_be_created(all_server: Server, extension_name: str) -> None:
    """
    Create the extension, with its requirements, in a transaction that is rolled back.

    The extension database is also pg_cron's, which pg_cron and DocumentDB require. Rolling back
    keeps the extensions from conflicting with one another.
    """
    if extension_name in UNCREATABLE:
        pytest.skip(UNCREATABLE[extension_name])
    process = all_server.psql(
        "--command",
        f'BEGIN; CREATE EXTENSION IF NOT EXISTS "{extension_name}" CASCADE; ROLLBACK;',
        database=ALL_DATABASE,
    )
    assert process.returncode == 0, process.stderr
