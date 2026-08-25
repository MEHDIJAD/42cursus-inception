# requirements/bonus/adminer/Dockerfile
FROM alpine:3.20

RUN apk add --no-cache php83 php83-mysqli php83-session

# the one file Adminer actually is — downloaded once at build time,
# baked into the image, not fetched at runtime
ADD https://www.adminer.org/latest.php /var/www/html/adminer.php

WORKDIR /var/www/html
EXPOSE 8081

# php's own built-in server, run in the foreground as PID 1 — acceptable
# here because Adminer is a single small script, not a full application;
# the "no built-in PHP server" rule in this project targets the WordPress
# container specifically, where a real php-fpm setup is required instead
CMD ["php83", "-S", "0.0.0.0:8081", "adminer.php"]
