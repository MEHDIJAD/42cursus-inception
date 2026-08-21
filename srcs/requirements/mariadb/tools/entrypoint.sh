#!/bin/sh
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

DB_DATA_DIR=/var/lib/mysql

# is the list of files in the data directory empty? ➜ 
if [ -z "$(ls -A "$DB_DATA_DIR" 2>/dev/null)" ]; then
	printf "${YELLOW}[mariadb]${NC} No existing database found — initializing...\n"
	mariadb-install-db --user=mysql --datadir="$DB_DATA_DIR" >/dev/null
	# reading the passwords from Docker secrets
	DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
	DB_PASSWORD=$(cat /run/secrets/db_password)

	mysqld --user=mysql --bootstrap <<-EOSQL
    USE mysql;
    FLUSH PRIVILEGES;
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
    CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
	EOSQL

	printf "${GREEN}[mariadb]${NC} Initialization complete.\n"
fi

exec mysqld --user=mysql