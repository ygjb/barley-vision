#!/bin/sh
set -eu

recordings_dir="${RECORDINGS_DIR:-/media/yboily/New Volume/recordings}"
max_bytes="${MAX_RECORDING_BYTES:-34359738368}"
min_age_hours="${MIN_RECORDING_AGE_HOURS:-24}"

if [ ! -d "$recordings_dir" ]; then
  echo "recordings directory not found: $recordings_dir" >&2
  exit 1
fi

current_bytes="$(du -sb "$recordings_dir" | awk '{print $1}')"
if [ "$current_bytes" -le "$max_bytes" ]; then
  echo "recordings use $current_bytes bytes, under limit $max_bytes"
  exit 0
fi

find "$recordings_dir" -type f \( -name '*.mp4' -o -name '*.jpg' \) -mmin +"$((min_age_hours * 60))" -printf '%T@ %p\n' \
  | sort -n \
  | while read -r _ file_path; do
      current_bytes="$(du -sb "$recordings_dir" | awk '{print $1}')"
      if [ "$current_bytes" -le "$max_bytes" ]; then
        break
      fi
      echo "deleting $file_path"
      rm -f "$file_path"
    done

find "$recordings_dir" -type d -empty -delete
