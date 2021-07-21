# based on https://github.com/just-containers/base-alpine/blob/master/Dockerfile

FROM alpine:latest

# TARGETARCH will be amd64 or arm64
ARG TARGETARCH

RUN \
  # dynamic S6ARCH based on https://github.com/BretFisher/multi-platform-docker-build
  case ${TARGETARCH} in \
    "amd64") S6ARCH="amd64";; \
    "arm64") S6ARCH="aarch64";; \
  esac && \
  # install alpine packages
  apk --no-cache add \
    curl \
    nginx \
    php8-brotli \
    php8-cli \
    php8-ctype \
    php8-curl \
    php8-dom \
    php8-exif \
    php8-fileinfo \
    php8-fpm \
    php8-gd \
    php8-iconv \
    php8-intl \
    php8-ldap \
    php8-mbstring \
    php8-mysqli \
    php8-mysqlnd \
    php8-opcache \
    php8-openssl \
    php8-pcntl \
    php8-pdo_mysql \
    php8-pdo_pgsql \
    php8-pdo_sqlite \
    php8-pecl-apcu \
    php8-pecl-imagick \
    php8-pecl-lzf \
    php8-pecl-oauth \
    php8-pecl-redis \
    php8-pecl-uploadprogress \
    php8-pecl-uuid \
    php8-pgsql \
    php8-posix \
    php8-session \
    php8-simplexml \
    php8-sqlite3 \
    php8-xml \
    php8-xmlwriter \
    php8-zip && \
  # add www-data user
  adduser -u 82 -D -S -H -g 'www-data' -h /var/www -G www-data www-data && \
  # reduce nginx worker processes to 1
  sed -i 's/^worker_processes auto;$/worker_processes 1;/' /etc/nginx/nginx.conf && \
  # use s6 for nginx access log
  sed -i 's#^	access_log /var/log/nginx/access.log main;$#	access_log /var/run/s6/nginx-access-log-fifo main;#' /etc/nginx/nginx.conf && \
  # use s6 for nginx error log
  sed -i 's#^error_log /var/log/nginx/error.log warn;$#error_log /var/run/s6/nginx-error-log-fifo warn;#' /etc/nginx/nginx.conf && \
  # use s6 for phpfpm error log
  sed -i 's#^;error_log = log/php8/error.log$#error_log = /var/run/s6/phpfpm-error-log-fifo#' /etc/php8/php-fpm.conf && \
  # make env vars available to phpfpm
  sed -i 's/^;clear_env = no$/clear_env = no/' /etc/php8/php-fpm.d/www.conf && \
  # run phpfpm as the www-data user
  sed -i "s/user = nobody$/user = www-data/" /etc/php8/php-fpm.d/www.conf && \
  sed -i "s/group = nobody$/group = www-data/" /etc/php8/php-fpm.d/www.conf && \
  # download s6-overlay to /
  curl -LS https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-${S6ARCH}.tar.gz | \
    tar zx -C /

# add files from our git repo
ADD rootfs /

# init
ENTRYPOINT [ "/init" ]
