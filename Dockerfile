FROM veupathdb/vdi-plugin-base:8.1.0-rc9

ARG LIB_GIT_COMMIT_SHA=099844ec5005e7fab95358b2b538dbe4f0581572

RUN apt-get update \
  && apt-get install -y git python3 python3-numpy python3-pybigwig \
  && apt-get clean

RUN git clone https://github.com/VEuPathDB/lib-vdi-plugin-rnaseq.git \
  && cd lib-vdi-plugin-rnaseq \
  && git checkout $LIB_GIT_COMMIT_SHA \
  && mkdir -p /opt/veupathdb/lib/perl /opt/veupathdb/bin \
  && cp lib/perl/BigWigUtils.pm /opt/veupathdb/lib/perl \
  && cp bin/* /opt/veupathdb/bin \
  && rm -rf lib-vdi-plugin-rnaseq

COPY bin/ /opt/veupathdb/bin

RUN chmod +x /opt/veupathdb/bin/*
