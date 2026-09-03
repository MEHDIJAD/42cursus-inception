# requirements/bonus/adminer/Dockerfile
FROM alpine:3.20

RUN apk add --no-cache php83 php83-mysqli php83-session

# the one file Adminer actually is — downloaded once at build time,
# baked into the image, not fetched at runtime
ADD https://www.adminer.org/latest.php /var/www/html/adminer.php

WORKDIR /var/www/html
EXPOSE 8081

CMD ["php83", "-S", "0.0.0.0:8081", "adminer.php"]
