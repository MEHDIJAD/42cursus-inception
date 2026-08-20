#!/bin/sh
set -e

WP_PATH=/var/www/html

# --- 1. Wait for MariaDB, bounded — not an infinite loop ---
# Containers can start in any order. mariadb might still be running
# its own first-time init (Lesson 4) when this container starts.
# This retries a fixed number of times, then gives up loudly.
i=0
until nc -z "$WORDPRESS_DB_HOST" 3306 2>/dev/null || [ "$i" -ge 30 ]; do
  i=$((i + 1))
  echo "Waiting for database... ($i/30)"
  sleep 1
done


if [ "$i" -ge 30 ]; then
  echo "Database never became reachable — aborting." >&2
  exit 1
fi

# --- 2. Only install once — the volume may already hold a real site ---
if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "No WordPress install found — setting up..."

  DB_PASSWORD=$(cat /run/secrets/db_password)
  # credentials.txt: KEY=VALUE lines, sourced directly as shell vars.
  # This project's own convention — the subject doesn't mandate a
  # format, only that the file exists and holds real secret values.
  . /run/secrets/credentials.txt

  # --- 3. Reject a banned admin username before it's ever used ---
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

  echo "WordPress install complete."
fi

chown -R www-data:www-data "$WP_PATH"

# --nodaemonize: without this, php-fpm forks into the background
# and this script (PID 1) exits — the container would stop
# immediately even though php-fpm is technically still "running".
exec php-fpm8.2 --nodaemonize