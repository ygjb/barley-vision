#!/bin/sh
set -eu

cat > "$HOME/.msmtprc" <<EOF
defaults
auth           on
tls            ${SMTP_TLS:-on}
tls_starttls   ${SMTP_STARTTLS:-on}
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        -

account        default
host           ${SMTP_HOST:-}
port           ${SMTP_PORT:-587}
from           ${SMTP_FROM:-}
user           ${SMTP_USER:-}
password       ${SMTP_PASSWORD:-}
EOF
chmod 600 "$HOME/.msmtprc"

mkdir -p "${RECORDINGS_DIR:-/recordings}" "${WEB_API_DIR:-/www/api}"
/usr/local/barley-vision/scripts/index-recordings.sh || true
/usr/local/barley-vision/scripts/write-status.sh || true

exec "$@"
