# Developer Documentation

This guide covers setting up, building, and working on the Inception stack
from a developer's point of view.

## Setting up the environment from scratch

### Prerequisites
- Docker Engine and Docker Compose (v2 syntax, i.e. `docker compose`, not
  the standalone `docker-compose` binary)
- `make`
- A Linux virtual machine — the project is designed to run inside a VM
  (not directly on a host OS), since the eval process checks persistence
  by rebooting the VM itself

### Configuration files to fill in
Two kinds of configuration live outside the code, and both need real
values before the first `make up`:

1. **`system/srcs/.env`** — non-secret settings, plain key/value pairs:
   - `LOGIN` — your 42 login, used to build the host data path
     (`/home/<LOGIN>/data/...`).
   - `DOMAIN_NAME` — the domain the site will answer to, conventionally
     `<login>.42.fr`.
   - `MYSQL_DATABASE`, `MYSQL_USER` — database name and app-level DB user.
   - `WORDPRESS_DB_HOST` — should stay `mariadb` (the container's service
     name, resolved via Docker's internal DNS).
   - `WP_ADMIN_USER`, `WP_ADMIN_EMAIL` — WordPress admin account (the
     username must **not** contain "admin"/"administrator" in any form —
     the entrypoint script rejects it if it does).
   - `WP_USER`, `WP_USER_EMAIL` — a second, non-admin WordPress user.

2. **`system/secrets/`** — one password per file, read by the containers
   at `/run/secrets/<name>` (never as plain environment variables):
   - `db_root_password.txt` — MariaDB root password.
   - `db_password.txt` — password for the app-level DB user.
   - `credentials.txt` — `KEY=VALUE` lines providing
     `WP_ADMIN_PASSWORD` and `WP_USER_PASSWORD`, sourced directly by the
     WordPress entrypoint script.

   These files are excluded from git (see `.gitignore`) — on a fresh
   clone you have to create them yourself with real values; `git pull`
   will not bring them over.

3. **`/etc/hosts`** (inside the VM, and on the host machine if you're
   browsing from outside the VM) — add a line mapping `DOMAIN_NAME` to
   `127.0.0.1` (inside the VM) or the VM's forwarded address (from the
   host), since the domain isn't real DNS.

## Building and launching

Everything is driven from `system/Makefile`, which wraps
`docker compose -f srcs/docker-compose.yml`:

```bash
make data-dirs        # mkdir -p the host folders wp_data/db_data bind-mount to
make up               # docker compose up --build -d — builds every image, starts detached (runs data-dirs first)
make down             # docker compose down — stops and removes containers
make stop             # docker compose stop — pauses containers, keeps them (no rebuild on resume)
make start            # docker compose start — resumes containers paused by "stop"
make restart s=nginx  # docker compose restart <service> — restart one service, or all if s is empty
make ps               # docker compose ps — container status
make logs s=wordpress # docker compose logs -f --tail=100 <service> — follow logs, one service or all
make build            # docker compose build — rebuild images without starting anything
make shell s=mariadb  # docker compose exec <service> sh — interactive shell in a running container
make clean            # down, then docker system prune -f (safe cleanup)
make fclean           # down, remove the db_data/wp_data volumes, wipe the host data folders, then prune -af --volumes
make re               # fclean && up — full rebuild from a clean state
```

`data-dirs` creates `/home/<LOGIN>/data/wordpress` and
`/home/<LOGIN>/data/mariadb` (`LOGIN` is read from `.env`, not hardcoded)
— the folders the bind-mounted volumes point at. `up` depends on it, so it
always runs first automatically; you'd only call it directly to prep a
brand-new VM before the first `make up`.

`up` always rebuilds (`--build`), so changes to any `Dockerfile` or the
files it `COPY`s are picked up automatically on the next `make up` — no
separate `make build` is needed unless you want to check the image builds
without starting containers.

`restart`, `logs`, and `shell` take an optional `s=<service>` argument
(`s` is just a Makefile variable) where `<service>` is `nginx`,
`wordpress`, or `mariadb`. `restart` and `logs` default to acting on every
service if `s` is left off; `shell` requires a service, since you can only
open a shell in one container at a time.

## Managing volumes

```bash
docker volume ls                # list Docker volumes
docker volume inspect wp_data   # confirm the bind path
docker volume inspect db_data
```

## Where data lives and how it persists

The two named volumes, `wp_data` and `db_data`, are declared with a
`local` driver but configured with `driver_opts` to actually **bind-mount**
to a fixed path on the host VM:

- `wp_data` → `/home/${LOGIN}/data/wordpress` (WordPress core files, themes,
  uploads)
- `db_data` → `/home/${LOGIN}/data/mariadb` (MariaDB's data directory)

This is a deliberate combination — a named volume (so Docker manages it
and `docker volume inspect` shows it, satisfying the eval) that is also
pinned to a real, inspectable path on disk (via `driver_opts: type: none,
o: bind, device: ...`), rather than a plain Docker-managed volume hidden
under `/var/lib/docker/volumes/`.

**Practical consequences:**
- Data survives `make down` and container restarts, since it never lived
  inside the container's writable layer.
- Data survives even `docker compose down -v`, because that command only
  removes Docker's *record* of the volume name — it does not delete files
  at the bind-mounted host path.
- The only way to actually wipe the data is `make fclean`, which now
  removes both Docker's volume records **and** the real files at
  `/home/<LOGIN>/data/*` on the host (`sudo rm -rf`, since those files are
  owned by root/www-data/mysql from inside the containers) — this is why
  `fclean` is a separate, clearly-destructive target from `clean`, and why
  it asks for `sudo`.
- Both containers check for existing data on startup before running any
  first-time setup (WordPress checks for `wp-config.php`, MariaDB checks
  whether its data directory is empty) — so restarting the stack with
  existing volumes does not re-run installation, it just reconnects to
  what's already there.