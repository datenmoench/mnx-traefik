# mnx-traefik deploy targets
#
# All targets operate against the VPS over SSH using ~/.ssh/id_hetzner.

VPS  := monastryx@178.104.52.253
SSH  := ssh -o IdentitiesOnly=yes -o IdentityFile=~/.ssh/id_hetzner
DIR  := ~/mnx-traefik

.PHONY: deploy logs restart status help

help:
	@echo "Targets:"
	@echo "  deploy   pull the edge images CI built for TAG (default: HEAD) and restart"
	@echo "  logs     tail traefik logs (stdout; INFO level by default)"
	@echo "  restart  restart traefik"
	@echo "  status   show docker compose ps"

# A deploy names a commit (TAG, default: the local HEAD, pushed) and pulls
# the images CI built for it; nothing is built on the machine. The compose file
# itself is pulled from the registry (ORAS artifact) — the machine has no checkout.
TAG ?= $(shell git rev-parse HEAD)

deploy:
	@git fetch -q origin main && test "$$(git rev-parse $(TAG))" = "$$(git merge-base $(TAG) origin/main)" \
	  || { echo "commit $(TAG) is not on origin/main — push first"; exit 1; }
	@echo "==> deploying mnx-traefik $(TAG) on VPS..."
	$(SSH) $(VPS) 'set -e; cd $(DIR) && ~/.local/bin/oras pull -o . ghcr.io/datenmoench/mnx-traefik-compose:$(TAG) >/dev/null; touch .env; \
	  grep -q "^MNX_IMAGE_TAG=" .env && sed -i "s/^MNX_IMAGE_TAG=.*/MNX_IMAGE_TAG=$(TAG)/" .env || echo "MNX_IMAGE_TAG=$(TAG)" >> .env; \
	  for i in $$(seq 1 40); do docker manifest inspect ghcr.io/datenmoench/mnx-traefik:$(TAG) >/dev/null 2>&1 && break; \
	    [ $$i -eq 40 ] && { echo "image for $(TAG) never appeared on ghcr.io — is the images workflow green?"; exit 1; }; \
	    echo "waiting for ghcr.io/datenmoench/mnx-traefik:$(TAG) (CI still building?)"; sleep 15; done; \
	  docker compose pull -q && docker compose up -d'

logs:
	$(SSH) $(VPS) 'docker logs -f --tail 200 mnx-traefik'

restart:
	$(SSH) $(VPS) 'cd $(DIR) && docker compose restart traefik'

status:
	$(SSH) $(VPS) 'cd $(DIR) && docker compose ps'
