"""The image offers every extension it used to, plus the ones the manifest adds."""

from __future__ import annotations

import warnings
from typing import TYPE_CHECKING

import pytest

from scripts.manifest import load_baseline, load_manifest, provided_extensions

if TYPE_CHECKING:
    from tests._docker import Image, Server


def _available(server: Server) -> set[str]:
    return set(server.query("SELECT name FROM pg_available_extensions"))


def test_no_extension_was_lost(default_server: Server, image: Image) -> None:
    """Everything the pre-rewrite image offered for this major is still available."""
    baseline = load_baseline(image.pg_major)
    if baseline is None:
        pytest.skip(f"no pre-rewrite baseline for PostgreSQL {image.pg_major}")
    missing = set(baseline) - _available(default_server)
    assert not missing, f"extensions no longer available: {sorted(missing)}"


def test_manifest_extensions_are_available(default_server: Server, image: Image) -> None:
    """Every extension the manifest ships for this major (and variant) is available."""
    shipped = provided_extensions(load_manifest(), image.pg_major, extended=image.extended)
    missing = shipped - _available(default_server)
    assert not missing, f"extensions listed in extensions.toml but missing: {sorted(missing)}"


def test_every_extension_is_documented(
    default_server: Server, image: Image, pytestconfig: pytest.Config
) -> None:
    """
    Every extension the image offers is part of the baseline or of the manifest.

    A regular image offering an extension the manifest keeps to the extended ones fails this too.
    """
    documented = set(load_baseline(image.pg_major) or {}) | provided_extensions(
        load_manifest(), image.pg_major, extended=image.extended
    )
    undocumented = sorted(_available(default_server) - documented)
    if not undocumented:
        return
    message = f"extensions missing from extensions.toml: {undocumented}"
    if pytestconfig.getoption("--strict-drift"):
        pytest.fail(message)
    warnings.warn(message, stacklevel=1)
