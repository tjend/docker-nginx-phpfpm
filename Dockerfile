# based on https://github.com/just-containers/base-alpine/blob/master/Dockerfile

# use latest alpine
ARG IMAGE=alpine:latest
FROM ${IMAGE}
ARG ARCH=amd64

RUN \
  # install alpine packages
  apk --no-cache add \
    curl \
    nginx && \
  # reduce nginx worker processes to 1
  sed -i 's/^worker_processes auto;$/worker_processes 1;/' /etc/nginx/nginx.conf && \
  # download s6-overlay to /
  curl -LS https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-${ARCH}.tar.gz | \
    tar zx -C /

# add files from our git repo
ADD rootfs /

# init
ENTRYPOINT [ "/init" ]
