## Before you install

This is a heavy install. Please make sure your server can handle it.

### Minimum hardware

| Resource | Required |
| --- | --- |
| RAM during install | **2 GB free** (Gradle + Cargo + Vite all build from source) |
| RAM at runtime | **1 GB free** (Java backend, PostgreSQL, proxy) |
| Disk | **3 GB free** (~1 GB build artifacts, ~1 GB caches, headroom for media proxy cache) |
| CPU | 2 cores recommended (single-core works but takes ~25 min) |

If you are on a small VPS, **stop other big services before installing**;
Gradle and Cargo will OOM-kill themselves under memory pressure and the
install will fail.

### Architecture

`amd64` and `arm64` are supported. `armhf` (32-bit Pi) is **not** supported —
piped-backend requires JDK 21, which Adoptium does not publish for armhf.

### Network

The install fetches:

- piped-backend source from GitHub
- piped-proxy source from GitHub
- Eclipse Temurin JDK 21 from the Adoptium APT repo
- Node.js 22 from NodeSource
- Rust 1.83 from rustup.rs
- Frontend npm dependencies from the npm registry
- Java dependencies via Gradle

Allow ~10–20 minutes for the first install on average hardware.

### Domain

Piped expects to live at the **root of a dedicated domain or subdomain**
(e.g. `piped.example.com`). Path-based installs (`example.com/piped`) are
not supported because the frontend uses absolute paths for routing.
