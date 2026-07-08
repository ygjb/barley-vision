#!/bin/sh
set -eu

recordings_dir="${RECORDINGS_DIR:-/recordings}"
api_dir="${WEB_API_DIR:-/www/api}"
mkdir -p "$api_dir"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

find "$recordings_dir" -type f \( -name '*.mp4' -o -name '*.jpg' \) -printf '%T@ %s %P\n' \
  | sort -nr \
  | awk '
    BEGIN { print "["; first=1 }
    {
      mtime=$1; size=$2; $1=""; $2=""; sub(/^  /, "", $0); path=$0
      kind=(path ~ /\.mp4$/ ? "recording" : "snapshot")
      if (!first) printf ",\n"; first=0
      gsub(/"/, "\\\"", path)
      printf "  {\"path\":\"%s\",\"kind\":\"%s\",\"size\":%d,\"mtime\":%d}", path, kind, size, mtime
    }
    END { print "\n]" }
  ' > "$tmp"

mv "$tmp" "$api_dir/recordings.json"
