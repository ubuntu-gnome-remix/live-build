FROM debian:bookworm-20240904 AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

RUN apt-get update -yq \
  && apt-get install -yq \
  --no-install-recommends \
  --no-install-suggests \
    live-build \
    patch \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
  && truncate -s 0 /var/log/*log

COPY patches/ /patches/

RUN find /patches -type f -name '*.patch' -print0 | sort -z | xargs -t -0 -n 1 patch --verbose -p0 -i \
  && rm -rf /patches/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/usr/bin/env", "bash", "/entrypoint.sh" ]

FROM base AS runtime
