#!/bin/sh
set -e

DB_DATA_DIR=/var/lib/mysql

# is the list of files in the data directory empty? ➜ 
if [ -z "$(ls -A "$DB_DATA_DIR" 2>/dev/null)" ]; then
	echo "No existing database found — initializing..."
	mariadb-install-db --user=mysql --datadir="$DB_DATA_DIR" >/dev/null
	# reading the passwords from Docker secrets
	DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
	DB_PASSWORD=$(cat /run/secrets/db_password)

	mkdir -p /run/mysqld
	chown mysql:mysql /run/mysqld
	
	mysqld --user=mysql --bootstrap <<-EOSQL
    USE mysql;
    FLUSH PRIVILEGES;
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
    CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
	EOSQL

	echo "Initialization complete."
fi

exec mysqld --user=mysql