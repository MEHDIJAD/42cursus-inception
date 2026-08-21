
COMPOSE = docker compose -f srcs/docker-compose.yml

# --build: rebuild the images every time we change Dockerfile insted of building the container fron an existing image
up:
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down

# docker system prune -f: removes stopped containers, unused networks, dangling (untagged) images, and build cache across all of Docker, not just this project. -f = force.
clean: down
	docker system prune -f


fclean: down
	docker volume rm db_data wp_data
	docker system prune -af --volumes

re: fclean up

.PHONY: up down clean fclean re