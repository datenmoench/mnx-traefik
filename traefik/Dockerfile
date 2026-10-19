# traefik with this stack's configuration baked in, so a box pulls the
# image and never needs the repository. The static config lands where
# traefik looks by default; the dynamic directory is the file provider's
# watched path (see config.yml). ACME state lives in the `acme` volume.
FROM traefik:v3
COPY config.yml /etc/traefik/traefik.yml
COPY dynamic /etc/traefik/dynamic
