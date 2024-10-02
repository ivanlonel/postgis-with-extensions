ARG BASE_IMAGE_TAG=latest

FROM postgis/postgis:$BASE_IMAGE_TAG AS base-image

ENV ORACLE_HOME /usr/lib/oracle/client
ENV PATH $PATH:${ORACLE_HOME}




FROM base-image AS basic-deps

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		curl




FROM basic-deps AS powa-scripts

WORKDIR /tmp/powa
RUN (curl --fail -LOJ "https://raw.githubusercontent.com/powa-team/powa-podman/master/powa-archivist/$PG_MAJOR/setup_powa-archivist.sh" || \
	curl --fail -LOJ "https://raw.githubusercontent.com/powa-team/powa-podman/master/powa-archivist-git/setup_powa-archivist.sh") && \
	(curl --fail -LOJ "https://raw.githubusercontent.com/powa-team/powa-podman/master/powa-archivist/$PG_MAJOR/install_all_powa_ext.sql" || \
	curl --fail -LOJ "https://raw.githubusercontent.com/powa-team/powa-podman/master/powa-archivist-git/install_all_powa_ext.sql")




FROM basic-deps AS common-deps

# /var/lib/apt/lists/ still has the indexes from parent stage, so there's no need to run apt-get update again.
# (unless the parent stage cache is not invalidated...)
RUN apt-get install -y --no-install-recommends \
	gcc \
	make \
	postgresql-server-dev-$PG_MAJOR




FROM common-deps AS cmake-deps

RUN apt-get install -y --no-install-recommends build-essential checkinstall zlib1g-dev libssl-dev && \
	ASSET_NAME=$(basename $(curl -LIs -o /dev/null -w %{url_effective} https://github.com/Kitware/CMake/releases/latest)) && \
	curl --fail -L "https://github.com/Kitware/CMake/archive/${ASSET_NAME}.tar.gz" | tar -zx --strip-components=1 -C . && \
	./bootstrap && \
	make && \
	make install




FROM cmake-deps AS build-h3

WORKDIR /tmp/h3
RUN ASSET_NAME=$(basename $(curl -LIs -o /dev/null -w %{url_effective} https://github.com/zachasme/h3-pg/releases/latest)) && \
	curl --fail -L "https://github.com/zachasme/h3-pg/archive/${ASSET_NAME}.tar.gz" | tar -zx --strip-components=1 -C . && \
	cmake -B build -DCMAKE_BUILD_TYPE=Release && \
	cmake --build build && \
	cmake --install build --component h3-pg




FROM cmake-deps AS build-timescaledb

WORKDIR /tmp/timescaledb
RUN apt-get install -y --no-install-recommends libkrb5-dev && \
	URL_END=$(case "$PG_MAJOR" in ("12") echo "tag/2.11.2";; ("13") echo "tag/2.15.3";; (*) echo "latest";; esac) && \
	ASSET_NAME=$(basename $(curl -LIs -o /dev/null -w %{url_effective} https://github.com/timescale/timescaledb/releases/${URL_END})) && \
	curl --fail -L "https://github.com/timescale/timescaledb/archive/${ASSET_NAME}.tar.gz" | tar -zx --strip-components=1 -C . && \
	./bootstrap
WORKDIR /tmp/timescaledb/build
RUN make -j$(nproc) && \
	make install




FROM cmake-deps AS build-mobilitydb

WORKDIR /tmp/mobilitydb
RUN apt-get install -y --no-install-recommends libgeos++-dev libgsl-dev libjson-c-dev libproj-dev && \
	URL_END=$(case "$PG_MAJOR" in ("12") echo "tag/v1.1.2";; (*) echo "latest";; esac) && \
	ASSET_NAME=$(basename $(curl -LIs -o /dev/null -w %{url_effective} https://github.com/MobilityDB/MobilityDB/releases/${URL_END})) && \
	curl --fail -L "https://github.com/MobilityDB/MobilityDB/archive/${ASSET_NAME}.tar.gz" | tar -zx --strip-components=1 -C .
WORKDIR /tmp/mobilitydb/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON -DCMAKE_POLICY_DEFAULT_CMP0069=NEW .. && \
	make -j$(nproc) && \
	make install




FROM common-deps AS pgxn

RUN apt-get install -y --no-install-recommends pgxnclient && \
	pgxn install ddlx && \
	pgxn install pg_uuidv7




FROM common-deps AS build-pguint

WORKDIR /tmp/pguint
RUN ASSET_NAME=$(basename $(curl -LIs -o /dev/null -w %{url_effective} https://github.com/petere/pguint/releases/latest)) && \
	curl --fail -L "https://github.com/petere/pguint/archive/${ASSET_NAME}.tar.gz" | tar -zx --strip-components=1 -C . && \
	make && \
	make install




FROM common-deps AS build-sqlite_fdw

WORKDIR /tmp/sqlite_fdw
RUN apt-get install -y --no-install-recommends libsqlite3-dev && \
	ASSET_NAME=$(basename $(curl -LIs -o /dev/null -w %{url_effective} https://github.com/pgspider/sqlite_fdw/releases/latest)) && \
	curl --fail -L "https://github.com/pgspider/sqlite_fdw/archive/${ASSET_NAME}.tar.gz" | tar -zx --strip-components=1 -C . && \
	make USE_PGXS=1 && \
	make USE_PGXS=1 install




FROM common-deps AS build-oracle_fdw

# Latest version
ARG ORACLE_CLIENT_URL=https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linuxx64.zip
ARG ORACLE_SQLPLUS_URL=https://download.oracle.com/otn_software/linux/instantclient/instantclient-sqlplus-linuxx64.zip
ARG ORACLE_SDK_URL=https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linuxx64.zip

RUN apt-get install -y --no-install-recommends unzip && \
	# instant client
	curl --fail -L -o instant_client.zip ${ORACLE_CLIENT_URL} && \
	unzip instant_client.zip -x META-INF/* && \
	# sqlplus
	curl --fail -L -o sqlplus.zip ${ORACLE_SQLPLUS_URL} && \
	unzip sqlplus.zip -x META-INF/* && \
	# sdk
	curl --fail -L -o sdk.zip ${ORACLE_SDK_URL} && \
	unzip sdk.zip -x META-INF/* && \
	# install
	mkdir -p ${ORACLE_HOME} && \
	mv ./instantclient_*/* ${ORACLE_HOME}

# Install oracle_fdw
WORKDIR /tmp/oracle_fdw
RUN ASSET_NAME=$(basename $(curl -LIs -o /dev/null -w %{url_effective} https://github.com/laurenz/oracle_fdw/releases/latest)) && \
	curl --fail -L "https://github.com/laurenz/oracle_fdw/archive/${ASSET_NAME}.tar.gz" | tar -zx --strip-components=1 -C . && \
	make && \
	make install




FROM base-image AS final-stage

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		# runtime requirement for the Oracle client that oracle_fdw uses
		libaio1 \
        # MobilityDB missing runtime dependency from libgsl-dev
        libgsl25 \
		# runtime requirement for using spatialite with sqlite_fdw
		libsqlite3-mod-spatialite \
		pgagent \
		postgresql-$PG_MAJOR-asn1oid \
		postgresql-$PG_MAJOR-cron \
		postgresql-$PG_MAJOR-debversion \
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
		# postgresql-$PG_MAJOR-partman \
		postgresql-$PG_MAJOR-periods \
		postgresql-$PG_MAJOR-pg-fact-loader \
		postgresql-$PG_MAJOR-pgaudit \
		postgresql-$PG_MAJOR-pgauditlogtofile \
		postgresql-$PG_MAJOR-pgfincore \
		postgresql-$PG_MAJOR-pgl-ddl-deploy \
		postgresql-$PG_MAJOR-pglogical \
		postgresql-$PG_MAJOR-pglogical-ticker \
		postgresql-$PG_MAJOR-pgmemcache \
		postgresql-$PG_MAJOR-pgmp \
		postgresql-$PG_MAJOR-pgpcre \
		postgresql-$PG_MAJOR-pgq-node \
		postgresql-$PG_MAJOR-pgrouting \
        postgresql-$PG_MAJOR-pgrouting-scripts \
		# postgresql-$PG_MAJOR-pgsphere \
		postgresql-$PG_MAJOR-pgtap \
		postgresql-$PG_MAJOR-pgvector \
		postgresql-$PG_MAJOR-pldebugger \
		# postgresql-$PG_MAJOR-pljava \
		# postgresql-$PG_MAJOR-pllua \
		postgresql-$PG_MAJOR-plpgsql-check \
		postgresql-$PG_MAJOR-plproxy \
		# postgresql-$PG_MAJOR-plr \
		postgresql-$PG_MAJOR-plsh \
		postgresql-$PG_MAJOR-pointcloud \
		postgresql-$PG_MAJOR-prefix \
		# postgresql-$PG_MAJOR-preprepare \
		postgresql-$PG_MAJOR-prioritize \
		# postgresql-$PG_MAJOR-python3-multicorn \
		postgresql-$PG_MAJOR-q3c \
		postgresql-$PG_MAJOR-rational \
		postgresql-$PG_MAJOR-repack \
		postgresql-$PG_MAJOR-rum \
		postgresql-$PG_MAJOR-semver \
		postgresql-$PG_MAJOR-show-plans \
		postgresql-$PG_MAJOR-similarity \
		postgresql-$PG_MAJOR-tablelog \
		postgresql-$PG_MAJOR-tdigest \
		postgresql-$PG_MAJOR-tds-fdw \
		postgresql-$PG_MAJOR-toastinfo \
		postgresql-$PG_MAJOR-unit \
		# postgresql-$PG_MAJOR-wal2json \
		postgresql-plperl-$PG_MAJOR \
		postgresql-plpython3-$PG_MAJOR \
	# extensions below are all here for PoWA
		postgresql-$PG_MAJOR-hypopg \
		postgresql-$PG_MAJOR-pg-qualstats \
		postgresql-$PG_MAJOR-pg-stat-kcache \
		postgresql-$PG_MAJOR-pg-track-settings \
		postgresql-$PG_MAJOR-pg-wait-sampling \
		postgresql-$PG_MAJOR-powa && \
	apt-get purge -y --auto-remove && \
	rm -rf /var/lib/apt/lists/*

COPY --from=powa-scripts \
	/tmp/powa/setup_powa-archivist.sh \
	/docker-entrypoint-initdb.d/setup_powa-archivist.sh
COPY --from=powa-scripts \
	/tmp/powa/install_all_powa_ext.sql \
	/usr/local/src/install_all_powa_ext.sql

COPY --from=pgxn \
	/usr/share/postgresql/$PG_MAJOR/extension/ \
	/usr/share/postgresql/$PG_MAJOR/extension/
COPY --from=pgxn \
	/usr/lib/postgresql/$PG_MAJOR/lib \
	/usr/lib/postgresql/$PG_MAJOR/lib

COPY --from=build-h3 \
	/usr/share/postgresql/$PG_MAJOR/extension/h3* \
	/usr/share/postgresql/$PG_MAJOR/extension/
COPY --from=build-h3 \
	/usr/lib/postgresql/$PG_MAJOR/lib/h3* \
	/usr/lib/postgresql/$PG_MAJOR/lib/

COPY --from=build-timescaledb \
	/usr/share/postgresql/$PG_MAJOR/extension/timescaledb* \
	/usr/share/postgresql/$PG_MAJOR/extension/
COPY --from=build-timescaledb \
	/usr/lib/postgresql/$PG_MAJOR/lib/timescaledb* \
	/usr/lib/postgresql/$PG_MAJOR/lib/

COPY --from=build-mobilitydb \
	/usr/share/postgresql/$PG_MAJOR/extension/ \
	/usr/share/postgresql/$PG_MAJOR/extension/
COPY --from=build-mobilitydb \
	/usr/lib/postgresql/$PG_MAJOR/lib/ \
	/usr/lib/postgresql/$PG_MAJOR/lib/

COPY --from=build-pguint \
	/usr/share/postgresql/$PG_MAJOR/extension/uint* \
	/usr/share/postgresql/$PG_MAJOR/extension/
COPY --from=build-pguint \
	/usr/lib/postgresql/$PG_MAJOR/lib/uint* \
	/usr/lib/postgresql/$PG_MAJOR/lib/

COPY --from=build-sqlite_fdw \
	/usr/share/postgresql/$PG_MAJOR/extension/sqlite_fdw* \
	/usr/share/postgresql/$PG_MAJOR/extension/
COPY --from=build-sqlite_fdw \
	/usr/lib/postgresql/$PG_MAJOR/lib/bitcode/sqlite_fdw.index.bc \
	/usr/lib/postgresql/$PG_MAJOR/lib/bitcode/sqlite_fdw.index.bc
COPY --from=build-sqlite_fdw \
	/usr/lib/postgresql/$PG_MAJOR/lib/bitcode/sqlite_fdw \
	/usr/lib/postgresql/$PG_MAJOR/lib/bitcode/sqlite_fdw
COPY --from=build-sqlite_fdw \
	/usr/lib/postgresql/$PG_MAJOR/lib/sqlite_fdw.so \
	/usr/lib/postgresql/$PG_MAJOR/lib/sqlite_fdw.so

COPY --from=build-oracle_fdw \
	/usr/share/postgresql/$PG_MAJOR/extension/oracle_fdw* \
	/usr/share/postgresql/$PG_MAJOR/extension/
COPY --from=build-oracle_fdw \
	/usr/share/doc/postgresql-doc-$PG_MAJOR/extension/README.oracle_fdw \
	/usr/share/doc/postgresql-doc-$PG_MAJOR/extension/README.oracle_fdw
COPY --from=build-oracle_fdw \
	/usr/lib/postgresql/$PG_MAJOR/lib/oracle_fdw.so \
	/usr/lib/postgresql/$PG_MAJOR/lib/oracle_fdw.so
COPY --from=build-oracle_fdw  ${ORACLE_HOME}  ${ORACLE_HOME}

RUN echo ${ORACLE_HOME} > /etc/ld.so.conf.d/oracle_instantclient.conf && \
	ldconfig

COPY ./conf.sh  /docker-entrypoint-initdb.d/z_conf.sh
