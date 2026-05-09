# Installing Piped on YunoHost

This repository is packaged as a YunoHost app. It installs the full
self-hosted Piped stack (frontend + backend + proxy + PostgreSQL).

## One-line install

From the YunoHost admin command line on your server:

```sh
sudo yunohost app install https://github.com/DIZZYHOBO/Piped \
    --args "domain=piped.example.com&admin_email=you@example.com&disable_registration=false"
```

Replace `piped.example.com` with the domain (or subdomain) you want Piped
to live at. The domain must already be configured in YunoHost
(`yunohost domain list`) and have a working Let's Encrypt certificate (or
allow YunoHost to obtain one during install).

## Or install from the YunoHost web admin

1. Go to **Apps → Install** in the YunoHost web admin.
2. At the bottom, choose **Install custom app**.
3. Paste the repo URL: `https://github.com/DIZZYHOBO/Piped`.
4. Confirm the prompt about installing a non-official app.
5. Fill in the form (domain, admin email, registration toggle).
6. Wait. The install takes 10–20 minutes — it builds the Java backend with
   Gradle and the Rust proxy with Cargo from source.

## Requirements

See [`doc/PRE_INSTALL.md`](doc/PRE_INSTALL.md) for the full hardware/network
checklist. TL;DR: you need 2 GB RAM free during install, 1 GB at runtime,
and 3 GB disk.

## What the package does

| Step | Where |
| --- | --- |
| Reserves two TCP ports (backend + proxy) | manifest `[resources.ports]` |
| Provisions a PostgreSQL database | manifest `[resources.database]` |
| Installs JDK 21 (Adoptium), Node 22 (NodeSource), Rust 1.83 (rustup) | `scripts/_common.sh` |
| Builds the Vite frontend with your domain baked in | `piped_build_frontend` |
| Builds piped-backend (`./gradlew shadowJar`) | `piped_build_backend` |
| Builds piped-proxy (`cargo build --release`) | `piped_build_proxy` |
| Generates `config.properties` with random JWT secret + db creds | `conf/config.properties` template |
| Drops two systemd units and registers them with `yunohost service` | `conf/piped-backend.service`, `conf/piped-proxy.service` |
| Routes `/`, `/api/`, `/proxy/` through nginx | `conf/nginx.conf` |

## After install

- Frontend: `https://your-domain/`
- Backend health: `https://your-domain/api/healthcheck`
- Logs: `journalctl -u piped-backend` and `journalctl -u piped-proxy`,
  plus `/var/log/piped/`
- Configuration: `/var/www/piped/backend/config.properties` (regenerated
  on every upgrade — edit `conf/config.properties` in this repo to make
  changes durable across upgrades)

## Upgrades

`yunohost app upgrade piped` will pull this repo, rebuild all three
components from the latest upstream refs (pinned in `scripts/_common.sh`),
and restart the services. Database migrations are handled by Hibernate at
backend startup.

## Removing

`yunohost app remove piped` stops both services, drops the database, and
deletes the install/data directories.

## Troubleshooting

**The install fails halfway through with "java: command not found"**
Adoptium repo couldn't be set up — usually a network/CA issue.
`apt-get update` and check `/etc/apt/sources.list.d/adoptium.list`.

**Gradle gets killed during build**
Out of memory. Free at least 2 GB before installing or add swap:
`fallocate -l 2G /swapfile && mkswap /swapfile && swapon /swapfile`.

**Frontend loads but every API call 502s**
Backend hasn't finished its cold start. Wait 30–60 s, then check
`systemctl status piped-backend`. If it's failed, look at
`/var/log/piped/backend.log`.

**Videos play but stutter / proxy timeouts**
The `piped-proxy` cache directory may be filling its disk. Adjust
`MAX_FILE_SIZE` in `conf/piped-proxy.service` and reduce on-disk cache,
or move `__DATA_DIR__/proxy-cache` to a larger volume.
