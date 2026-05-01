# mnx-traefik

Reverse proxy and TLS termination for the monastryx platform on Hetzner.

This stack runs a single instance of [Traefik v3](https://doc.traefik.io/traefik/) on the VPS as the public entry point. It owns ports 80 and 443, terminates TLS, fetches and renews Let's Encrypt certificates automatically, and routes traffic to the right container by hostname based on labels declared in each service's own `docker-compose.yml`.

## How services attach themselves

Other monastryx services (e.g. `mnx-infra`'s Hasura) attach to the **external Docker network `proxy`** and announce their routing rules via container labels. Traefik watches the Docker socket and picks them up live — no traefik restart needed when a new service comes up.

## First-time setup on the VPS

```bash
# Create the shared external network (once per host)
docker network create proxy

# Clone this repo
cd ~ && git clone https://github.com/datenmoench/mnx-traefik.git
cd mnx-traefik

# Create the cert storage file with strict permissions
# (Let's Encrypt refuses to write to it otherwise)
touch traefik/acme.json
chmod 600 traefik/acme.json

# Bring up traefik + the fallback holding page
docker compose up -d
```

## Configuration

- **`traefik/config.yml`** — static config: entrypoints, Let's Encrypt resolver, IP whitelist middleware, logging.
- **`docker-compose.yml`** — runtime config: ports, volumes, the catch-all fallback router pointing at the holding-page container.
- **`landing/`** — static HTML served by the fallback when someone hits an unmapped hostname.
- **`logs/`** — traefik access + error logs (gitignored).

## IP whitelist

The `ipallowlist` middleware in `config.yml` is *defined* but only applies to routers that explicitly reference it. Public services (e.g. the GraphQL endpoint) are reachable from anywhere; locked-down endpoints (e.g. the Hasura console) attach `ipallowlist@file` to their router via labels.

Update the `sourceRange:` list with the IPs you want to allow before exposing whitelisted services.
