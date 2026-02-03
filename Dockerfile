FROM amazoncorretto:25-alpine3.22-jdk

ENV LANG=en_US.UTF-8 \
  JVM_MEM_ARGS="-Xms16m -Xmx64m" \
  JVM_ARGS="" \
  TZ="America/New_York" \
  PATH=/opt/veupathdb/bin:$PATH

RUN apk add --no-cache \
     wget git tzdata unzip make gcc netcat-openbsd musl-dev \
     curl libcurl curl-dev  \
     perl perl-dbi perl-test-nowarnings perl-dbd-pg \
     python3 python3-dev py3-pip py3-numpy \
  && cp /usr/share/zoneinfo/America/New_York /etc/localtime \
  && echo ${TZ} > /etc/timezone \
  && pip install --break-system-packages pybigwig

ARG LIB_GIT_COMMIT_SHA=9a42797b635341841b8dbe77e6bfed56c0a9fad8
RUN git clone https://github.com/VEuPathDB/lib-vdi-plugin-rnaseq.git \
  && cd lib-vdi-plugin-rnaseq \
  && git checkout $LIB_GIT_COMMIT_SHA \
  && mkdir -p /opt/veupathdb/lib/perl /opt/veupathdb/bin \
  && cp lib/perl/BigWigUtils.pm /opt/veupathdb/lib/perl \
  && cp bin/* /opt/veupathdb/bin \
  && rm -rf lib-vdi-plugin-rnaseq

COPY bin/ /opt/veupathdb/bin

RUN chmod +x /opt/veupathdb/bin/*

# VDI PLUGIN SERVER
ARG PLUGIN_SERVER_VERSION=v1.7.0-a31
RUN curl "https://github.com/VEuPathDB/vdi-service/releases/download/${PLUGIN_SERVER_VERSION}/plugin-server.tar.gz" -Lf --no-progress-meter | tar -xz

CMD PLUGIN_ID=bigwig /startup.sh
