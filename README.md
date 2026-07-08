# Barley Vision

Barley Vision is a Docker-based Raspberry Pi webcam monitor for a Logitech USB camera. It provides a password-protected HTTPS dashboard, live stream, Motion-based recording, JPEG snapshots, email alerts, and FIFO cleanup for recordings stored on an external drive.

## Layout

```text
/srv/barley-vision
├── docker-compose.yml
├── Caddyfile
├── .env.local
├── motion/
├── scripts/
├── www/
├── recordings/
└── docs/
```

This repository is designed to be deployed at `/srv/barley-vision`. The recordings are stored outside the repository on the external drive at `/media/yboily/New Volume/recordings`.

## Installation

1. Install Raspberry Pi OS Bookworm, Docker, and Docker Compose.
2. Confirm the external exFAT drive is mounted at `/media/yboily/New Volume`.
3. Create the recordings directory:

```sh
sudo mkdir -p "/media/yboily/New Volume/recordings"
sudo chown -R 1000:1000 "/media/yboily/New Volume/recordings"
chmod +x scripts/*.sh motion/docker-entrypoint.sh
```

4. Copy this project to `/srv/barley-vision`.
5. Create `.env.local` from `.env.example` and fill in the values.
6. Add the first Basic Auth user:

```sh
scripts/manage-caddy-users.sh add yboily
```

7. Start the stack:

```sh
docker compose --env-file .env.local up -d --build
```

8. Forward TCP ports 80 and 443 from the router to the Raspberry Pi.

The target Pi is expected to be reachable with:

```sh
ssh yboily@barley-vision
```

See [docs/deployment.md](docs/deployment.md) for DNS notes.

## Configuration

Important `.env.local` values:

- `BARLEY_DOMAIN`: public hostname, currently `barley.boily.me`.
- `HOST_RECORDINGS_DIR`: host path for recordings, currently `/media/yboily/New Volume/recordings`.
- `NAME_CHEAP_DNS_PASSWORD`: Namecheap Dynamic DNS password for updating `barley.boily.me`.
- `LETSENCRYPT_EMAIL`: email for Let's Encrypt account notices.
- `SMTP_*`: SMTP settings used by `msmtp`.
- `MAX_RECORDING_BYTES`: recording storage limit. The default is 500 GiB.
- `MIN_RECORDING_AGE_HOURS`: files younger than this are never deleted by cleanup.

The Motion camera settings live in `motion/motion.conf`. Defaults target 1280x720 at 15 fps for reliability.

Manage Basic Auth users with:

```sh
scripts/manage-caddy-users.sh add yboily
scripts/manage-caddy-users.sh add daughter
scripts/manage-caddy-users.sh delete daughter
scripts/manage-caddy-users.sh list
```

The script prompts for passwords, hashes them with Caddy, stores only hashes in `caddy/users.htpasswd`, uploads that file to the Pi, and recreates the Caddy container. `caddy/users.htpasswd` is ignored by Git.

## Operation

Open:

```text
https://barley.boily.me
```

The dashboard includes:

- live stream
- recent motion events
- recordings browser
- storage usage
- camera and Motion status

Recordings are served from:

```text
https://barley.boily.me/recordings/
```

## Email Alerts

When Motion finishes a clip, `scripts/notify-motion.sh` sends an email with:

- subject `Motion detected`
- timestamp
- clip duration
- link to the MP4 recording
- one JPEG snapshot attachment

The MP4 recording is linked, not attached.

## Cleanup

Run cleanup manually:

```sh
docker compose --env-file .env.local exec motion /usr/local/barley-vision/scripts/cleanup-recordings.sh
```

Recommended host cron entry:

```cron
15 * * * * cd /srv/barley-vision && docker compose --env-file .env.local exec -T motion /usr/local/barley-vision/scripts/cleanup-recordings.sh >/var/log/barley-vision-cleanup.log 2>&1
```

Cleanup deletes the oldest MP4/JPEG files first when usage exceeds 500 GiB. Files newer than `MIN_RECORDING_AGE_HOURS` are kept.

## Updating

```sh
cd /srv/barley-vision
git pull
docker compose --env-file .env.local build --pull
docker compose --env-file .env.local up -d
docker compose --env-file .env.local ps
```

## Backup

Back up:

- `/srv/barley-vision/.env.local`
- `/srv/barley-vision/Caddyfile`
- `/srv/barley-vision/motion/motion.conf`
- `/media/yboily/New Volume/recordings`, if historical clips matter

Caddy certificates are stored in the named Docker volume `barley-vision_caddy_data`. They can be reissued automatically if DNS and port forwarding remain correct.

## Troubleshooting

Check containers:

```sh
docker compose --env-file .env.local ps
docker compose --env-file .env.local logs -f caddy
docker compose --env-file .env.local logs -f motion
```

Check the camera:

```sh
ls -l /dev/video0
```

Check generated UI data:

```sh
docker compose --env-file .env.local exec motion cat /www/api/status.json
docker compose --env-file .env.local exec motion cat /www/api/recordings.json
```

Test SMTP from the Motion container:

```sh
docker compose --env-file .env.local exec motion sh -lc 'printf "Subject: test\n\nBarley Vision test\n" | msmtp "$SMTP_TO"'
```

If HTTPS fails, verify that public DNS points to the home Internet connection and that the router forwards ports 80 and 443 to the Pi.

Check dynamic DNS on the Pi:

```sh
sudo systemctl status ddclient
dig @dns1.registrar-servers.com barley.boily.me A +short
```

## Architecture

See [docs/architecture.md](docs/architecture.md).

## Deployment

See [docs/deployment.md](docs/deployment.md).

## Security

See [docs/security.md](docs/security.md).
