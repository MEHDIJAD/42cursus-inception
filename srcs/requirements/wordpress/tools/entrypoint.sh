#!/bin/sh
set -e

WP_PATH=/var/www/html

i=0
until nc -z "$WORDPRESS_DB_HOST" 3306 2>/dev/null || [ "$i" -ge 30 ]; do
  i=$((i + 1))
  printf "${YELLOW}[wordpress]${NC} Waiting for database... ($i/30)\n"
  sleep 1
done


if [ "$i" -ge 30 ]; then
  printf "${RED}[wordpress]${NC} Database never became reachable — aborting.\n" >&2
  exit 1
fi


if [ ! -f "$WP_PATH/wp-config.php" ]; then
  printf "${YELLOW}[wordpress]${NC} No WordPress install found — setting up...\n"

  DB_PASSWORD=$(cat /run/secrets/db_password)

  . /run/secrets/credentials


  case "$(echo "$WP_ADMIN_USER" | tr 'A-Z' 'a-z')" in
    *admin*|*administrator*)
      echo "WP_ADMIN_USER must not contain 'admin' or 'administrator'" >&2
      exit 1
      ;;
  esac

  wp core download --path="$WP_PATH" --allow-root

  wp config create \
    --path="$WP_PATH" \
    --dbname="$MYSQL_DATABASE" \
    --dbuser="$MYSQL_USER" \
    --dbpass="$DB_PASSWORD" \
    --dbhost="$WORDPRESS_DB_HOST" \
    --allow-root

  wp core install \
    --path="$WP_PATH" \
    --url="https://$DOMAIN_NAME" \
    --title="Inception" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --allow-root

  wp user create "$WP_USER" "$WP_USER_EMAIL" \
    --path="$WP_PATH" \
    --role=author \
    --user_pass="$WP_USER_PASSWORD" \
    --allow-root

  printf "${GREEN}[wordpress]${NC} WordPress install complete.\n"
fi

chown -R www-data:www-data "$WP_PATH"

wp config set WP_REDIS_HOST "$REDIS_HOST" --path=/var/www/html --allow-root
wp config set WP_REDIS_PORT "$REDIS_PORT" --path=/var/www/html --allow-root --raw

wp plugin install redis-cache --activate --path=/var/www/html --allow-root
wp redis enable --path=/var/www/html --allow-root

exec php-fpm8.2 --nodaemonize