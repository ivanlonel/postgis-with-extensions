# Build definition for ivanlonel/postgis-with-extensions.
#
#   docker buildx bake                          # every PostgreSQL major and variant, for POSTGIS_VERSION
#   docker buildx bake pg18 --load              # a single major's regular image
#   docker buildx bake pg18-full --load         # ... or its extended image
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

# Tag suffix of the extended images (<PG major>-<PostGIS>-<suffix>), which add heavier extensions
# to the regular ones. The extended image of LATEST is also published as just <suffix>.
variable "EXTENDED_SUFFIX" {
  default = "full"
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

function "image_tag" {
  params = [pg, variant]
  result = "${pg}-${POSTGIS_VERSION}${variant == "extended" ? "-${EXTENDED_SUFFIX}" : ""}"
}

function "image_tags" {
  params = [tag]
  result = flatten([
    for image in split(",", IMAGES) :
    concat(
      ["${image}:${tag}"],
      tag == LATEST ? ["${image}:latest"] : [],
      tag == "${LATEST}-${EXTENDED_SUFFIX}" ? ["${image}:${EXTENDED_SUFFIX}"] : [],
    )
  ])
}

target "image" {
  name = variant == "extended" ? "pg${pg}-${EXTENDED_SUFFIX}" : "pg${pg}"
  matrix = {
    pg = split(",", PG_MAJORS)
    # The frozen PostGIS 3.6 line has no extended images.
    variant = POSTGIS_VERSION == "3.6" ? ["regular"] : ["regular", "extended"]
  }
  context    = "."
  dockerfile = "Dockerfile"
  target     = variant == "extended" ? "extended" : "final"
  platforms  = ["linux/amd64"]
  args = {
    BASE_IMAGE_TAG      = "${pg}-${POSTGIS_VERSION}"
    TIMESCALEDB_VERSION = timescaledb_version(pg)
    # PostGIS 3.6 images keep preloading the libraries they always did; 3.7+ preload nothing.
    DEFAULT_PRELOAD = POSTGIS_VERSION == "3.6" ? "legacy" : ""
    APT_CACHE_BUST  = APT_CACHE_BUST
  }
  tags = image_tags(image_tag(pg, variant))
  labels = {
    "org.opencontainers.image.title" = "postgis-with-extensions"
    "org.opencontainers.image.description" = (variant == "extended"
      ? "PostgreSQL ${pg} with PostGIS ${POSTGIS_VERSION}, many other extensions and heavier ones (Citus, DocumentDB, pg_duckdb, pg_search, PL/Java, PL/R...)"
    : "PostgreSQL ${pg} with PostGIS ${POSTGIS_VERSION} and many other extensions")
    "org.opencontainers.image.source"    = "https://github.com/ivanlonel/postgis-with-extensions"
    "org.opencontainers.image.url"       = "https://hub.docker.com/r/ivanlonel/postgis-with-extensions"
    "org.opencontainers.image.licenses"  = "MIT"
    "org.opencontainers.image.version"   = image_tag(pg, variant)
    "org.opencontainers.image.revision"  = REVISION
    "org.opencontainers.image.base.name" = "docker.io/postgis/postgis:${pg}-${POSTGIS_VERSION}"
  }
}

group "default" {
  targets = ["image"]
}
