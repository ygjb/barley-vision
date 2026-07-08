#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USERS_FILE="${BARLEY_USERS_FILE:-$PROJECT_DIR/caddy/users.htpasswd}"
REMOTE="${BARLEY_REMOTE:-yboily@barley-vision}"
REMOTE_DIR="${BARLEY_REMOTE_DIR:-/srv/barley-vision}"
CADDY_IMAGE="${CADDY_IMAGE:-docker.io/library/caddy:2-alpine}"

usage() {
  cat <<'EOF'
Usage:
  scripts/manage-caddy-users.sh list
  scripts/manage-caddy-users.sh add USERNAME
  scripts/manage-caddy-users.sh delete USERNAME
  scripts/manage-caddy-users.sh deploy

Environment overrides:
  BARLEY_REMOTE      SSH target, default yboily@barley-vision
  BARLEY_REMOTE_DIR  Remote project directory, default /srv/barley-vision
  BARLEY_USERS_FILE  Local users file, default ./caddy/users.htpasswd
  CADDY_IMAGE        Caddy image used for hashing, default docker.io/library/caddy:2-alpine
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

validate_username() {
  local username="$1"
  [[ "$username" =~ ^[A-Za-z0-9._-]+$ ]] || die "username must contain only letters, numbers, dot, underscore, or dash"
}

ensure_users_file() {
  mkdir -p "$(dirname "$USERS_FILE")"
  touch "$USERS_FILE"
  chmod 600 "$USERS_FILE"
}

prompt_password() {
  local first second
  read -r -s -p "Password: " first
  echo
  read -r -s -p "Confirm password: " second
  echo
  [[ -n "$first" ]] || die "password cannot be empty"
  [[ "$first" == "$second" ]] || die "passwords do not match"
  printf '%s\n' "$first"
}

hash_password() {
  local password="$1" hash encoded
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    if hash="$(printf '%s\n' "$password" | docker run --rm -i "$CADDY_IMAGE" caddy hash-password 2>/dev/null)"; then
      printf '%s\n' "$hash"
      return
    fi
    echo "local Docker hashing failed; retrying on $REMOTE" >&2
  fi
  encoded="$(printf '%s' "$password" | base64 | tr -d '\n')"
  ssh "$REMOTE" "docker run --rm -e PASSWORD_B64='$encoded' '$CADDY_IMAGE' sh -c 'password=\$(printf %s \"\$PASSWORD_B64\" | base64 -d); caddy hash-password --plaintext \"\$password\"'"
}

write_user() {
  local username="$1" hash="$2" tmp
  tmp="$(mktemp)"
  awk -v user="$username" '$1 != user { print }' "$USERS_FILE" > "$tmp"
  printf '%s %s\n' "$username" "$hash" >> "$tmp"
  sort -o "$tmp" "$tmp"
  install -m 600 "$tmp" "$USERS_FILE"
  rm -f "$tmp"
}

delete_user() {
  local username="$1" tmp remaining
  tmp="$(mktemp)"
  awk -v user="$username" '$1 != user { print }' "$USERS_FILE" > "$tmp"
  remaining="$(awk 'NF { count++ } END { print count + 0 }' "$tmp")"
  [[ "$remaining" -gt 0 ]] || {
    rm -f "$tmp"
    die "refusing to delete the last user"
  }
  install -m 600 "$tmp" "$USERS_FILE"
  rm -f "$tmp"
}

deploy_users() {
  ensure_users_file
  [[ -s "$USERS_FILE" ]] || die "$USERS_FILE is empty; add at least one user first"
  ssh "$REMOTE" "mkdir -p '$REMOTE_DIR/caddy'"
  rsync -az --chmod=F600 "$USERS_FILE" "$REMOTE:$REMOTE_DIR/caddy/users.htpasswd"
  ssh "$REMOTE" "cd '$REMOTE_DIR' && docker compose --env-file .env.local up -d --force-recreate caddy"
}

cmd="${1:-}"
case "$cmd" in
  list)
    ensure_users_file
    awk 'NF { print $1 }' "$USERS_FILE"
    ;;
  add)
    username="${2:-}"
    [[ -n "$username" ]] || die "missing username"
    validate_username "$username"
    ensure_users_file
    password="$(prompt_password)"
    hash="$(hash_password "$password")"
    write_user "$username" "$hash"
    deploy_users
    echo "updated user: $username"
    ;;
  delete|del|remove|rm)
    username="${2:-}"
    [[ -n "$username" ]] || die "missing username"
    validate_username "$username"
    ensure_users_file
    delete_user "$username"
    deploy_users
    echo "deleted user: $username"
    ;;
  deploy)
    deploy_users
    echo "deployed users"
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
