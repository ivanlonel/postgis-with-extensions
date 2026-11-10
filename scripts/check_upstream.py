"""
Compare the maintained postgis/postgis Debian tags with the build matrix.

CI runs it weekly: it fails when upstream maintains a tag the matrix doesn't build, or stopped
updating one it does, so the matrix keeps following upstream.
"""

from __future__ import annotations

import json
import re
import sys
import urllib.request
from datetime import UTC, datetime, timedelta
from typing import TYPE_CHECKING, Final

from scripts.manifest import matrix_majors, matrix_postgis

if TYPE_CHECKING:
    from collections.abc import Iterator

TAGS_URL: Final = (
    "https://hub.docker.com/v2/namespaces/postgis/repositories/postgis/tags?page_size=100"
)
"""First page of the postgis/postgis tag listing."""

DEBIAN_TAG: Final = re.compile(r"(?P<major>\d+)-(?P<postgis>\d+\.\d+)")
"""Debian-based release tags, such as ``18-3.7``."""

MAINTAINED_WITHIN: Final = timedelta(days=21)
"""How recently upstream must have pushed a tag for it to count as maintained."""


def iter_tags(url: str = TAGS_URL) -> Iterator[tuple[str, datetime]]:
    """
    List every postgis/postgis tag with its last update time.

    :param url: The first page of the listing.
    :yield: ``(tag, last_updated)`` pairs.
    :raise ValueError: If a pagination link leaves Docker Hub.
    """
    next_url: str | None = url
    while next_url:
        if not next_url.startswith("https://hub.docker.com/"):
            msg = f"unexpected pagination URL: {next_url}"
            raise ValueError(msg)
        with urllib.request.urlopen(next_url, timeout=60) as response:  # noqa: S310 -- https URL checked above
            page = json.load(response)
        for tag in page["results"]:
            yield tag["name"], datetime.fromisoformat(tag["last_updated"])
        next_url = page.get("next")


def maintained_tags(now: datetime) -> set[tuple[int, str]]:
    """
    Collect the Debian tags upstream updated recently.

    :param now: The reference time.
    :return: ``(PostgreSQL major, PostGIS major.minor)`` pairs.
    """
    return {
        (int(match["major"]), match["postgis"])
        for name, updated in iter_tags()
        if (match := DEBIAN_TAG.fullmatch(name)) and now - updated <= MAINTAINED_WITHIN
    }


def main() -> int:
    """
    Report differences between upstream and the build matrix.

    :return: ``1`` when they differ, ``0`` otherwise.
    """
    postgis = matrix_postgis()
    built = {(major, postgis) for major in matrix_majors()}
    upstream = maintained_tags(datetime.now(UTC))
    missing = sorted(upstream - built)
    stale = sorted(built - upstream)
    for major, version in missing:
        print(
            f"upstream maintains postgis/postgis:{major}-{version}, which the matrix doesn't build"
        )
    for major, version in stale:
        print(f"the matrix builds {major}-{version}, which upstream no longer updates")
    if missing or stale:
        print("Update PG_MAJORS / POSTGIS_VERSION / LATEST in docker-bake.hcl to follow upstream.")
        return 1
    print(f"The matrix matches upstream: {', '.join(f'{m}-{v}' for m, v in sorted(built))}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
