FROM debian:latest AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

FROM base AS live-build

RUN apt-get update -yq \
  && apt-get install -yq \
  --no-install-recommends \
  --no-install-suggests \
    binutils \
    live-build \
    patch \
    xz-utils\
    zstd \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
  && truncate -s 0 /var/log/*log

COPY patches/ /patches/

RUN find /patches -type f -name '*.patch' -print0 | sort -z | xargs -t -0 -n 1 patch -p0 -i \
  && rm -rf /patches/

FROM live-build AS ubuntu-live-build

COPY debs/ /debs/

RUN dpkg -i /debs/*.deb \
  && rm -rf /debs/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/usr/bin/env", "bash", "/entrypoint.sh" ]

FROM ubuntu-live-build AS ubuntu-live-build-runtime
