# requirements/bonus/portainer/Dockerfile
# Portainer ships an official ready-built image (portainer/portainer-ce) —
# using it directly would break this project's "no ready-made service
# images" rule, the same rule that applies to every mandatory service.
# Downloading the binary release and running it yourself keeps this
# consistent with everything else in the project.
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/portainer/portainer/releases/download/2.21.4/portainer-2.21.4-linux-amd64.tar.gz \
    | tar -xz -C /opt

EXPOSE 9443

# --data: where Portainer keeps its own config/users — gets its own volume,
# same reasoning as WordPress/MariaDB's data directories
ENTRYPOINT ["/opt/portainer/portainer", "--data", "/data"]