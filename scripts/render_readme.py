"""
Render the extension table of README.md from extensions.toml.

Run ``uv run python -m scripts.render_readme`` after editing the manifest; ``--check`` only reports
whether README.md is up to date.
"""

from __future__ import annotations

import argparse
import sys
from typing import TYPE_CHECKING, Final

from scripts.manifest import ROOT, load_manifest, matrix_majors

if TYPE_CHECKING:
    from collections.abc import Iterable, Sequence

    from scripts.manifest import Extension

README_PATH: Final = ROOT / "README.md"
"""The README to update."""

START: Final = "<!-- extensions:start -->"
"""Marker preceding the generated table."""

END: Final = "<!-- extensions:end -->"
"""Marker following the generated table."""

DOCKER_HUB_LIMIT: Final = 25_000
"""Maximum length of a Docker Hub repository description."""


def describe_majors(extension: Extension, majors: Sequence[int]) -> str:
    """
    Describe the PostgreSQL majors an extension ships for, relative to the build matrix.

    :param extension: The manifest entry.
    :param majors: The PostgreSQL majors of the build matrix, in ascending order.
    :return: ``all``, ``<first>+``, ``up to <last>`` or ``<first>-<last>``.
    :raise ValueError: If the extension ships for none of the majors.
    """
    shipped = [major for major in majors if extension.ships_for(major)]
    if not shipped:
        msg = f"{extension.name} ships for none of {list(majors)}"
        raise ValueError(msg)
    if shipped == list(majors):
        return "all"
    if shipped[-1] == majors[-1]:
        return f"{shipped[0]}+"
    if shipped[0] == majors[0]:
        return f"up to {shipped[-1]}"
    return f"{shipped[0]}-{shipped[-1]}"


def render_table(extensions: Iterable[Extension], majors: Sequence[int]) -> str:
    """
    Render the manifest as a compact Markdown table, in the format mdformat keeps.

    :param extensions: The manifest entries.
    :param majors: The PostgreSQL majors of the build matrix, in ascending order.
    :return: The table, without a trailing newline.
    """
    rows = ["| Extension | PostgreSQL | Preload | Notes |", "| -- | -- | -- | -- |"]
    for extension in sorted(extensions, key=lambda entry: entry.name.casefold()):
        cells = (
            f"[{extension.name}]({extension.url})",
            describe_majors(extension, majors),
            f"`{extension.preload}`" if extension.preload else "",
            extension.note or "",
        )
        rows.append("| " + " | ".join(cells) + " |")
    return "\n".join(rows)


def render_readme(readme: str, table: str) -> str:
    """
    Replace the generated section of the README.

    :param readme: The current README.
    :param table: The rendered table.
    :return: The updated README.
    :raise ValueError: If the README lacks the start or end marker.
    """
    head, start, rest = readme.partition(START)
    _, end, tail = rest.partition(END)
    if not start or not end:
        msg = f"README.md must contain {START} and {END}"
        raise ValueError(msg)
    return f"{head}{START}\n\n{table}\n\n{END}{tail}"


def main(argv: Sequence[str] | None = None) -> int:
    """
    Update README.md, or check that it is up to date.

    :param argv: Command-line arguments (defaults to :data:`sys.argv`).
    :return: The exit status.
    """
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--check", action="store_true", help="report instead of writing when README.md is outdated"
    )
    args = parser.parse_args(argv)

    current = README_PATH.read_text(encoding="utf-8")
    rendered = render_readme(current, render_table(load_manifest(), matrix_majors()))
    if len(rendered) > DOCKER_HUB_LIMIT:
        print(f"README.md has {len(rendered)} characters; Docker Hub accepts {DOCKER_HUB_LIMIT}.")
        return 1
    if rendered == current:
        return 0
    if args.check:
        print("README.md is outdated: run `uv run python -m scripts.render_readme`.")
        return 1
    README_PATH.write_text(rendered, encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
