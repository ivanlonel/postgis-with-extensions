FROM postgis/postgis:latest

# Install pg_cron, mysql_fdw, ogr_fdw, pgaudit, pgpcre, pgtap, pldebugger, plpgsql_check and tdw_fdw
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        postgresql-$PG_MAJOR-cron \
        postgresql-$PG_MAJOR-mysql-fdw \
        postgresql-$PG_MAJOR-ogr-fdw \
        postgresql-$PG_MAJOR-orafce \
        postgresql-$PG_MAJOR-pgaudit \
        postgresql-$PG_MAJOR-pgpcre \
        postgresql-$PG_MAJOR-pgtap \
        postgresql-$PG_MAJOR-pldebugger \
        postgresql-$PG_MAJOR-plpgsql-check \
        postgresql-$PG_MAJOR-tds-fdw && \
    apt-get purge -y --auto-remove

RUN localedef -i pt_BR -c -f UTF-8 -A /usr/share/locale/locale.alias pt_BR.UTF-8
ENV LANG pt_BR.utf8



# TO-DO:
# Rewrite this file using milti-stage build to avoid explicit cleanup
# See what other modifications each extension requires me to do, like changing something on postgresql.conf 
# Look into this "alien" used to install oracle client in this other image: https://github.com/TessTea/Postgres_fdw/blob/master/Dockerfile



# Install sqlite_fdw
ARG SQLITE_FDW_VERSION=1.3.1
ARG SQLITE_FDW_URL=https://github.com/pgspider/sqlite_fdw/archive/v${SQLITE_FDW_VERSION}.tar.gz
ARG SOURCE_FILES=/tmp/sqlite_fdw

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libsqlite3-dev \
        wget \
        ca-certificates \
        make \
        gcc \
        cmake \
        pkg-config \
        postgresql-server-dev-$PG_MAJOR \
        libssl-dev \
        libzstd-dev && \
    # download SQLITE_FDW source files
    mkdir -p ${SOURCE_FILES} && \
    wget -O - ${SQLITE_FDW_URL} | tar -zx -C ${SOURCE_FILES} --strip-components=1 && \
    cd ${SOURCE_FILES} && \
    # compilation
    make USE_PGXS=1 && \
    make USE_PGXS=1 install && \
    # cleanup
    apt-get purge -y --auto-remove\
        libsqlite3-dev \
        wget \
        ca-certificates \
        make \
        gcc \
        cmake \
        pkg-config \
        postgresql-server-dev-$PG_MAJOR \
        libssl-dev \
        libzstd-dev && \
    cd - && \
    rm -rf ${SOURCE_FILES}



# Latest version
ARG ORACLE_CLIENT_URL=https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linuxx64.zip
ARG ORACLE_SQLPLUS_URL=https://download.oracle.com/otn_software/linux/instantclient/instantclient-sqlplus-linuxx64.zip
ARG ORACLE_SDK_URL=https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linuxx64.zip

# Version specific setup
#ARG ORACLE_CLIENT_VERSION=21.1.0.0.0
#ARG ORACLE_CLIENT_PATH=211000
#ARG ORACLE_CLIENT_URL=https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_CLIENT_PATH}/instantclient-basic-linux.x64-${ORACLE_CLIENT_VERSION}dbru.zip
#ARG ORACLE_SQLPLUS_URL=https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_CLIENT_PATH}/instantclient-sqlplus-linux.x64-${ORACLE_CLIENT_VERSION}dbru.zip
#ARG ORACLE_SDK_URL=https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_CLIENT_PATH}/instantclient-sdk-linux.x64-${ORACLE_CLIENT_VERSION}dbru.zip

ENV ORACLE_HOME=/usr/lib/oracle/client

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        unzip && \
    # instant client
    wget -O instant_client.zip ${ORACLE_CLIENT_URL} && \
    unzip instant_client.zip && \
    # sqlplus
    wget -O sqlplus.zip ${ORACLE_SQLPLUS_URL} && \
    unzip sqlplus.zip && \
    # sdk
    wget -O sdk.zip ${ORACLE_SDK_URL} && \
    unzip sdk.zip && \
    # install
    mkdir -p ${ORACLE_HOME} && \
    mv instantclient*/* ${ORACLE_HOME} && \
    rm -r instantclient* && \
    rm instant_client.zip sqlplus.zip sdk.zip && \
    # required runtime libs: libaio
    apt-get install -y --no-install-recommends libaio1 && \
    apt-get purge -y --auto-remove

ENV PATH $PATH:${ORACLE_HOME}

ARG ORACLE_FDW_VERSION=2_3_0
ARG ORACLE_FDW_URL=https://github.com/laurenz/oracle_fdw/archive/ORACLE_FDW_${ORACLE_FDW_VERSION}.tar.gz
ARG SOURCE_FILES=tmp/oracle_fdw

    # oracle_fdw
RUN mkdir -p ${SOURCE_FILES} && \
    wget -O - ${ORACLE_FDW_URL} | tar -zx --strip-components=1 -C ${SOURCE_FILES} && \
    cd ${SOURCE_FILES} && \
    # install
    apt-get install -y --no-install-recommends \
        make \
        gcc \
        postgresql-server-dev-$PG_MAJOR && \
    make && \
    make install && \
    echo ${ORACLE_HOME} > /etc/ld.so.conf.d/oracle_instantclient.conf && \
    ldconfig && \
    # cleanup
    apt-get purge -y --auto-remove \
        postgresql-server-dev-$PG_MAJOR \
        gcc \
        make
