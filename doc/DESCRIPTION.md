Piped is a privacy-friendly alternative YouTube frontend.

This package installs the **full self-hosted stack** on your YunoHost server:

- **Frontend** — Vue 3 single-page app (this repo), built with Vite at install
  time and served as static files by nginx.
- **Backend** — `piped-backend` (Java/Kotlin), built from source with Gradle
  and run as the `piped-backend` systemd service. Exposes the public Piped
  API used by the frontend.
- **Proxy** — `piped-proxy` (Rust), built from source with Cargo and run as
  the `piped-proxy` systemd service. Streams media so YouTube never sees
  your viewers' IP addresses.
- **PostgreSQL** — provisioned automatically by YunoHost. Stores user
  accounts, subscriptions, watch history.

Everything is reverse-proxied through a single domain:

| Path | Component |
| --- | --- |
| `/` | Frontend SPA |
| `/api/…` | Java backend |
| `/proxy/…` | Rust media proxy |

Because the frontend is built **per install**, the API and proxy URLs are
baked in at install time and you do not need to configure anything in the
preferences UI.
