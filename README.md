Build a nginx/php-fpm/s6 docker image based on https://github.com/just-containers/s6-overlay.

Allows overriding the phpfpm opcache validate timestamps config value using the
PHPFPM_OPCACHE_VALIDATE_TIMESTAMPS env var. This is useful for performance
reasons if you never update php files inside your docker image, or if you delete
the opcache after updates(like wordpress does).
