
COMPOSE = docker compose -f srcs/docker-compose.yml

# LOGIN is read straight from .env instead of hardcoded, so this Makefile
# works unmodified on any fresh VM/machine as long as .env is filled in.
LOGIN     := $(shell grep -m1 '^LOGIN=' srcs/.env | cut -d '=' -f2)
DATA_DIR  := /home/$(LOGIN)/data

# ANSI color codes for readable make output. \033 is the ESC character;
# [0m resets to default so color doesn't bleed into the next line.
GREEN  := \033[0;32m
YELLOW := \033[0;33m
CYAN   := \033[0;36m
RED    := \033[0;31m
RESET  := \033[0m

# data-dirs: create the host folders the bind-mounted volumes point at
# (wp_data -> $(DATA_DIR)/wordpress, db_data -> $(DATA_DIR)/mariadb).
# On a brand new VM these don't exist yet — Docker would auto-create them
# as root on first "up", which can cause permission headaches later, so
# we create them explicitly and up depends on this target running first.
data-dirs:
	@printf "$(CYAN)Ensuring data dirs exist in $(DATA_DIR)...$(RESET)\n"
	mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb

# --build: rebuild the images every time we change Dockerfile insted of building the container fron an existing image
up: data-dirs
	@printf "$(CYAN)Building and starting the stack...$(RESET)\n"
	$(COMPOSE) up --build -d
	@printf "$(GREEN)Stack is up.$(RESET)\n"

down:
	@printf "$(YELLOW)Stopping and removing containers...$(RESET)\n"
	$(COMPOSE) down
	@printf "$(GREEN)Done.$(RESET)\n"

# stop: pause running containers without deleting them (keeps volumes AND
# containers themselves — faster to resume than "up" since nothing rebuilds).
stop:
	@printf "$(YELLOW)Pausing containers...$(RESET)\n"
	$(COMPOSE) stop
	@printf "$(GREEN)Stopped.$(RESET)\n"

# start: resume containers that were paused with "stop". No rebuild, no
# re-running entrypoint init logic — just picks up where they left off.
start:
	@printf "$(CYAN)Resuming containers...$(RESET)\n"
	$(COMPOSE) start
	@printf "$(GREEN)Started.$(RESET)\n"

# restart: stop + start in one step, per service if given (e.g. make restart s=nginx)
# or all services if s is left empty.
restart:
	@printf "$(CYAN)Restarting $(if $(s),$(s),all services)...$(RESET)\n"
	$(COMPOSE) restart $(s)
	@printf "$(GREEN)Done.$(RESET)\n"

# ps: quick status check — which containers are up, their ports, health.
ps:
	@printf "$(CYAN)=== containers ===$(RESET)\n"
	@$(COMPOSE) ps

# logs: -f follows the log output live (like `tail -f`), --tail=100 limits
# how much history is printed on entry. Pass a service with s=<name>, e.g.
# `make logs s=wordpress`; leave s empty to show logs from every service.
logs:
	@printf "$(CYAN)Tailing logs for $(if $(s),$(s),all services)...$(RESET)\n"
	$(COMPOSE) logs -f --tail=100 $(s)

# build: rebuild images without starting containers — useful when editing
# a Dockerfile and you just want to confirm it builds before running it.
build:
	@printf "$(CYAN)Building images...$(RESET)\n"
	$(COMPOSE) build
	@printf "$(GREEN)Build done.$(RESET)\n"

# shell: open an interactive shell inside a running container.
# usage: make shell s=wordpress
shell:
	@printf "$(CYAN)Opening shell in $(s)...$(RESET)\n"
	$(COMPOSE) exec $(s) sh

# status: one-shot health check of the whole stack — containers, the
# custom network, and the volumes, each in their own labeled section.
status:
	@printf "$(CYAN)=== containers ===$(RESET)\n"
	@$(COMPOSE) ps
	@echo ""
	@printf "$(CYAN)=== network ===$(RESET)\n"
	@docker network inspect inception --format '{{range .Containers}}{{.Name}} -> {{.IPv4Address}}{{"\n"}}{{end}}'
	@echo ""
	@printf "$(CYAN)=== volumes ===$(RESET)\n"
	@docker volume ls --filter name=wp_data --filter name=db_data --filter name=portainer_data

# docker system prune -f: removes stopped containers, unused networks, dangling (untagged) images, and build cache across all of Docker, not just this project. -f = force.
clean: down
	@printf "$(YELLOW)Pruning unused Docker resources...$(RESET)\n"
	docker system prune -f
	@printf "$(GREEN)clean done.$(RESET)\n"

# fclean: full wipe. Removes Docker's own record of the volumes (docker
# volume rm), AND the real files at the bind-mounted host path — since
# those never get deleted by "docker volume rm" or "down -v" alone
# (bug learned the hard way, see NOTES.md). sudo is required because the
# data was written by root/www-data/mysql inside the containers.
fclean: down
	@printf "$(RED)Wiping volumes and host data — this cannot be undone...$(RESET)\n"
	docker volume rm db_data wp_data
	sudo rm -rf $(DATA_DIR)/*
	docker system prune -af --volumes
	@printf "$(GREEN)fclean done.$(RESET)\n"

re: fclean up

.PHONY: up down stop start restart ps logs build shell status clean fclean re data-dirs