# OpenClaw — build & deploy recipes
# Usage: just <recipe>    (install: brew install just)

set dotenv-load := true
set positional-arguments := true

# Default: list available recipes
default:
    @just --list

# ─── Build ────────────────────────────────────────────────────────────────────

# Full production build (TypeScript + UI)
build:
    pnpm build
    pnpm ui:build

# Fast incremental build (TypeScript only, no UI)
build-fast:
    pnpm exec tsdown --no-clean

# Build the Docker image
build-docker tag="openclaw:local" *args="":
    docker build -t {{ tag }} {{ args }} .

# Build Docker image with browser support (Chromium + Xvfb baked in)
build-docker-browser tag="openclaw:local":
    docker build -t {{ tag }} --build-arg OPENCLAW_INSTALL_BROWSER=1 .

# ─── Daemon lifecycle ────────────────────────────────────────────────────────

# Install the Gateway daemon (launchd/systemd)
daemon-install *args="":
    node scripts/run-node.mjs daemon install {{ args }}

# Start the Gateway daemon
daemon-start:
    node scripts/run-node.mjs daemon start

# Stop the Gateway daemon
daemon-stop:
    node scripts/run-node.mjs daemon stop

# Restart the Gateway daemon
daemon-restart:
    node scripts/run-node.mjs daemon restart

# Show daemon status and Gateway health
daemon-status:
    node scripts/run-node.mjs daemon status

# Uninstall the Gateway daemon
daemon-uninstall:
    node scripts/run-node.mjs daemon uninstall

# ─── Install & Deploy ─────────────────────────────────────────────────────────

# Symlink the `openclaw` binary globally so it's on your PATH
link:
    pnpm link --global

# Build, link globally, and restart the daemon
deploy: build link daemon-restart

# Fast deploy — incremental TS build + daemon restart (skip UI)
deploy-fast: build-fast daemon-restart

# Full redeploy — clean build, link globally, reinstall daemon, start
redeploy: build link daemon-uninstall
    just daemon-install
    just daemon-start

# Docker deploy — rebuild image + restart compose stack
deploy-docker tag="openclaw:local":
    just build-docker {{ tag }}
    docker compose up -d openclaw-gateway

# ─── Dev ──────────────────────────────────────────────────────────────────────

# Run gateway in dev mode (channels disabled, auto-rebuild on source changes)
dev:
    pnpm gateway:dev

# Run gateway in dev mode with session reset
dev-reset:
    pnpm gateway:dev:reset

# Run gateway with file watcher (auto-restart on changes)
watch:
    pnpm gateway:watch

# ─── Test & Check ────────────────────────────────────────────────────────────

# Run unit tests
test:
    pnpm test

# Run fast unit tests only
test-fast:
    pnpm test:fast

# Lint + type-check + format check
check:
    pnpm check

# ─── Logs & Debug ────────────────────────────────────────────────────────────

# Tail the Gateway daemon logs (macOS launchd)
[macos]
logs:
    tail -f ~/.openclaw/logs/gateway.log 2>/dev/null || echo "No log file found at ~/.openclaw/logs/gateway.log"

# Tail the Gateway daemon error logs (macOS launchd)
[macos]
logs-err:
    tail -f ~/.openclaw/logs/gateway.err.log 2>/dev/null || echo "No error log found at ~/.openclaw/logs/gateway.err.log"

# Run the doctor diagnostic tool
doctor:
    node scripts/run-node.mjs doctor
