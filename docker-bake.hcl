# Build definition for ivanlonel/postgis-with-extensions.
#
#   docker buildx bake                          # every PostgreSQL major, for POSTGIS_VERSION
#   docker buildx bake pg18 --load              # a single major
#   POSTGIS_VERSION=3.6 docker buildx bake      # the PostGIS 3.6 line (one-off final release)

# PostgreSQL majors to build, following the postgis/postgis Debian tags.
variable "PG_MAJORS" {
  default = "14,15,16,17,18"
}

# PostGIS major.minor of the postgis/postgis base images.
variable "POSTGIS_VERSION" {
  default = "3.7"
}

# The <PG major>-<PostGIS> tag also published as "latest".
variable "LATEST" {
  default = "18-3.7"
}

# Comma-separated image repositories to tag.
variable "IMAGES" {
  default = "docker.io/ivanlonel/postgis-with-extensions,ghcr.io/ivanlonel/postgis-with-extensions"
}

# TimescaleDB for the majors its current release line supports (see timescaledb_version).
# renovate: datasource=github-releases depName=timescale/timescaledb
variable "TIMESCALEDB_VERSION" {
  default = "2.31.0"
}

# CI sets it to the ISO week, so the PGDG packages refresh weekly.
variable "APT_CACHE_BUST" {
  default = ""
}

# Commit for the org.opencontainers.image.revision label (CI sets it).
variable "REVISION" {
  default = ""
}

function "timescaledb_version" {
  params = [pg]
  # PG 14 and 15 stay on the last release lines that support them. The PostGIS 3.6 release keeps
  # the version its previous images shipped, so existing databases need no extension update.
  result = (pg == "14" ? "2.19.3"
    : pg == "15" ? "2.28.3"
    : POSTGIS_VERSION == "3.6" ? "2.31.0"
  : TIMESCALEDB_VERSION)
}

function "image_tags" {
  params = [tag]
  result = flatten([
    for image in split(",", IMAGES) :
    concat(["${image}:${tag}"], tag == LATEST ? ["${image}:latest"] : [])
  ])
}

target "image" {
  name = "pg${pg}"
  matrix = {
    pg = split(",", PG_MAJORS)
  }
  context    = "."
  dockerfile = "Dockerfile"
  target     = "final"
  platforms  = ["linux/amd64"]
  args = {
    BASE_IMAGE_TAG      = "${pg}-${POSTGIS_VERSION}"
    TIMESCALEDB_VERSION = timescaledb_version(pg)
    # PostGIS 3.6 images keep preloading the libraries they always did; 3.7+ preload nothing.
    DEFAULT_PRELOAD = POSTGIS_VERSION == "3.6" ? "legacy" : ""
    APT_CACHE_BUST  = APT_CACHE_BUST
  }
  tags = image_tags("${pg}-${POSTGIS_VERSION}")
  labels = {
    "org.opencontainers.image.title"       = "postgis-with-extensions"
    "org.opencontainers.image.description" = "PostgreSQL ${pg} with PostGIS ${POSTGIS_VERSION} and many other extensions"
    "org.opencontainers.image.source"      = "https://github.com/ivanlonel/postgis-with-extensions"
    "org.opencontainers.image.url"         = "https://hub.docker.com/r/ivanlonel/postgis-with-extensions"
    "org.opencontainers.image.licenses"    = "MIT"
    "org.opencontainers.image.version"     = "${pg}-${POSTGIS_VERSION}"
    "org.opencontainers.image.revision"    = REVISION
    "org.opencontainers.image.base.name"   = "docker.io/postgis/postgis:${pg}-${POSTGIS_VERSION}"
  }
}

group "default" {
  targets = ["image"]
}
