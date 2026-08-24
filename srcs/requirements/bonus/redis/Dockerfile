# requirements/bonus/redis/Dockerfile
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends redis-server \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 6379

# --daemonize no: same PID-1 requirement as every other service —
# redis-server backgrounds itself by default otherwise
CMD ["redis-server", "--daemonize", "no", "--bind", "0.0.0.0"]
