# Security Considerations

- Only Caddy publishes host ports. Motion is reachable only on the Docker network.
- The whole site is protected with Caddy Basic Authentication.
- Use Caddy password hashes, not plaintext passwords.
- Keep `.env.local` out of Git because it contains SMTP credentials and password hashes.
- The Caddy container runs read-only with `no-new-privileges`.
- The Motion container drops Linux capabilities and only receives `/dev/video0`.
- The Docker socket is not mounted into any container.
- HTTPS certificates are issued by Let's Encrypt through Caddy.
- Router forwarding should be limited to TCP ports 80 and 443.
