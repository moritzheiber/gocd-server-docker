FROM moritzheiber/alpine-base
LABEL maintainer="Moritz Heiber <hello@heiber.im>"

ARG MAJOR_VERSION="19.3.0"
ARG BATCH_VERSION="8959"
ARG GOCD_RELEASE="${MAJOR_VERSION}-${BATCH_VERSION}"
ARG GOCD_CHECKSUM="4c830c81aa5cee884287cc279edfc4d3bf5a81b266e690fa079c7265dac76030"

ENV GO_DIR="/gocd"
ENV GO_CONFIG_DIR="${GO_DIR}/config" \
  LANG="en_US.UTF8"

RUN apk --no-cache add curl unzip bash openjdk8-jre git && \
  curl -Lo /tmp/gocd.zip \
    https://download.gocd.org/binaries/${GOCD_RELEASE}/generic/go-server-${GOCD_RELEASE}.zip && \
  echo "${GOCD_CHECKSUM}  /tmp/gocd.zip" | sha256sum -c - && \
  mkdir -p /tmp/extraced && \
  unzip /tmp/gocd.zip -d /tmp/extracted && \
  mv /tmp/extracted/go-server-${MAJOR_VERSION} ${GO_DIR} && \
  addgroup -S gocd && \
  adduser -h /gocd -s /bin/sh -G gocd -SDH gocd && \
  install -d -o gocd -g gocd ${GO_CONFIG_DIR} ${GO_DIR}/runtime ${GO_DIR}/runtime/db ${GO_DIR}/runtime/artifacts && \
  apk --no-cache del --purge curl unzip && \
  rm -r /tmp/gocd.zip /tmp/extracted

ADD config/logback.xml ${GO_CONFIG_DIR}/logback.xml
ADD templates/passwd_file ${GO_DIR}/templates/passwd_file
ADD templates/cruise-config.xml ${GO_DIR}/templates/cruise-config.xml

VOLUME ["${GO_DIR}/runtime/db","${GO_DIR}/runtime/artifacts"]

EXPOSE 8153/tcp 8154/tcp
WORKDIR ${GO_DIR}/runtime
USER gocd

CMD ["gomplate","--file=/gocd/templates/cruise-config.xml","--out=/gocd/config/cruise-config.xml","--file=/gocd/templates/passwd_file","--out=/gocd/config/passwd_file","--","java","-Xms512m","-Xmx1024m","-Duser.language=en","-Djruby.rack.request.size.threshold.bytes=30000000","-Duser.country=DE","-Dcruise.config.dir=/gocd/config","-Dcruise.config.file=/gocd/config/cruise-config.xml","-Dcruise.server.port=8153","-Dcruise.server.ssl.port=8154","-server","-jar","../go.jar"]
