#!/bin/sh
set -e

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

# create the FTP-only user if it doesn't already exist —
# same idempotency pattern MariaDB's entrypoint uses for its own init
if ! id "$FTP_USER" >/dev/null 2>&1; then
  useradd -d /var/www/html "$FTP_USER"
  echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
fi

exec vsftpd /etc/vsftpd.conf