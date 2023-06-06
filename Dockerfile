# based on https://github.com/just-containers/base-alpine/blob/master/Dockerfile

FROM docker.io/alpine:latest

# TARGETARCH will be amd64 or arm64
ARG TARGETARCH

# target the latest php version in alpine
ARG PHP_VERSION="82"

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
    php${PHP_VERSION}-brotli \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-ctype \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-dom \
    php${PHP_VERSION}-exif \
    php${PHP_VERSION}-fileinfo \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-iconv \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-mysqli \
    php${PHP_VERSION}-mysqlnd \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-openssl \
    php${PHP_VERSION}-pcntl \
    php${PHP_VERSION}-pdo_mysql \
    php${PHP_VERSION}-pdo_pgsql \
    php${PHP_VERSION}-pdo_sqlite \
    php${PHP_VERSION}-pecl-apcu \
    php${PHP_VERSION}-pecl-imagick \
    php${PHP_VERSION}-pecl-lzf \
    php${PHP_VERSION}-pecl-redis \
    php${PHP_VERSION}-pecl-uploadprogress \
    php${PHP_VERSION}-pecl-uuid \
    php${PHP_VERSION}-pgsql \
    php${PHP_VERSION}-posix \
    php${PHP_VERSION}-session \
    php${PHP_VERSION}-simplexml \
    php${PHP_VERSION}-sqlite3 \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-xmlwriter \
    php${PHP_VERSION}-zip && \
  # add www-data user
  adduser -u 82 -D -S -H -g 'www-data' -h /var/www -G www-data www-data && \
  # reduce nginx worker processes to 1
  sed -i 's/^worker_processes auto;$/worker_processes 1;/' /etc/nginx/nginx.conf && \
  # use s6 for nginx access log
  sed -i 's#^	access_log /var/log/nginx/access.log main;$#	access_log /var/run/s6/nginx-access-log-fifo main;#' /etc/nginx/nginx.conf && \
  # use s6 for nginx error log
  sed -i 's#^error_log /var/log/nginx/error.log warn;$#error_log /var/run/s6/nginx-error-log-fifo warn;#' /etc/nginx/nginx.conf && \
  # symlink php paths/executables without version
  ln -s /etc/php* /etc/php && \
  ln -s /var/log/php* /var/log/php && \
  ln -s /usr/bin/php* /usr/bin/php && \
  ln -s /usr/sbin/php-fpm* /usr/sbin/php-fpm && \
  # use s6 for phpfpm error log
  sed -i 's#^;error_log = log/php.*/error.log$#error_log = /var/run/s6/phpfpm-error-log-fifo#' /etc/php/php-fpm.conf && \
  # make env vars available to phpfpm
  sed -i 's/^;clear_env = no$/clear_env = no/' /etc/php/php-fpm.d/www.conf && \
  # run phpfpm as the www-data user
  sed -i "s/user = nobody$/user = www-data/" /etc/php/php-fpm.d/www.conf && \
  sed -i "s/group = nobody$/group = www-data/" /etc/php/php-fpm.d/www.conf && \
  # set upload file size and max post size
  echo "php_admin_value[upload_max_filesize] = 32M" >> /etc/php/php-fpm.d/www.conf && \
  echo "php_admin_value[post_max_size] = 64M" >> /etc/php/php-fpm.d/www.conf && \
  # set memory limit
  sed -i "s/.*php_admin_value\[memory_limit\] = .*$/php_admin_value[memory_limit] = 128M/" /etc/php/php-fpm.d/www.conf && \
  # set timeouts
  echo "php_admin_value[max_execution_time] = 120" >> /etc/php/php-fpm.d/www.conf && \
  echo "php_admin_value[max_input_time] = 300" >> /etc/php/php-fpm.d/www.conf && \
  # download s6-overlay to /
  curl -LS https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-${S6ARCH}.tar.gz | \
    tar zx -C /

# add files from our git repo
ADD rootfs /

# init
ENTRYPOINT [ "/init" ]
