# User Documentation

This guide is for anyone who needs to run, use, or check on the Inception
stack without digging into the Docker configuration itself.

## What this stack provides

Three services work together to run a single WordPress website:

| Service      | What it does                                              |
|--------------|-------------------------------------------------------------|
| **NGINX**    | The website's entrance. Handles HTTPS and is the only piece reachable from outside. |
| **WordPress**| The actual website — pages, posts, the admin panel.        |
| **MariaDB**  | The database. Stores everything WordPress needs (users, posts, settings). |

You interact with WordPress through your browser; the other two services
run in the background and don't need direct attention day to day.

## Starting and stopping the project

All commands below are run from the `system/` folder, using `make`.

| Command      | What it does                                                |
|--------------|----------------------------------------------------------------|
| `make up`    | Builds the images (if needed) and starts all three services.  |
| `make down`  | Stops and removes the running containers. Your data is kept.  |
| `make stop`  | Pauses the containers without removing them — faster to resume than `down` + `up` since nothing rebuilds. |
| `make start` | Resumes containers previously paused with `make stop`.        |
| `make restart s=nginx` | Restarts one service by name (`nginx`, `wordpress`, or `mariadb`). Leave `s` off to restart everything. |
| `make ps`    | Shows which containers are currently running.                 |
| `make clean` | `down`, plus removes unused Docker leftovers (safe, non-destructive to your site data). |
| `make fclean`| Stops everything **and deletes the site's data** (database + WordPress files). Use only if you want a full reset. |
| `make re`    | `fclean` followed by `up` — a complete fresh rebuild.          |

To check the site is back up after `make up`, give it a few seconds — the
containers wait for the database to be ready before finishing setup.

## Accessing the website and admin panel

- **Website:** open `https://<domain>` in a browser, where `<domain>` is
  the value configured for `DOMAIN_NAME` in `system/srcs/.env`
  (e.g. `eel-garo.42.fr`). The certificate is self-signed, so the browser
  will show a security warning the first time — this is expected, accept
  it to continue.
- **Admin panel:** go to `https://<domain>/wp-admin` and sign in with the
  admin account. The admin **username** is set by `WP_ADMIN_USER` in
  `.env`; the **password** is stored as a secret (see below).
- There's also a second, regular (non-admin) account, useful for testing
  things like posting comments as a normal visitor. Its username is set by
  `WP_USER` in `.env`.

## Finding and managing credentials

Passwords are never written directly into the configuration files — they
live in separate secret files so they can be kept out of version control
and off of the more visible parts of the setup:

- `system/secrets/db_root_password.txt` — MariaDB's root password.
- `system/secrets/db_password.txt` — the password for the WordPress
  database user.
- `system/secrets/credentials.txt` — the WordPress admin and regular user
  passwords.

Non-secret settings (domain name, usernames, database name) are in
`system/srcs/.env` instead — those are configuration, not secrets, so
they're fine to keep alongside the code.

If you ever need to change a password, edit the relevant secret file
**and** run `make re` (or `make fclean && make up`) so the containers pick
up the new value on a fresh database initialization — simply editing the
file and restarting is not enough, since the database only reads these
values the first time it initializes.

## Checking that everything is running correctly

- **Container status:** from `system/`, run `make ps`. All three services
  (`nginx`, `wordpress`, `mariadb`) should show as `running`/`Up`.
- **The site itself:** visiting `https://<domain>` should show the actual
  WordPress homepage, not a connection error or a blank page.
- **Logs, if something looks wrong:** run `make logs s=<service>`,
  replacing `<service>` with `nginx`, `wordpress`, or `mariadb` (leave
  `s` off to see logs from every service at once). This shows what that
  container printed on startup, including any errors.
- **Plain HTTP should not work:** the project intentionally does not serve
  anything over port 80 — only HTTPS (443). Seeing a connection failure on
  `http://<domain>` is expected, not a bug.