# Tasks for postgis-with-extensions: run `just` to list them.
# Recipes run in sh, or in PowerShell on Windows, so they stick to plain commands.

set windows-shell := ["pwsh.exe", "-NoLogo", "-NoProfile", "-Command"]
set lazy

export PYTHONUTF8 := "1"

dev_image := "postgis-with-extensions:dev"
branch := `git branch --show-current`
latest_run := `gh run list --branch $(git branch --show-current) --limit 1 --json databaseId --jq '.[0].databaseId'`

[private]
default:
    @just --justfile {{ justfile() }} --list

# Run every linter and formatter (prek only checks tracked files: `git add` new ones first)
[group("check")]
lint:
    uv run prek run --all-files

# Run the tests that need no Docker: manifest, preload registry and baselines
[group("check")]
static-test:
    uv run --exact pytest tests/test_manifest.py

# Regenerate the README extension table from extensions.toml
[group("check")]
readme:
    uv run --exact python -m scripts.render_readme

# Compare the build matrix with the postgis/postgis tags upstream maintains
[group("check")]
drift:
    uv run --exact python -m scripts.check_upstream

# Run the linters on every commit
[group("check")]
hooks:
    uv run prek install

# Build a PostgreSQL major's image and load it as postgis-with-extensions:dev-<major>-<PostGIS> (needs Docker)
[group("image")]
build pg="18" $POSTGIS_VERSION="3.7":
    docker buildx bake pg{{ pg }} --load --set pg{{ pg }}.tags={{ dev_image }}-{{ pg }}-{{ POSTGIS_VERSION }}

# Test an image built by `just build`; further arguments go to pytest (set PWE_TEST_LOGS to keep server logs)
[group("image")]
test pg="18" postgis="3.7" *args:
    uv run --exact pytest --image {{ dev_image }}-{{ pg }}-{{ postgis }} {{ args }}

# Run CI on a branch for one PostGIS line (3.6 checks the final 3.6 release); it never publishes
[group("ci")]
ci postgis="3.7" ref=branch:
    gh workflow run ci.yml --ref {{ ref }} -f postgis={{ postgis }} -f publish=false

# Wait for a CI run to finish (default: the branch's latest), failing if it fails
[group("ci")]
ci-watch run=latest_run:
    gh run watch {{ run }} --exit-status --interval 60

# List a CI run's jobs with their ids (default: the branch's latest run)
[group("ci")]
ci-jobs run=latest_run:
    gh run view {{ run }} --json jobs --jq '.jobs[] | [.databaseId, .name, .status, .conclusion] | @tsv'

# Print a finished job's log, even while its run goes on (`gh run view --log-failed` waits for the whole run)
[group("ci")]
ci-log job:
    gh api --allow-escape-sequences 'repos/{owner}/{repo}/actions/jobs/{{ job }}/logs'

# Download a CI run's test reports and server logs into .ci/<run>
[group("ci")]
ci-artifacts run=latest_run:
    gh run download {{ run }} --dir .ci/{{ run }}

# Publish the final PostGIS 3.6 images: a one-off CI run on master
[confirm("Publish the final PostGIS 3.6 images to Docker Hub and GHCR from master?")]
[group("release")]
publish-3-6:
    gh workflow run ci.yml --ref master -f postgis=3.6 -f publish=true
