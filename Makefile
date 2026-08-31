COMPOSE = docker compose -f srcs/docker-compose.yml

DATA_DIR  := /home/eel-garo/data

data-dirs:
	@echo "Ensuring data dirs exist in $(DATA_DIR)..."
	mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb

up: data-dirs
	@echo "Building and starting the stack..."
	$(COMPOSE) up --build -d
	@echo "Stack is up."

down:
	@echo "Stopping and removing containers..."
	$(COMPOSE) down
	@echo "Done."

stop:
	@echo "Pausing containers..."
	$(COMPOSE) stop
	@echo "Stopped."

start:
	@echo "Resuming containers..."
	$(COMPOSE) start
	@echo "Started."

restart:
	@echo "Restarting $(if $(s),$(s),all services)..."
	$(COMPOSE) restart $(s)
	@echo "Done."

ps:
	@echo "=== containers ==="
	@$(COMPOSE) ps

logs:
	@echo "Tailing logs for $(if $(s),$(s),all services)..."
	$(COMPOSE) logs -f --tail=10 $(s)

build:
	@echo "Building images..."
	$(COMPOSE) build
	@echo "Build done."

shell:
	@echo "Opening shell in $(s)..."
	$(COMPOSE) exec $(s) sh

status:
	@echo "=== containers ==="
	@$(COMPOSE) ps
	@echo ""
	@echo "=== network ==="
	@docker network ls
	@echo ""
	@echo "=== volumes ==="
	@docker volume ls --filter name=wp_data --filter name=db_data --filter name=portainer_data

# docker system prune -f: removes stopped containers, unused networks, dangling (untagged) images,
# and build cache across all of Docker, not just this project. -f = force.
clean: down
	@echo "Pruning unused Docker resources..."
	docker system prune -f
	@echo "clean done."

# fclean: full wipe = volume rm + bind-mount-host-path
# -a means "everything," not just the stuff nobody's using anymore.
fclean: down
	@echo "Wiping volumes and host data — this cannot be undone..."
	docker volume rm db_data wp_data portainer_data
	sudo rm -rf $(DATA_DIR)/*
	docker system prune -af --volumes
	@echo "fclean done."

re: fclean up

.PHONY: up down stop start restart ps logs build shell status clean fclean re data-dirs