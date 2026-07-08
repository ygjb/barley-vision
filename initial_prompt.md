You are acting as the lead software engineer, DevOps engineer, and systems architect for this project.

# Project

Build a production-quality Raspberry Pi application called **Barley Vision**.

The purpose is to monitor our family dog while we are away.

The hardware is:

- Raspberry Pi 4
- Raspberry Pi OS (Debian Bookworm)
- Logitech HD USB webcam
- 1TB external USB drive formatted exFAT

The application should be entirely Docker-based where practical.

The finished project should be suitable for GitHub.

Use current best practices.

---

# Goals

The system should provide:

- Live webcam streaming
- Motion detection
- Motion recording
- Email notifications
- Web UI
- Authentication
- Automatic HTTPS
- Automatic recording cleanup
- Docker deployment
- Simple maintenance

---

# Public URL

The application will be publicly accessible at

    https://barley-vision.ygjb.ca

This is a public DNS record pointing to my home Internet connection.

Ports 80 and 443 will be forwarded from my router to the Raspberry Pi.

The webcam itself must NEVER be directly exposed.

Only Caddy should be Internet-facing.

---

# Authentication

Use Caddy Basic Authentication.

The entire site should require login.

Eventually there will be multiple users:

- myself
- my daughter

Passwords should be stored using Caddy password hashes.

---

# HTTPS

Use Caddy automatic Let's Encrypt certificates.

No self-signed certificates.

---

# Containers

Use Docker Compose.

Expected containers:

- Caddy
- Motion

If additional containers improve the design (mail relay, monitoring, etc.) justify them before adding them.

---

# Webcam

The webcam is a Logitech HD USB webcam available as

/dev/video0

Motion should stream at approximately

1280x720
15 fps

Optimize for reliability rather than maximum quality.

---

# Motion Detection

Use Motion.

When motion is detected:

- record an MP4 clip
- capture a JPEG snapshot
- wait until the recording is complete
- send an email notification

Motion clips should include

- a few seconds before motion
- a few seconds after motion

---

# Email

Email is the notification mechanism.

The email should include

Subject:

Motion detected

Body:

- timestamp
- duration
- link to the recording

Attach

- one JPEG snapshot

The recording itself should NOT be attached.

Instead include a URL such as

https://barley-vision.ygjb.ca/recordings/2026/07/07/example.mp4

Use SMTP.

Prefer msmtp.

Configuration should be externalized.

---

# Recording Storage

The external USB drive should be mounted at

/mnt/petcam

Store recordings there.

The application should reserve approximately

32 GB

for recordings.

When usage exceeds 32 GB

delete the oldest recordings first.

FIFO.

Never delete recent recordings.

Implement this as a cleanup script that can be run manually or by cron.

---

# Web Interface

Create a simple HTML dashboard.

Include:

Live Stream

Recent Motion Events

Recordings Browser

Storage Usage

Current Camera Status

Motion Status

The interface should be clean and responsive.

No frameworks unless necessary.

Vanilla HTML/CSS/JS is preferred.

---

# Project Structure

Create

/srv/barley-vision

containing

docker-compose.yml

Caddyfile

README.md

.env.example

motion/

scripts/

www/

recordings/

docs/

---

# Documentation

Write excellent documentation.

Include

README

Installation

Configuration

Updating

Backup

Troubleshooting

Architecture diagram

Security considerations

---

# Security

Do NOT expose Motion directly.

Do NOT expose Docker APIs.

Run containers with minimal privileges.

Store secrets in .env.

Add security headers in Caddy.

Use HTTPS only.

---

# Nice-to-have Features

Generate thumbnails for recordings.

Recent Events page.

Storage statistics.

Health check page.

System status.

Ability to download recordings.

Retention configuration.

---

# Development Style

Work incrementally.

After completing each milestone:

- explain what was done
- explain why
- suggest improvements

Prefer maintainability over cleverness.

Keep everything under version control.

Whenever possible generate production-quality code rather than prototypes.