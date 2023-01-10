FROM postgis/postgis:15-3.3 AS build

LABEL maintainer="Nate Currit"

RUN set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
       git \
       build-essential \
       make \
       cmake \
       libssl-dev \
       libkrb5-dev \
       g++ \
       autoconf \
       autotools-dev \
       libgeos-dev \
       libpq-dev \
       libproj-dev \
       libjson-c-dev \
       protobuf-c-compiler \
       xsltproc \
       libgsl-dev \
       libgslcblas0 \
       postgresql-server-dev-15 \
       python3 \
       python3-pip \
       postgresql-plpython3-15 \
       postgresql-15-pgrouting \
       postgresql-15-pgrouting-scripts \
       postgresql-15-ogr-fdw \
       postgresql-15-pointcloud \
       postgresql-15-extra-window-functions \
       postgresql-15-first-last-agg \
       pgloader \
       gdal-bin && \
    rm -rf /var/lib/apt/lists/*

RUN echo '#!/bin/bash\n/usr/bin/python3' > /usr/bin/python && \
    chmod +x /usr/bin/python && \ 
    echo '#!/bin/bash\n/usr/bin/pip3' > /usr/bin/pip && \
    chmod +x /usr/bin/pip

RUN git clone https://github.com/michelp/pgjwt && \
    git clone https://github.com/timescale/timescaledb && \
    # git clone https://github.com/MobilityDB/MobilityDB && \
    git clone --branch develop https://github.com/MobilityDB/MobilityDB && \
    mkdir /MobilityDB/build

WORKDIR /pgjwt
RUN make install

WORKDIR /timescaledb
RUN ./bootstrap
WORKDIR /timescaledb/build
RUN make && make install -j

WORKDIR /MobilityDB/build
RUN cmake .. && \
    make -j && \
    make install

WORKDIR /
RUN rm -R pgjwt && \
    rm -R timescaledb && \
    rm -R MobilityDB

RUN rm /docker-entrypoint-initdb.d/10_postgis.sh
COPY init-postgis-db.sh /docker-entrypoint-initdb.d/10-init-postgis-db.sh
