COMPOSE = docker compose -f srcs/docker-compose.yml

DATA_DIR  := /home/eel-garo/data

GREEN  := \033[0;32m
YELLOW := \033[0;33m
CYAN   := \033[0;36m
RED    := \033[0;31m
RESET  := \033[0m

data-dirs:
	@printf "$(CYAN)Ensuring data dirs exist in $(DATA_DIR)...$(RESET)\n"
	mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb

up: data-dirs
	@printf "$(CYAN)Building and starting the stack...$(RESET)\n"
	$(COMPOSE) up --build -d
	@printf "$(GREEN)Stack is up.$(RESET)\n"

down:
	@printf "$(YELLOW)Stopping and removing containers...$(RESET)\n"
	$(COMPOSE) down
	@printf "$(GREEN)Done.$(RESET)\n"


stop:
	@printf "$(YELLOW)Pausing containers...$(RESET)\n"
	$(COMPOSE) stop
	@printf "$(GREEN)Stopped.$(RESET)\n"

start:
	@printf "$(CYAN)Resuming containers...$(RESET)\n"
	$(COMPOSE) start
	@printf "$(GREEN)Started.$(RESET)\n"


restart:
	@printf "$(CYAN)Restarting $(if $(s),$(s),all services)...$(RESET)\n"
	$(COMPOSE) restart $(s)
	@printf "$(GREEN)Done.$(RESET)\n"

ps:
	@printf "$(CYAN)=== containers ===$(RESET)\n"
	@$(COMPOSE) ps


logs:
	@printf "$(CYAN)Tailing logs for $(if $(s),$(s),all services)...$(RESET)\n"
	$(COMPOSE) logs -f --tail=10 $(s)

build:
	@printf "$(CYAN)Building images...$(RESET)\n"
	$(COMPOSE) build
	@printf "$(GREEN)Build done.$(RESET)\n"


shell:
	@printf "$(CYAN)Opening shell in $(s)...$(RESET)\n"
	$(COMPOSE) exec $(s) sh


status:
	@printf "$(CYAN)=== containers ===$(RESET)\n"
	@$(COMPOSE) ps
	@echo ""
	@printf "$(CYAN)=== network ===$(RESET)\n"
	@docker network ls
	@echo ""
	@printf "$(CYAN)=== volumes ===$(RESET)\n"
	@docker volume ls --filter name=wp_data --filter name=db_data --filter name=portainer_data

# docker system prune -f: removes stopped containers, unused networks, dangling (untagged) images, 
# and build cache across all of Docker, not just this project. -f = force.
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