#!/bin/sh
set -e

mkdir -p /var/run/vsftpd/empty

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

if ! id "$FTP_USER" >/dev/null 2>&1; then
  # -u 33 -o: reuse www-data's exact UID (33 is already taken by www-data
  # itself, -o allows a non-unique UID on purpose) — this makes every
  # file this FTP user touches behave as if www-data touched it, matching
  # the ownership WordPress's own entrypoint already set on this volume
  useradd -u 33 -o -d /var/www/html "$FTP_USER"
  echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
fi

exec vsftpd /etc/vsftpd.conf
