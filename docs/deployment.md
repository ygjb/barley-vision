# Deployment Notes

## Raspberry Pi

The target Raspberry Pi is reachable on the local network as:

```sh
ssh yboily@barley-vision
```

Deploy the project under:

```text
/srv/barley-vision
```

The external recording storage is mounted on the Pi at:

```text
/media/yboily/New Volume
```

Use `/media/yboily/New Volume/recordings` as `HOST_RECORDINGS_DIR` in `.env.local`.

## DNS

The public domain is:

```text
barley.boily.me
```

It is currently hosted with Namecheap. Caddy only needs normal public DNS and does not require moving providers. Configure an `A` record for `barley.boily.me` that points to the public IPv4 address of the home Internet connection. If IPv6 is available and routed to the Pi, also add an `AAAA` record.

Forward TCP ports 80 and 443 from the router to the Raspberry Pi. Do not forward Motion ports.

If the home public IP changes often, use Namecheap Dynamic DNS or move DNS to a provider with an API-supported dynamic DNS updater.

## Dynamic DNS

The Pi uses `ddclient` with Namecheap Dynamic DNS to keep `barley.boily.me` pointed at the home public IPv4 address.

The active host configuration is:

```text
protocol=namecheap
server=dynamicdns.park-your-domain.com
login=boily.me
host=barley
```

Store the Namecheap Dynamic DNS password in `.env.local` as `NAME_CHEAP_DNS_PASSWORD`. The deployed `ddclient` config is `/etc/ddclient.conf` on the Pi and is readable only by root.

Useful checks:

```sh
sudo systemctl status ddclient
sudo ddclient -force -daemon=0 -noquiet -file /etc/ddclient.conf
dig @dns1.registrar-servers.com barley.boily.me A +short
```
