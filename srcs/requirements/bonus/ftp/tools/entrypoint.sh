#!/bin/sh
set -e

mkdir -p /var/run/vsftpd/empty

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

if ! id "$FTP_USER" >/dev/null 2>&1; then
  useradd -u 33 -o -d /var/www/html "$FTP_USER"
  echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
fi

exec vsftpd /etc/vsftpd.conf
