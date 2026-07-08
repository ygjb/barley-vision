#!/bin/sh
set -eu

recordings_dir="${RECORDINGS_DIR:-/recordings}"
api_dir="${WEB_API_DIR:-/www/api}"
mkdir -p "$api_dir"

total_bytes="$(du -sb "$recordings_dir" 2>/dev/null | awk '{print $1}')"
free_bytes="$(df -B1 "$recordings_dir" 2>/dev/null | awk 'NR==2 {print $4}')"
recording_count="$(find "$recordings_dir" -type f -name '*.mp4' 2>/dev/null | wc -l | tr -d ' ')"
snapshot_count="$(find "$recordings_dir" -type f -name '*.jpg' 2>/dev/null | wc -l | tr -d ' ')"
camera_present="false"
motion_running="false"

if [ -e /dev/video0 ]; then
  camera_present="true"
fi
if pgrep motion >/dev/null 2>&1; then
  motion_running="true"
fi

cat > "$api_dir/status.json" <<EOF
{
  "generatedAt": "$(date -Iseconds)",
  "storage": {
    "recordingsBytes": ${total_bytes:-0},
    "freeBytes": ${free_bytes:-0},
    "recordingCount": ${recording_count:-0},
    "snapshotCount": ${snapshot_count:-0}
  },
  "camera": {
    "device": "/dev/video0",
    "present": $camera_present
  },
  "motion": {
    "running": $motion_running,
    "streamPath": "/stream"
  }
}
EOF
