# mnx-traefik

Reverse proxy and TLS termination for the monastryx platform on Hetzner.

This stack runs a single instance of [Traefik v3](https://doc.traefik.io/traefik/) on the VPS as the public entry point. It owns ports 80 and 443, terminates TLS, fetches and renews Let's Encrypt certificates automatically, and routes traffic to the right container by hostname based on labels declared in each service's own `docker-compose.yml`.

## How services attach themselves

Other monastryx services (e.g. `mnx-infra`'s Hasura) attach to the **external Docker network `proxy`** and announce their routing rules via container labels. Traefik watches the Docker socket and picks them up live — no traefik restart needed when a new service comes up.

## Images

The configuration is baked into two images built by CI on every push to
`main` (`.github/workflows/images.yml`) and published to ghcr.io:
`mnx-traefik` (traefik v3 + `traefik/config.yml` + `traefik/dynamic/`) and
`mnx-holding-page` (nginx + `landing/`). A cell pulls them by tag
(`MNX_IMAGE_TAG`, default `main`); it never needs this repository. The only
state is the Let's Encrypt account and certificates, in the named volume
`mnx-traefik_acme` (`/acme/acme.json` inside the container; traefik creates
the file itself). Both logs go to stdout: `docker logs mnx-traefik`.

Changing the allowlist or any traefik setting is therefore a commit, a push,
and a deploy — the running container never has its config edited in place.

## First-time setup on the VPS

```bash
# Create the shared external network (once per host)
docker network create proxy

# Bring up traefik + the fallback holding page (pulls the images)
docker compose pull && docker compose up -d
```

Moving an existing machine whose certificates live in the old bind-mounted
`traefik/acme.json` (one-time, before the first `up` of the image-based
stack, so the certificates are not re-requested):

```bash
docker volume create mnx-traefik_acme
docker run --rm -v mnx-traefik_acme:/acme -v ~/mnx-traefik/traefik/acme.json:/src:ro alpine \
  sh -c 'cp /src /acme/acme.json && chmod 600 /acme/acme.json'
```

## Configuration

- **`traefik/config.yml`** — static config: entrypoints, Let's Encrypt resolver, logging.
- **`traefik/dynamic/`** — dynamic config read by the file provider: routers, services and middlewares not tied to a container (none today).
- **`docker-compose.yml`** — runtime config: ports, the `acme` volume, the catch-all fallback router pointing at the holding-page container.
- **`landing/`** — static HTML served by the fallback when someone hits an unmapped hostname.
