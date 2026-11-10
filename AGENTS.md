# AGENTS.md

Guidance for coding agents working in this repository.

## Project

Builds and publishes `ivanlonel/postgis-with-extensions` (Docker Hub and GHCR): the `postgis/postgis` Debian images
plus 100+ extensions. The images follow upstream's Debian tags (amd64 only); CI builds PostGIS 3.7 for PostgreSQL
14–18. `X-3.6` tags got a single final release and are frozen.

## Layout

- `Dockerfile`: one stage per source build (`make install DESTDIR=/out`, copied into `final`); the `vendor` stage
  downloads third-party `.deb`s; `final` installs `build/apt-packages.txt` via `build/install-runtime.sh`, which also
  adds the PostGIS 3.7 compatibility shims (tiger geocoder on PG 14/15, `address_standardizer-3.so`, `-3` aliases).
- `docker-bake.hcl`: the build matrix (`PG_MAJORS` × `POSTGIS_VERSION`), per-major TimescaleDB pins, tags, labels.
- `image/`: the entrypoint wrapper (applies `SHARED_PRELOAD_LIBRARIES` on every start), the preload registry
  (`preload-libraries.txt`, shared by the wrapper, the init scripts and the tests), `preload.sh` helpers, and the init
  scripts, whose file names (`z_conf.sh`, `setup_powa-archivist.sh`) must not change: users may override them.
- `extensions.toml`: the manifest behind the README table and the catalog tests.
- `tests/`: pytest drives the docker CLI (`tests/_docker.py`); `tests/sql/*.sql` are per-extension pgTAP scripts with
  `-- preload:` / `-- pg:` / `-- database:` directives; `tests/baseline/` snapshots the extensions of the pre-rewrite
  images and must never lose a name; `tests/upgrade/` reopens clusters created by the previous image.

## Rules

- Never break existing containers: no edits to existing clusters' configuration files, the wrapper only adds
  libraries, and published tags keep their meaning. Ask before any change that alters behaviour for existing clusters.
- Pin every non-apt source (with a `# renovate:` comment); PGDG packages float and refresh weekly.
- Docker isn't available on the maintainer's Windows machine: image builds and tests run in GitHub Actions.
- Python is 3.13+, fully typed, with Sphinx field-list docstrings (`:param:`, `:return:`, `:raise:`); prek runs ruff
  (`ALL`), ty and pydoclint. Every suppression comment carries a reason.
- Shell scripts use bash with `set -Eeuo pipefail`; shellcheck and shfmt must pass.
- Run `uv run prek run --all-files` before committing; `uv run python -m scripts.render_readme` after editing
  `extensions.toml`.
- Commit messages follow Conventional Commits.
