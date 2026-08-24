COMPOSE = docker compose -f srcs/docker-compose.yml

# LOGIN is read straight from .env instead of hardcoded, so this Makefile
# works unmodified on any fresh VM/machine as long as .env is filled in.
LOGIN     := $(shell grep -m1 '^LOGIN=' srcs/.env | cut -d '=' -f2)
DATA_DIR  := /home/$(LOGIN)/data

# data-dirs: create the host folders the bind-mounted volumes point at
# (wp_data -> $(DATA_DIR)/wordpress, db_data -> $(DATA_DIR)/mariadb).
# On a brand new VM these don't exist yet — Docker would auto-create them
# as root on first "up", which can cause permission headaches later, so
# we create them explicitly and up depends on this target running first.
data-dirs:
	mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb

# --build: rebuild the images every time we change Dockerfile insted of building the container fron an existing image
up: data-dirs
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down

# stop: pause running containers without deleting them (keeps volumes AND
# containers themselves — faster to resume than "up" since nothing rebuilds).
stop:
	$(COMPOSE) stop

# start: resume containers that were paused with "stop". No rebuild, no
# re-running entrypoint init logic — just picks up where they left off.
start:
	$(COMPOSE) start

# restart: stop + start in one step, per service if given (e.g. make restart s=nginx)
# or all services if s is left empty.
restart:
	$(COMPOSE) restart $(s)

# ps: quick status check — which containers are up, their ports, health.
ps:
	$(COMPOSE) ps

# logs: -f follows the log output live (like `tail -f`), --tail=100 limits
# how much history is printed on entry. Pass a service with s=<name>, e.g.
# `make logs s=wordpress`; leave s empty to show logs from every service.
logs:
	$(COMPOSE) logs -f --tail=100 $(s)

# build: rebuild images without starting containers — useful when editing
# a Dockerfile and you just want to confirm it builds before running it.
build:
	$(COMPOSE) build

# shell: open an interactive shell inside a running container.
# usage: make shell s=wordpress
shell:
	$(COMPOSE) exec $(s) sh

# docker system prune -f: removes stopped containers, unused networks, dangling (untagged) images, and build cache across all of Docker, not just this project. -f = force.
clean: down
	docker system prune -f

# fclean: full wipe. Removes Docker's own record of the volumes (docker
# volume rm), AND the real files at the bind-mounted host path — since
# those never get deleted by "docker volume rm" or "down -v" alone
# (bug learned the hard way, see NOTES.md). sudo is required because the
# data was written by root/www-data/mysql inside the containers.
fclean: down
	docker volume rm db_data wp_data
	sudo rm -rf $(DATA_DIR)/*
	docker system prune -af --volumes

re: fclean up

.PHONY: up down stop start restart ps logs build shell clean fclean re data-dirs