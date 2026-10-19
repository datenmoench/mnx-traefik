# mnx-traefik deploy targets
#
# All targets operate against the VPS over SSH using ~/.ssh/id_hetzner.

VPS  := monastryx@178.104.52.253
SSH  := ssh -o IdentitiesOnly=yes -o IdentityFile=~/.ssh/id_hetzner
DIR  := ~/mnx-traefik

.PHONY: deploy logs restart status help

help:
	@echo "Targets:"
	@echo "  deploy   git pull + docker compose up -d --build  (config is baked into the images)"
	@echo "  logs     tail traefik logs (stdout; INFO level by default)"
	@echo "  restart  restart traefik"
	@echo "  status   show docker compose ps"

deploy:
	@echo "==> deploying mnx-traefik on VPS..."
	$(SSH) $(VPS) 'cd $(DIR) && git pull && docker compose up -d --build'

logs:
	$(SSH) $(VPS) 'docker logs -f --tail 200 mnx-traefik'

restart:
	$(SSH) $(VPS) 'cd $(DIR) && docker compose restart traefik'

status:
	$(SSH) $(VPS) 'cd $(DIR) && docker compose ps'
