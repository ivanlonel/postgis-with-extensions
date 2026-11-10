"""Loaders for the extension manifest, the preload registry, the baselines and the build matrix."""

from __future__ import annotations

import re
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING, Final, Self

if TYPE_CHECKING:
    from collections.abc import Iterable

ROOT: Final = Path(__file__).resolve().parent.parent
"""Repository root."""

MANIFEST_PATH: Final = ROOT / "extensions.toml"
"""The extension manifest."""

REGISTRY_PATH: Final = ROOT / "image/preload-libraries.txt"
"""The registry of libraries the image can preload."""

BASELINE_DIR: Final = ROOT / "tests/baseline"
"""Snapshots of ``pg_available_extensions`` taken from the images published before the rewrite."""

BAKE_PATH: Final = ROOT / "docker-bake.hcl"
"""The Bake build definition, which holds the PostgreSQL majors of the build matrix."""

_CONSTRAINT: Final = re.compile(r"(?P<operator>>=|<=)\s*(?P<major>\d+)")


@dataclass(frozen=True, slots=True, kw_only=True)
class MajorRange:
    """An inclusive range of PostgreSQL major versions; ``None`` bounds are open."""

    minimum: int | None = None
    """Lowest supported major, if bounded."""

    maximum: int | None = None
    """Highest supported major, if bounded."""

    @classmethod
    def parse(cls, spec: str | None) -> Self:
        """
        Parse a comma-separated constraint list such as ``">=15"`` or ``">=14, <=17"``.

        :param spec: The constraints, or ``None`` for an unbounded range.
        :return: The parsed range.
        :raise ValueError: If a constraint is malformed.
        """
        minimum: int | None = None
        maximum: int | None = None
        for constraint in (spec or "").split(","):
            if not constraint.strip():
                continue
            match = _CONSTRAINT.fullmatch(constraint.strip())
            if match is None:
                msg = f"invalid PostgreSQL major constraint: {constraint!r}"
                raise ValueError(msg)
            if match["operator"] == ">=":
                minimum = int(match["major"])
            else:
                maximum = int(match["major"])
        return cls(minimum=minimum, maximum=maximum)

    def __contains__(self, major: object) -> bool:
        """
        Tell whether a PostgreSQL major falls within the range.

        :param major: The major version to test.
        :return: Whether ``major`` is an :class:`int` within the bounds.
        """
        if not isinstance(major, int):
            return False
        return (self.minimum is None or major >= self.minimum) and (
            self.maximum is None or major <= self.maximum
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Extension:
    """A manifest entry: one project, which may provide several PostgreSQL extensions."""

    name: str
    """Display name."""

    url: str
    """Project home page."""

    provides: tuple[str, ...]
    """Names of the PostgreSQL extensions the project installs (may be empty)."""

    majors: MajorRange
    """PostgreSQL majors the image ships it for."""

    preload: str | None
    """Library to list in ``SHARED_PRELOAD_LIBRARIES`` to use it, if it needs one."""

    note: str | None
    """Remark shown in the README."""

    def ships_for(self, major: int) -> bool:
        """
        Tell whether the image ships the project for a PostgreSQL major.

        :param major: The PostgreSQL major version.
        :return: Whether ``major`` is within :attr:`majors`.
        """
        return major in self.majors


@dataclass(frozen=True, slots=True, kw_only=True)
class PreloadLibrary:
    """A registry entry: a library the entrypoint can add to ``shared_preload_libraries``."""

    name: str
    """Library name, as listed in ``shared_preload_libraries``."""

    legacy: bool
    """Whether the ``legacy`` preset (the pre-3.7 default) includes it."""

    requires: tuple[str, ...]
    """Libraries preloaded along with it."""

    workers: int
    """Background workers it may start."""

    settings: tuple[tuple[str, str], ...]
    """Settings the entrypoint applies when it adds the library, as ``(name, value)`` pairs."""


def load_manifest(path: Path = MANIFEST_PATH) -> tuple[Extension, ...]:
    """
    Load the extension manifest.

    :param path: The manifest file.
    :return: The entries, in manifest order.
    """
    with path.open("rb") as file:
        data = tomllib.load(file)
    return tuple(
        Extension(
            name=entry["name"],
            url=entry["url"],
            provides=tuple(entry.get("provides", [entry["name"]])),
            majors=MajorRange.parse(entry.get("pg")),
            preload=entry.get("preload"),
            note=entry.get("note"),
        )
        for entry in data["extension"]
    )


def load_registry(path: Path = REGISTRY_PATH) -> tuple[PreloadLibrary, ...]:
    """
    Load the preload registry.

    :param path: The registry file.
    :return: The libraries, in canonical order.
    :raise ValueError: If a line doesn't have the five ``|``-separated columns.
    """
    libraries: list[PreloadLibrary] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        columns = line.split("|")
        if len(columns) != 5:  # noqa: PLR2004 -- the registry's documented column count
            msg = f"malformed registry line: {line!r}"
            raise ValueError(msg)
        name, legacy, requires, workers, settings = columns
        libraries.append(
            PreloadLibrary(
                name=name,
                legacy=legacy == "yes",
                requires=tuple(filter(None, requires.split(","))),
                workers=int(workers or 0),
                settings=tuple(
                    (key, value)
                    for key, _, value in (item.partition("=") for item in settings.split(";"))
                    if key
                ),
            )
        )
    return tuple(libraries)


def load_baseline(major: int, directory: Path = BASELINE_DIR) -> dict[str, str] | None:
    """
    Load the extensions the pre-rewrite image offered for a PostgreSQL major.

    :param major: The PostgreSQL major version.
    :param directory: The directory holding the ``pg<major>.txt`` snapshots.
    :return: Extension names mapped to their default versions, or ``None`` without a snapshot.
    """
    path = directory / f"pg{major}.txt"
    if not path.exists():
        return None
    baseline: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip() and not line.startswith("#"):
            name, _, version = line.partition(" ")
            baseline[name] = version
    return baseline


def _bake_default(name: str, path: Path) -> str:
    match = re.search(
        rf'variable\s+"{name}"\s*\{{\s*default\s*=\s*"(?P<value>[^"]*)"',
        path.read_text(encoding="utf-8"),
    )
    if match is None:
        msg = f"no {name} default in {path}"
        raise ValueError(msg)
    return match["value"]


def matrix_majors(path: Path = BAKE_PATH) -> tuple[int, ...]:
    """
    Read the PostgreSQL majors of the build matrix from the Bake file.

    :param path: The Bake file.
    :return: The default ``PG_MAJORS``, in ascending order.
    """
    majors = _bake_default("PG_MAJORS", path).split(",")
    return tuple(sorted(int(major) for major in majors if major.strip()))


def matrix_postgis(path: Path = BAKE_PATH) -> str:
    """
    Read the PostGIS ``major.minor`` the build matrix targets from the Bake file.

    :param path: The Bake file.
    :return: The default ``POSTGIS_VERSION``.
    """
    return _bake_default("POSTGIS_VERSION", path)


def provided_extensions(manifest: Iterable[Extension], major: int) -> set[str]:
    """
    Collect the extension names the manifest ships for a PostgreSQL major.

    :param manifest: The manifest entries.
    :param major: The PostgreSQL major version.
    :return: The extension names.
    """
    return {name for entry in manifest if entry.ships_for(major) for name in entry.provides}
