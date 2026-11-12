"""
Render the extension tables of README.md from extensions.toml.

Run ``uv run python -m scripts.render_readme`` after editing the manifest; ``--check`` only reports
whether README.md is up to date, and ``--dockerhub PATH`` writes the copy of the README Docker Hub
shows, which leaves out the Development section to stay within Docker Hub's size limit.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import TYPE_CHECKING, Final

from scripts.manifest import ROOT, load_manifest, matrix_majors

if TYPE_CHECKING:
    from collections.abc import Iterable, Sequence

    from scripts.manifest import Extension

README_PATH: Final = ROOT / "README.md"
"""The README to update."""

START: Final = "<!-- extensions:start -->"
"""Marker preceding the generated table of the extensions every image ships."""

END: Final = "<!-- extensions:end -->"
"""Marker following the generated table of the extensions every image ships."""

EXTENDED_START: Final = "<!-- extended:start -->"
"""Marker preceding the generated table of the extensions only the extended images ship."""

EXTENDED_END: Final = "<!-- extended:end -->"
"""Marker following the generated table of the extensions only the extended images ship."""

DOCKER_HUB_LIMIT: Final = 25_000
"""Maximum length of a Docker Hub repository description."""

DOCKER_HUB_SKIPPED: Final = "## Development"
"""Heading of the README section the Docker Hub copy leaves out (up to the next heading)."""


def describe_majors(extension: Extension, majors: Sequence[int]) -> str:
    """
    Describe the PostgreSQL majors an extension ships for, relative to the build matrix.

    :param extension: The manifest entry.
    :param majors: The PostgreSQL majors of the build matrix, in ascending order.
    :return: ``all``, ``<first>+``, ``up to <last>`` or ``<first>-<last>``.
    :raise ValueError: If the extension ships for none of the majors.
    """
    shipped = [major for major in majors if major in extension.majors]
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
    Render manifest entries as a compact Markdown table, in the format mdformat keeps.

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


def replace_section(text: str, start: str, end: str, content: str) -> str:
    """
    Replace what lies between two markers.

    :param text: The document.
    :param start: The marker preceding the section.
    :param end: The marker following the section.
    :param content: The new section content.
    :return: The updated document.
    :raise ValueError: If the document lacks either marker.
    """
    head, found_start, rest = text.partition(start)
    _, found_end, tail = rest.partition(end)
    if not found_start or not found_end:
        msg = f"README.md must contain {start} and {end}"
        raise ValueError(msg)
    return f"{head}{start}\n\n{content}\n\n{end}{tail}"


def render_readme(readme: str, table: str, extended_table: str) -> str:
    """
    Replace the generated sections of the README.

    :param readme: The current README.
    :param table: The rendered table of the extensions every image ships.
    :param extended_table: The rendered table of the extensions only the extended images ship.
    :return: The updated README.
    """
    readme = replace_section(readme, START, END, table)
    return replace_section(readme, EXTENDED_START, EXTENDED_END, extended_table)


def dockerhub_copy(readme: str) -> str:
    """
    Derive the README copy Docker Hub shows, without the section it doesn't need.

    :param readme: The README.
    :return: The README without its Development section.
    :raise ValueError: If the README lacks that section.
    """
    head, found, rest = readme.partition(f"\n{DOCKER_HUB_SKIPPED}\n")
    if not found:
        msg = f"README.md must contain a {DOCKER_HUB_SKIPPED!r} section"
        raise ValueError(msg)
    _, next_heading, tail = rest.partition("\n## ")
    return f"{head}{next_heading}{tail}" if next_heading else f"{head.rstrip()}\n"


def main(argv: Sequence[str] | None = None) -> int:
    """
    Update README.md, or check that it is up to date; optionally write the Docker Hub copy.

    :param argv: Command-line arguments (defaults to :data:`sys.argv`).
    :return: The exit status.
    """
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    parser.add_argument(
        "--check", action="store_true", help="report instead of writing when README.md is outdated"
    )
    parser.add_argument(
        "--dockerhub", type=Path, metavar="PATH", help="also write the Docker Hub copy to PATH"
    )
    args = parser.parse_args(argv)

    manifest = load_manifest()
    majors = matrix_majors()
    current = README_PATH.read_text(encoding="utf-8")
    rendered = render_readme(
        current,
        render_table((entry for entry in manifest if not entry.extended), majors),
        render_table((entry for entry in manifest if entry.extended), majors),
    )
    hub = dockerhub_copy(rendered)
    if len(hub) > DOCKER_HUB_LIMIT:
        print(
            f"The Docker Hub copy of README.md has {len(hub)} characters;"
            f" Docker Hub accepts {DOCKER_HUB_LIMIT}."
        )
        return 1
    if args.dockerhub is not None:
        args.dockerhub.write_text(hub, encoding="utf-8", newline="\n")
    if rendered == current:
        return 0
    if args.check:
        print("README.md is outdated: run `uv run python -m scripts.render_readme`.")
        return 1
    README_PATH.write_text(rendered, encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
