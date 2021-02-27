ARG BASE_IMAGE=postgis/postgis
ARG BASE_IMAGE_TAG=latest

FROM $BASE_IMAGE:$BASE_IMAGE_TAG as base-image

ENV ORACLE_HOME /usr/lib/oracle/client
ENV PATH $PATH:${ORACLE_HOME}




FROM base-image as basic-deps

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl




FROM basic-deps as powa-scripts

WORKDIR /tmp/powa
RUN curl -LOJ https://raw.githubusercontent.com/powa-team/powa-docker/master/powa-archivist/$PG_MAJOR/setup_powa-archivist.sh && \
    curl -LOJ https://raw.githubusercontent.com/powa-team/powa-docker/master/powa-archivist/$PG_MAJOR/install_all_powa_ext.sql




FROM basic-deps as common-deps

# /var/lib/apt/lists/ still has the indexes from previous stage, so there's no need to run apt-get update again.
RUN apt-get install -y --no-install-recommends \
        gcc \
        make \
        postgresql-server-dev-$PG_MAJOR




FROM common-deps as build-oracle_fdw

# Latest version
ARG ORACLE_CLIENT_URL=https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linuxx64.zip
ARG ORACLE_SQLPLUS_URL=https://download.oracle.com/otn_software/linux/instantclient/instantclient-sqlplus-linuxx64.zip
ARG ORACLE_SDK_URL=https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linuxx64.zip

RUN apt-get install -y --no-install-recommends \
        libaio1 \
        unzip

    # instant client
RUN curl -L -o instant_client.zip ${ORACLE_CLIENT_URL} && \
    unzip instant_client.zip && \
    # sqlplus
    curl -L -o sqlplus.zip ${ORACLE_SQLPLUS_URL} && \
    unzip sqlplus.zip && \
    # sdk
    curl -L -o sdk.zip ${ORACLE_SDK_URL} && \
    unzip sdk.zip && \
    # install
    mkdir -p ${ORACLE_HOME} && \
    mv ./instantclient*/* ${ORACLE_HOME}

# Install oracle_fdw
WORKDIR /tmp/oracle_fdw
RUN ASSET_NAME=$(basename $(curl -LIs -o /dev/null -w %{url_effective} https://github.com/laurenz/oracle_fdw/releases/latest)) && \
    curl -L https://github.com/laurenz/oracle_fdw/archive/${ASSET_NAME}.tar.gz | tar -zx --strip-components=1 -C . && \
    make && \
    make install




FROM common-deps as build-sqlite_fdw

WORKDIR /tmp/sqlite_fdw
RUN apt-get install -y --no-install-recommends libsqlite3-dev
RUN ASSET_NAME=$(basename $(curl -LIs -o /dev/null -w %{url_effective} https://github.com/pgspider/sqlite_fdw/releases/latest)) && \
    curl -L https://github.com/pgspider/sqlite_fdw/archive/${ASSET_NAME}.tar.gz | tar -zx --strip-components=1 -C . && \
    make USE_PGXS=1 && \
    make USE_PGXS=1 install




FROM base-image as final-stage

# See the "Locale Customization" section at https://github.com/docker-library/docs/blob/master/postgres/README.md
RUN localedef -i pt_BR -c -f UTF-8 -A /usr/share/locale/locale.alias pt_BR.UTF-8
ENV LANG pt_BR.utf8

# lc-collate=C makes strings comparison (and decurring operations like sorting) faster,
#     because it's just byte-to-byte comparison (no complex locale rules)
# lc-ctype=C would make Postgres features that use ctype.h (e.g. upper(), lower(), initcap(), ILIKE, citext)
#     work as expected only for characters in the US-ASCII range (that is, up to codepoint 0x7F in Unicode).
ENV POSTGRES_INITDB_ARGS " \
    -E utf8 \
    --auth-host=md5 \
    --lc-collate=C \
    --lc-ctype=pt_BR.UTF-8 \
    --lc-messages=pt_BR.UTF-8 \
    --lc-monetary=pt_BR.UTF-8 \
    --lc-numeric=pt_BR.UTF-8 \
    --lc-time=pt_BR.UTF-8 \
"

# Install pg_cron, mysql_fdw, ogr_fdw, orafce, pgaudit, pgpcre, pgtap, pldebugger, plpgsql_check, tds_fdw, plpython3 and more
# libaio1 is a runtime requirement for the Oracle client that oracle_fdw uses
# I think libsqlite3-dev is a runtime requirement for sqlite_fdw
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libaio1 \
        libsqlite3-dev \
        postgresql-$PG_MAJOR-cron \
        postgresql-$PG_MAJOR-dirtyread \
        postgresql-$PG_MAJOR-extra-window-functions \
        postgresql-$PG_MAJOR-first-last-agg \
        postgresql-$PG_MAJOR-hll \
        postgresql-$PG_MAJOR-icu-ext \
        postgresql-$PG_MAJOR-ip4r \
        postgresql-$PG_MAJOR-jsquery \
        postgresql-$PG_MAJOR-mysql-fdw \
        postgresql-$PG_MAJOR-numeral \
        postgresql-$PG_MAJOR-ogr-fdw \
        postgresql-$PG_MAJOR-orafce \
        postgresql-$PG_MAJOR-partman \
        postgresql-$PG_MAJOR-periods \
        postgresql-$PG_MAJOR-pg-fact-loader \
        postgresql-$PG_MAJOR-pgaudit \
        postgresql-$PG_MAJOR-pgl-ddl-deploy \
        postgresql-$PG_MAJOR-pglogical \
        postgresql-$PG_MAJOR-pglogical-ticker \
        postgresql-$PG_MAJOR-pgmemcache \
        postgresql-$PG_MAJOR-pgmp \
        postgresql-$PG_MAJOR-pgpcre \
        postgresql-$PG_MAJOR-pgq-node \
        postgresql-$PG_MAJOR-pgrouting \
      # postgresql-$PG_MAJOR-pgsphere \
        postgresql-$PG_MAJOR-pgtap \
        postgresql-$PG_MAJOR-pldebugger \
        postgresql-$PG_MAJOR-plpgsql-check \
      # postgresql-$PG_MAJOR-plr \
        postgresql-$PG_MAJOR-plsh \
        postgresql-$PG_MAJOR-pointcloud \
        postgresql-$PG_MAJOR-prefix \
      # postgresql-$PG_MAJOR-q3c \
        postgresql-$PG_MAJOR-rational \
        postgresql-$PG_MAJOR-repack \
        postgresql-$PG_MAJOR-rum \
        postgresql-$PG_MAJOR-similarity \
        postgresql-$PG_MAJOR-tds-fdw \
        postgresql-$PG_MAJOR-unit \
        postgresql-plpython3-$PG_MAJOR \
    # extensions below are all for PoWA
        postgresql-$PG_MAJOR-hypopg \
        postgresql-$PG_MAJOR-pg-qualstats \
        postgresql-$PG_MAJOR-pg-stat-kcache \
        postgresql-$PG_MAJOR-pg-track-settings \
        postgresql-$PG_MAJOR-pg-wait-sampling \
        postgresql-$PG_MAJOR-powa && \
    apt-get purge -y --auto-remove && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build-sqlite_fdw /usr/share/postgresql/$PG_MAJOR/extension/sqlite_fdw* /usr/share/postgresql/$PG_MAJOR/extension/
COPY --from=build-sqlite_fdw /usr/lib/postgresql/$PG_MAJOR/lib/bitcode/sqlite_fdw.index.bc /usr/lib/postgresql/$PG_MAJOR/lib/bitcode/sqlite_fdw.index.bc
COPY --from=build-sqlite_fdw /usr/lib/postgresql/$PG_MAJOR/lib/bitcode/sqlite_fdw /usr/lib/postgresql/$PG_MAJOR/lib/bitcode/sqlite_fdw
COPY --from=build-sqlite_fdw /usr/lib/postgresql/$PG_MAJOR/lib/sqlite_fdw.so /usr/lib/postgresql/$PG_MAJOR/lib/sqlite_fdw.so

COPY --from=build-oracle_fdw /usr/share/postgresql/$PG_MAJOR/extension/oracle_fdw* /usr/share/postgresql/$PG_MAJOR/extension/
COPY --from=build-oracle_fdw /usr/share/doc/postgresql-doc-$PG_MAJOR/extension/README.oracle_fdw /usr/share/doc/postgresql-doc-$PG_MAJOR/extension/README.oracle_fdw
COPY --from=build-oracle_fdw /usr/lib/postgresql/$PG_MAJOR/lib/oracle_fdw.so /usr/lib/postgresql/$PG_MAJOR/lib/oracle_fdw.so
COPY --from=build-oracle_fdw ${ORACLE_HOME} ${ORACLE_HOME}
RUN echo ${ORACLE_HOME} > /etc/ld.so.conf.d/oracle_instantclient.conf && \
    ldconfig

COPY --from=powa-scripts /tmp/powa/setup_powa-archivist.sh /docker-entrypoint-initdb.d/setup_powa-archivist.sh
COPY --from=powa-scripts /tmp/powa/install_all_powa_ext.sql /usr/local/src/install_all_powa_ext.sql

COPY ./conf.sh /docker-entrypoint-initdb.d/z_conf.sh

# TO-DO:
# Set up github actions to deploy this to dockerhub automatically
# Use initialization scripts to create the database, roles etc during first run
#   See the "Initialization scripts" section at https://github.com/docker-library/docs/blob/master/postgres/README.md
#   Since that info is irrelevant to the image itself, it's probably better to inject this script via docker-compose instead of Dockerfile (maybe even as buildkit secrets)
