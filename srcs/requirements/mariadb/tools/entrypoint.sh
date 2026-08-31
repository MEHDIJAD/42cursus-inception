#!/bin/sh
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

DB_DATA_DIR=/var/lib/mysql

# 0. do we have database from a previous docker compose up
if [ -z "$(ls -A "$DB_DATA_DIR" 2>/dev/null)" ]; then
	printf "${YELLOW}[mariadb]${NC} No existing database found — initializing...\n"
	# 1. create a brand new, empty database from scratch"
	mariadb-install-db --user=mysql --datadir="$DB_DATA_DIR" >/dev/null
	DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
	DB_PASSWORD=$(cat /run/secrets/db_password)

	# runs the DB server as user mysql, executes the piped-in SQL once, then exits
	mysqld --user=mysql --bootstrap <<-EOSQL
    USE mysql;
	DELETE FROM mysql.user WHERE User='';
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

# USE mysql; == switch to MariaDB's own internal mysql system database
# CREATE DATABASE = make the database itself exist. CREATE USER = make a login account exist