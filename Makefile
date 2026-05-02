# mnx-traefik deploy targets
#
# All targets operate against the VPS over SSH using ~/.ssh/id_hetzner.

VPS  := monastryx@178.104.52.253
SSH  := ssh -o IdentitiesOnly=yes -o IdentityFile=~/.ssh/id_hetzner
DIR  := ~/mnx-traefik

.PHONY: deploy logs restart status help

help:
	@echo "Targets:"
	@echo "  deploy   git pull + docker compose up -d  (image upgrades / compose changes)"
	@echo "  logs     tail traefik logs (file-mounted; INFO level by default)"
	@echo "  restart  restart traefik (re-reads config.yml; faster than full deploy)"
	@echo "  status   show docker compose ps"

deploy:
	@echo "==> deploying mnx-traefik on VPS..."
	$(SSH) $(VPS) 'cd $(DIR) && git pull && docker compose up -d'

logs:
	$(SSH) $(VPS) 'tail -f -n 200 ~/mnx-traefik/logs/traefik.log'

restart:
	$(SSH) $(VPS) 'cd $(DIR) && docker compose restart traefik'

status:
	$(SSH) $(VPS) 'cd $(DIR) && docker compose ps'
