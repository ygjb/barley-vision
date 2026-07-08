#!/bin/sh
set -eu

movie_path="${1:?movie path is required}"
recordings_dir="${RECORDINGS_DIR:-/recordings}"
api_dir="${WEB_API_DIR:-/www/api}"
url_base="${RECORDINGS_URL_BASE:-https://barley.boily.me/recordings}"
smtp_to="${SMTP_TO:-}"
smtp_from="${SMTP_FROM:-}"

if [ -z "$smtp_to" ] || [ -z "$smtp_from" ]; then
  echo "SMTP_TO and SMTP_FROM must be set" >&2
  exit 1
fi

relative_path="${movie_path#"$recordings_dir"/}"
event_dir="$(dirname "$movie_path")"
event_base="$(basename "$movie_path" .mp4)"
snapshot_path="$(find "$event_dir" -maxdepth 1 -type f -name "${event_base%.*}*.jpg" -o -name "*.jpg" | sort | tail -n 1)"
timestamp="$(date -Iseconds)"
duration="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$movie_path" 2>/dev/null | awk '{printf "%.1f seconds", $1}')"
recording_url="$url_base/$relative_path"
boundary="barley-vision-$(date +%s)"

tmp_mail="$(mktemp)"
trap 'rm -f "$tmp_mail"' EXIT

{
  printf 'From: %s\n' "$smtp_from"
  printf 'To: %s\n' "$smtp_to"
  printf 'Subject: Motion detected\n'
  printf 'MIME-Version: 1.0\n'
  printf 'Content-Type: multipart/mixed; boundary="%s"\n\n' "$boundary"
  printf -- '--%s\n' "$boundary"
  printf 'Content-Type: text/plain; charset=UTF-8\n\n'
  printf 'Motion detected\n\n'
  printf 'Timestamp: %s\n' "$timestamp"
  printf 'Duration: %s\n' "${duration:-unknown}"
  printf 'Recording: %s\n\n' "$recording_url"

  if [ -n "${snapshot_path:-}" ] && [ -f "$snapshot_path" ]; then
    printf -- '--%s\n' "$boundary"
    printf 'Content-Type: image/jpeg\n'
    printf 'Content-Transfer-Encoding: base64\n'
    printf 'Content-Disposition: attachment; filename="%s"\n\n' "$(basename "$snapshot_path")"
    base64 "$snapshot_path"
    printf '\n'
  fi

  printf -- '--%s--\n' "$boundary"
} > "$tmp_mail"

msmtp "$smtp_to" < "$tmp_mail"
"$(dirname "$0")/index-recordings.sh" || true
"$(dirname "$0")/write-status.sh" || true
