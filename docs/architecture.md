# Architecture

```text
Internet
   |
Router forwards 80/443
   |
Raspberry Pi 4
   |
Docker Compose
   |
   +-- caddy
   |     - Public TLS endpoint
   |     - Basic authentication
   |     - Static web UI
   |     - Read-only access to recordings
   |     - Reverse proxy to Motion stream only
   |
   +-- motion
         - Owns /dev/video0
         - Detects motion
         - Writes MP4 and JPEG files to /media/yboily/New Volume/recordings
         - Sends notification emails through msmtp
         - Generates status and recordings JSON for the UI
```

Motion is never published to the host network. Caddy is the only Internet-facing service.
