#!/bin/sh
set -e

mkdir -p /etc/nginx/ssl

# -x509: skip the certificate-signing-request step and self-sign directly
# -nodes: don't encrypt the private key with a passphrase (nginx can't
#         prompt for one at startup, so an encrypted key would block PID 1)
# -days 365: how long the cert is valid for
# -subj: fills in the certificate's identity fields non-interactively —
#        openssl would otherwise prompt for these one at a time
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/inception.key \
  -out /etc/nginx/ssl/inception.crt \
  -subj "/C=MA/ST=Casablanca-Settat/L=Khouribga/O=42/CN=${DOMAIN_NAME}"

exec nginx -g "daemon off;"