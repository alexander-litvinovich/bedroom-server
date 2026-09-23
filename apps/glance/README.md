# Glance

Home dashboard with Helsinki weather, a 24-hour clock, server stats, Docker container status, and links to deployed services. Its configuration is tracked in `config/glance.yml`; no credentials are required.

The stats widget reports CPU and memory from the local host and shows the system filesystem. Glance runs in Docker, so other host mountpoints and some hardware sensors will not appear unless separately exposed to the container. The Docker widget lists containers from the host's Docker socket. Mounting that socket gives Glance broad Docker access even with `:ro`; restrict access to the dashboard accordingly.

## Start

From this directory on the server:

```bash
docker compose config
docker compose up -d
docker compose logs --tail=100 glance
```

Check `http://192.168.100.22:8090` before configuring the proxy.

## Nginx Proxy Manager

Create a proxy host with these settings:

| Setting | Value |
| --- | --- |
| Domain name | `home.litvinovich.dev` |
| Scheme | `http` |
| Forward hostname/IP | `192.168.100.22` |
| Forward port | `8090` |
| SSL | Request a Let's Encrypt certificate and force SSL |

The dashboard's service links use the existing `*.home.litvinovich.dev` home-zone names. Clients need access to that DNS zone and the linked services.

## Update and stop

```bash
docker compose pull
docker compose up -d
docker compose logs --tail=100 glance
```

To change the pinned version, edit the image tag in `docker-compose.yml` before pulling. To stop Glance, run `docker compose down`.
