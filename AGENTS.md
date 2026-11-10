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
- `build/github-packages.txt`: PGXS extensions built from GitHub tags (or commits, with the branch Renovate follows),
  next to `build/pgxn-packages.txt` for PGXN; the `vendor` stage (`build/fetch-vendor.sh`) takes upstream binaries.
- `justfile`: the common tasks (`just --list`): lint, static tests, README rendering, image builds and tests, CI
  dispatch and logs.
- `tests/`: pytest drives the docker CLI (`tests/_docker.py`); `tests/sql/*.sql` are per-extension pgTAP scripts with
  `-- preload:` / `-- conflicts:` / `-- pg:` / `-- database:` directives, run on a server preloading just what they
  need and on the `all` one; `tests/sql/lib/helpers.sql` gives them `wait_until()` and `plan_of()`, and
  `tests/sql/data/` is served at `http://127.0.0.1:8000/`; `tests/baseline/` snapshots the extensions of the
  pre-rewrite images and must never lose a name; `tests/upgrade/` reopens clusters created by the previous image.

## Rules

- Never break existing containers: no edits to existing clusters' configuration files, the wrapper only adds
  libraries, and published tags keep their meaning. Ask before any change that alters behaviour for existing clusters.
- Pin every non-apt source (with a `# renovate:` comment); PGDG packages float and refresh weekly.
- When adding an extension, record its library's background workers in `image/preload-libraries.txt` (they size
  `max_worker_processes`), and list any logical decoding output plugin it ships in `trusted_plugins`
  (`image/initdb/z_conf.sh`): since the August 2026 minor releases, PostgreSQL refuses other plugins, even for
  superusers.
- Docker isn't available on the maintainer's Windows machine: image builds and tests run in GitHub Actions.
- Python is 3.13+, fully typed, with Sphinx field-list docstrings (`:param:`, `:return:`, `:raise:`); prek runs ruff
  (`ALL`), ty and pydoclint. Every suppression comment carries a reason.
- Shell scripts use bash with `set -Eeuo pipefail`; shellcheck and shfmt must pass.
- Each extension's test must prove it works, not just that it loads: known-answer assertions on its main features,
  index use checked with `plan_of()`, background workers seen doing their job. Remote-database FDWs, which have no
  server in CI, must show their client library loading and trying to connect.
- Run `uv run prek run --all-files` before committing, after `git add`-ing new files (it only checks tracked ones);
  `uv run python -m scripts.render_readme` after editing `extensions.toml`.
- Commit messages follow Conventional Commits.
