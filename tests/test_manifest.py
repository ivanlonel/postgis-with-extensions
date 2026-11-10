"""Static consistency checks of the manifest, the preload registry and the baselines."""

from __future__ import annotations

from collections import Counter

from scripts.manifest import load_baseline, load_manifest, load_registry, matrix_majors


def test_manifest_names_are_unique() -> None:
    """Every manifest entry has its own display name."""
    duplicates = [name for name, n in Counter(e.name for e in load_manifest()).items() if n > 1]
    assert not duplicates


def test_provided_extensions_are_unique() -> None:
    """No two manifest entries claim the same extension."""
    counts = Counter(name for entry in load_manifest() for name in entry.provides)
    assert not [name for name, n in counts.items() if n > 1]


def test_manifest_preloads_are_registered() -> None:
    """Every library the manifest tells users to preload is in the registry."""
    registered = {library.name for library in load_registry()}
    unknown = {e.preload for e in load_manifest() if e.preload} - registered
    assert not unknown


def test_registry_requirements_are_registered() -> None:
    """Libraries pulled in by others are registry entries themselves."""
    registry = load_registry()
    registered = {library.name for library in registry}
    unknown = {name for library in registry for name in library.requires} - registered
    assert not unknown


def test_every_matrix_major_up_to_18_has_a_baseline() -> None:
    """The pre-rewrite majors keep their snapshot, so no extension can silently disappear."""
    missing = [major for major in matrix_majors() if major <= 18 and load_baseline(major) is None]
    assert not missing
