FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/portainer/portainer/releases/download/2.21.4/portainer-2.21.4-linux-amd64.tar.gz \
    | tar -xz -C /opt

EXPOSE 9443

ENTRYPOINT ["/opt/portainer/portainer", "--data", "/data"]