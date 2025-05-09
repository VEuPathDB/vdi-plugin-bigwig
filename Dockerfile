FROM foxcapades/ubuntu-corretto:24.10-jdk21

ENV LANG=en_US.UTF-8 \
  JVM_MEM_ARGS="-Xms16m -Xmx64m" \
  JVM_ARGS="" \
  TZ="America/New_York" \
  PATH=/opt/veupathdb/bin:$PATH

RUN apt-get update \
  && apt-get install -y locales \
  && sed -i -e "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen \
  && dpkg-reconfigure --frontend=noninteractive locales \
  && update-locale LANG=en_US.UTF-8 \
  && apt-get install -y tzdata curl wget \
  && cp /usr/share/zoneinfo/America/New_York /etc/localtime \
  && echo ${TZ} > /etc/timezone

RUN apt-get install -y git python3 python3-numpy python3-pybigwig \
  && apt-get clean

ARG LIB_GIT_COMMIT_SHA=099844ec5005e7fab95358b2b538dbe4f0581572
RUN git clone https://github.com/VEuPathDB/lib-vdi-plugin-rnaseq.git \
  && cd lib-vdi-plugin-rnaseq \
  && git checkout $LIB_GIT_COMMIT_SHA \
  && mkdir -p /opt/veupathdb/lib/perl /opt/veupathdb/bin \
  && cp lib/perl/BigWigUtils.pm /opt/veupathdb/lib/perl \
  && cp bin/* /opt/veupathdb/bin \
  && rm -rf lib-vdi-plugin-rnaseq

COPY bin/ /opt/veupathdb/bin

RUN chmod +x /opt/veupathdb/bin/*

ARG PLUGIN_SERVER_VERSION=v8.2.0-beta.1
RUN set -o pipefail \
    && curl "https://github.com/VEuPathDB/vdi-plugin-handler-server/releases/download/${PLUGIN_SERVER_VERSION}/docker-download.sh" -Lf --no-progress-meter | bash

CMD /startup.sh