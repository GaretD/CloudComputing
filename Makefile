# ---------- Config ----------
PROJECT_NAME := cloudcomputing
COMPOSE := docker compose
# On older Docker you may need: COMPOSE := docker-compose

# ---------- Targets ----------
.PHONY: help
help:
	@echo "Make targets:"
	@echo "  make pull        - Pull latest images"
	@echo "  make up          - Start all services (detached)"
	@echo "  make down        - Stop all services"
	@echo "  make restart     - Restart services"
	@echo "  make logs        - Tail logs for all services"
	@echo "  make ps          - Show container status"
	@echo "  make db-shell    - Shell into MariaDB (mysql CLI)"
	@echo "  make sh-nginx    - Shell into nginx container"
	@echo "  make clean       - Remove containers, networks (keeps volumes)"
	@echo "  make nuke        - Remove EVERYTHING including volumes"
	@echo "  make reload-nginx- Hot reload nginx config"
	@echo "  make open        - Open site in browser (http://localhost:8080)"

.PHONY: pull
pull:
	$(COMPOSE) pull

.PHONY: up
up:
	$(COMPOSE) up -d

.PHONY: down
down:
	$(COMPOSE) down

.PHONY: restart
restart: down up

.PHONY: logs
logs:
	$(COMPOSE) logs -f

.PHONY: ps
ps:
	$(COMPOSE) ps

.PHONY: db-shell
db-shell:
	@echo "Opening MySQL shell in MariaDB container..."
	@docker exec -it cc_mariadb mysql -u$${MARIADB_USER:-appuser} -p$${MARIADB_PASSWORD:-app123} $${MARIADB_DATABASE:-cloudcomputing}

.PHONY: sh-nginx
sh-nginx:
	docker exec -it cc_nginx bash

.PHONY: clean
clean:
	$(COMPOSE) down --remove-orphans

.PHONY: nuke
nuke:
	$(COMPOSE) down --volumes --remove-orphans

.PHONY: reload-nginx
reload-nginx:
	docker exec cc_nginx nginx -s reload || true

.PHONY: open
open:
	@python3 - << 'PY'
import webbrowser; webbrowser.open("http://localhost:8080")
PY
