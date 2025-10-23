# ---------- Config ----------
COMPOSE := docker compose
OWNER   ?= GaretD
REPO    ?= CloudComputing
BRANCH  ?= $(shell git rev-parse --abbrev-ref HEAD)
TAG     ?= $(BRANCH)

# ---------- Help ----------
.PHONY: help
help:
	@echo "Make targets:"
	@echo "  make build         - Build nginx image (tagged with current git branch)"
	@echo "  make up            - Start local stack (detached), builds if needed"
	@echo "  make down          - Stop local stack"
	@echo "  make logs          - Tail logs"
	@echo "  make ps            - Show container status"
	@echo "  make db-shell      - Open mysql CLI in MariaDB"
	@echo "  make nuke          - Down + remove volumes"
	@echo "  make pull-prod     - Pull published nginx image for TAG"
	@echo "  make up-prod       - Run published nginx image for TAG"
	@echo "  make down-prod     - Stop prod compose stack"

# ---------- Local (build from working tree) ----------
.PHONY: build
build:
	docker build \
	  --build-arg WEB_DIR=. \
	  -t cloudcomputing-nginx:$(TAG) \
	  -f Dockerfile.nginx .

.PHONY: up
up:
	$(COMPOSE) up -d --build

.PHONY: down
down:
	$(COMPOSE) down

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

.PHONY: nuke
nuke:
	$(COMPOSE) down --volumes --remove-orphans

# ---------- Prod (pull & run published image) ----------
.PHONY: pull-prod
pull-prod:
	OWNER=$(OWNER) REPO=$(REPO) TAG=$(TAG) docker compose -f docker-compose.prod.yml pull

.PHONY: up-prod
up-prod:
	OWNER=$(OWNER) REPO=$(REPO) TAG=$(TAG) docker compose -f docker-compose.prod.yml up -d

.PHONY: down-prod
down-prod:
	docker compose -f docker-compose.prod.yml down
