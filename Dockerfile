# syntax=docker/dockerfile:1

# The postgis/postgis tag to extend, as <PostgreSQL major>-<PostGIS major.minor>.
# docker-bake.hcl sets it for every target; the default only serves plain `docker build`.
ARG BASE_IMAGE_TAG=18-3.7


FROM postgis/postgis:${BASE_IMAGE_TAG} AS base
SHELL ["/bin/bash", "-Eeuo", "pipefail", "-c"]


FROM base AS build-base
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bison \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        flex \
        libboost-dev \
        libcurl4-openssl-dev \
        libhiredis-dev \
        libicu-dev \
        libjq-dev \
        libkrb5-dev \
        liblz4-dev \
        libnuma-dev \
        libpam0g-dev \
        libpoppler-glib-dev \
        librdkafka-dev \
        libreadline-dev \
        libselinux1-dev \
        libsodium-dev \
        libsqlite3-dev \
        libssl-dev \
        liburiparser-dev \
        libzstd-dev \
        pkgconf \
        "postgresql-server-dev-${PG_MAJOR}" \
        python3 \
        unzip \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
COPY --chmod=0755 build/build-pgxs.sh /usr/local/bin/build-pgxs


FROM build-base AS timescaledb
# docker-bake.hcl pins older releases for majors the current line no longer supports.
# renovate: datasource=github-releases depName=timescale/timescaledb
ARG TIMESCALEDB_VERSION=2.31.0
WORKDIR /src/timescaledb
RUN curl --fail --silent --show-error --location --retry 3 --output /tmp/timescaledb.tar.gz \
        "https://github.com/timescale/timescaledb/archive/refs/tags/${TIMESCALEDB_VERSION}.tar.gz" \
    && tar -xzf /tmp/timescaledb.tar.gz --strip-components=1 \
    && ./bootstrap \
        -DCMAKE_BUILD_TYPE=Release \
        -DREGRESS_CHECKS=OFF \
        -DTAP_CHECKS=OFF \
        -DWARNINGS_AS_ERRORS=OFF \
    && make -C build -j "$(nproc)" \
    && make -C build install DESTDIR=/out


FROM build-base AS pgxn
COPY build/pgxn-packages.txt /tmp/pgxn-packages.txt
RUN while read -r dist version; do \
        case "$dist" in ''|'#'*) continue ;; esac; \
        build-pgxs "https://api.pgxn.org/dist/${dist}/${version}/${dist}-${version}.zip" USE_PGXS=1; \
    done < /tmp/pgxn-packages.txt


FROM build-base AS github
# Make variables in the list work around upstream issues: pg_tracing's PG_CFLAGS= drops its -Werror,
# which trixie's stricter libcurl headers trip.
COPY --chmod=0755 build/build-github.sh /usr/local/bin/build-github
COPY build/github-packages.txt /tmp/github-packages.txt
RUN build-github /tmp/github-packages.txt


FROM build-base AS citus
# Each Citus line supports three PostgreSQL majors and still gets fixes: 14 for PostgreSQL 16 to 18,
# 13 for 15 to 17 and 12.1 for 14 to 16 (Renovate keeps the older lines on their major).
# renovate: datasource=github-releases depName=citusdata/citus extractVersion=^v(?<version>.+)$
ARG CITUS_VERSION=14.3.0
# renovate: datasource=github-releases depName=citusdata/citus extractVersion=^v(?<version>.+)$
ARG CITUS_13_VERSION=13.5.0
# renovate: datasource=github-releases depName=citusdata/citus extractVersion=^v(?<version>.+)$
ARG CITUS_12_VERSION=12.1.14
WORKDIR /src/citus
RUN case "$PG_MAJOR" in \
        14) version="$CITUS_12_VERSION" ;; \
        15) version="$CITUS_13_VERSION" ;; \
        *) version="$CITUS_VERSION" ;; \
    esac \
    && curl --fail --silent --show-error --location --retry 3 --output /tmp/citus.tar.gz \
        "https://github.com/citusdata/citus/archive/refs/tags/v${version}.tar.gz" \
    && tar -xzf /tmp/citus.tar.gz --strip-components=1 \
    && ./configure \
    && make -j "$(nproc)" \
    && make install DESTDIR=/out


FROM build-base AS pgactive
# renovate: datasource=github-releases depName=aws/pgactive extractVersion=^v(?<version>.+)$
ARG PGACTIVE_VERSION=2.1.9
WORKDIR /src/pgactive
RUN curl --fail --silent --show-error --location --retry 3 --output /tmp/pgactive.tar.gz \
        "https://github.com/aws/pgactive/archive/refs/tags/v${PGACTIVE_VERSION}.tar.gz" \
    && tar -xzf /tmp/pgactive.tar.gz --strip-components=1 \
    && ./configure \
    && make -j "$(nproc)" \
    && make install DESTDIR=/out


FROM build-base AS pguint
# renovate: datasource=github-tags depName=petere/pguint
ARG PGUINT_VERSION=1.20260630
RUN build-pgxs "https://github.com/petere/pguint/archive/refs/tags/${PGUINT_VERSION}.tar.gz" PYTHON=python3


FROM build-base AS sqlite-fdw
# renovate: datasource=github-tags depName=pgspider/sqlite_fdw extractVersion=^v(?<version>.+)$
ARG SQLITE_FDW_VERSION=2.5.0
# sqlite_fdw doesn't support PostgreSQL 18 yet.
RUN if [ "$PG_MAJOR" -le 17 ]; then \
        build-pgxs "https://github.com/pgspider/sqlite_fdw/archive/refs/tags/v${SQLITE_FDW_VERSION}.tar.gz" USE_PGXS=1; \
    else \
        mkdir -p /out; \
    fi


FROM build-base AS pg-stat-monitor
# renovate: datasource=github-releases depName=percona/pg_stat_monitor
ARG PG_STAT_MONITOR_VERSION=2.4.0
RUN build-pgxs "https://github.com/percona/pg_stat_monitor/archive/refs/tags/${PG_STAT_MONITOR_VERSION}.tar.gz" USE_PGXS=1


FROM build-base AS pg-net
# renovate: datasource=github-tags depName=supabase/pg_net extractVersion=^v(?<version>.+)$
ARG PG_NET_VERSION=0.20.5
RUN build-pgxs "https://github.com/supabase/pg_net/archive/refs/tags/v${PG_NET_VERSION}.tar.gz"


FROM build-base AS pg-tle
# renovate: datasource=github-tags depName=aws/pg_tle extractVersion=^v(?<version>.+)$
ARG PG_TLE_VERSION=1.5.3
RUN build-pgxs "https://github.com/aws/pg_tle/archive/refs/tags/v${PG_TLE_VERSION}.tar.gz"


FROM build-base AS pg-hashids
# renovate: datasource=github-tags depName=iCyberon/pg_hashids extractVersion=^v(?<version>.+)$
ARG PG_HASHIDS_VERSION=1.2.1
RUN build-pgxs "https://github.com/iCyberon/pg_hashids/archive/refs/tags/v${PG_HASHIDS_VERSION}.tar.gz"


FROM build-base AS pg-bigm
# renovate: datasource=github-tags depName=pgbigm/pg_bigm extractVersion=^v(?<version>.+)$ versioning=loose
ARG PG_BIGM_VERSION=1.2-20250903
RUN build-pgxs "https://github.com/pgbigm/pg_bigm/archive/refs/tags/v${PG_BIGM_VERSION}.tar.gz" USE_PGXS=1


FROM build-base AS pg-profile
# renovate: datasource=github-releases depName=zubkov-andrei/pg_profile
ARG PG_PROFILE_VERSION=4.16
# The release tarball holds the ready-to-install control and SQL files.
RUN extdir="/out$(pg_config --sharedir)/extension" \
    && mkdir -p "$extdir" \
    && curl --fail --silent --show-error --location --retry 3 --output /tmp/pg_profile.tar.gz \
        "https://github.com/zubkov-andrei/pg_profile/releases/download/${PG_PROFILE_VERSION}/pg_profile--${PG_PROFILE_VERSION}.tar.gz" \
    && tar -xzf /tmp/pg_profile.tar.gz -C "$extdir"


FROM build-base AS vendor
# renovate: datasource=github-releases depName=supervc-stack/VectorChord
ARG VCHORD_VERSION=1.1.1
# renovate: datasource=github-releases depName=timescale/pgvectorscale
ARG PGVECTORSCALE_VERSION=0.9.1
# renovate: datasource=github-releases depName=supabase/pg_graphql extractVersion=^v(?<version>.+)$
ARG PG_GRAPHQL_VERSION=1.6.3
# renovate: datasource=github-releases depName=supabase/pg_jsonschema extractVersion=^v(?<version>.+)$
ARG PG_JSONSCHEMA_VERSION=0.3.4
# renovate: datasource=github-releases depName=timescale/timescaledb-toolkit extractVersion=^(?<version>\d+\.\d+\.\d+)
ARG TIMESCALEDB_TOOLKIT_VERSION=1.27.0
# renovate: datasource=github-releases depName=pksunkara/pgx_ulid extractVersion=^v(?<version>.+)$
ARG PGX_ULID_VERSION=0.2.3
# renovate: datasource=github-releases depName=kaspermarstal/plprql extractVersion=^v(?<version>.+)$
ARG PLPRQL_VERSION=18.0.2
# renovate: datasource=github-releases depName=rustprooflabs/pgdd
ARG PGDD_VERSION=0.6.1
# renovate: datasource=github-releases depName=mpartel/postgres-protobuf extractVersion=^v(?<version>.+)$
ARG POSTGRES_PROTOBUF_VERSION=0.3.3
# renovate: datasource=github-releases depName=VADOSWARE/pg_idkit extractVersion=^v(?<version>.+)$
ARG PG_IDKIT_VERSION=0.4.0
COPY --chmod=0755 build/fetch-vendor.sh /usr/local/bin/fetch-vendor
RUN fetch-vendor


FROM base AS final
# CI passes the ISO week, so the PGDG packages refresh weekly while rebuilds within a week stay cached.
ARG APT_CACHE_BUST=
# Image-level default for shared_preload_libraries on new clusters: "legacy" (PostGIS 3.6) or empty.
ARG DEFAULT_PRELOAD=

RUN --mount=type=bind,source=build,target=/build \
    --mount=type=bind,from=vendor,source=/debs,target=/debs \
    bash /build/install-runtime.sh /build/apt-packages.txt /debs/*.deb

COPY --link --from=timescaledb /out/ /
COPY --link --from=pgxn /out/ /
COPY --link --from=github /out/ /
COPY --link --from=citus /out/ /
COPY --link --from=pgactive /out/ /
COPY --link --from=vendor /out/ /
COPY --link --from=pguint /out/ /
COPY --link --from=sqlite-fdw /out/ /
COPY --link --from=pg-stat-monitor /out/ /
COPY --link --from=pg-net /out/ /
COPY --link --from=pg-tle /out/ /
COPY --link --from=pg-hashids /out/ /
COPY --link --from=pg-bigm /out/ /
COPY --link --from=pg-profile /out/ /

COPY --chmod=0755 image/postgis-with-extensions-entrypoint.sh /usr/local/bin/
# No --chmod here: it would also apply to the directory COPY creates, leaving it unsearchable.
COPY image/preload-libraries.txt image/preload.sh /usr/local/share/postgis-with-extensions/
# pgsodium and Supabase Vault run $sharedir/extension/pgsodium_getkey for their root key when preloaded.
COPY --chmod=0755 image/pgsodium_getkey.sh /usr/local/bin/pgsodium_getkey
RUN ln -sf /usr/local/bin/pgsodium_getkey "/usr/share/postgresql/${PG_MAJOR}/extension/pgsodium_getkey"
COPY image/powa/install_all_powa_ext.sql /usr/local/src/
COPY --chmod=0755 image/initdb/ /docker-entrypoint-initdb.d/

ENV PWE_DEFAULT_PRELOAD=${DEFAULT_PRELOAD}

# The shell is part of the image config: restore the default so images built FROM this one keep
# running their RUN instructions with plain `sh -c`, as they did before.
SHELL ["/bin/sh", "-c"]

ENTRYPOINT ["postgis-with-extensions-entrypoint.sh"]
CMD ["postgres"]
