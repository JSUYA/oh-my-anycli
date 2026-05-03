# Docker + Playwright sandbox reference

## Prerequisites

- Docker is required for all browser testing covered by this skill.
- On Ubuntu, install Docker with:

```bash
sudo apt-get update && sudo apt-get install -y docker.io
```

- Verify Docker with:

```bash
docker --version
```

- Start Docker after installation if needed:

```bash
sudo systemctl enable --now docker
```

- Verify container execution with:

```bash
docker run --rm hello-world
```

- If the current user cannot access Docker, either use `sudo docker ...` or add the user to the `docker` group and start a new login session:

```bash
sudo usermod -aG docker "$USER"
```

## Decision rules

1. If the repository has `docker-compose.yml`, `compose.yml`, or documented E2E commands, inspect and prefer them when browser execution remains containerized.
2. If the repository has Playwright config but no Docker wrapper, run the existing Playwright command inside `mcr.microsoft.com/playwright`.
3. If the repository has no Playwright dependency but browser testing is required, use a temporary container and avoid modifying project dependencies unless the user asks for a permanent setup.
4. If persistent setup is requested, add a Docker-based script or compose service rather than host browser installation instructions.
5. Match the Docker image tag to the project Playwright version when possible, following the official Playwright Docker image pattern.
6. Follow the official Playwright Docker guidance at `https://playwright.dev/docs/docker`: pin a versioned image, use `--init`, use `--ipc=host` for Chromium stability, and avoid host browser installation.

## One-shot Playwright test

```bash
docker run --rm \
  --init \
  --ipc=host \
  -u "$(id -u):$(id -g)" \
  -v "$PWD:/work" \
  -w /work \
  mcr.microsoft.com/playwright:v1.59.1-noble \
  npx playwright test
```

## One-shot headed-equivalent artifacts

Use traces, videos, and screenshots instead of opening a host browser:

```bash
docker run --rm \
  --init \
  --ipc=host \
  -u "$(id -u):$(id -g)" \
  -v "$PWD:/work" \
  -w /work \
  mcr.microsoft.com/playwright:v1.59.1-noble \
  npx playwright test --trace on --video on
```

## Docker Compose service template

```yaml
services:
  playwright:
    image: mcr.microsoft.com/playwright:v1.59.1-noble
    working_dir: /work
    init: true
    ipc: host
    user: "${UID:-1000}:${GID:-1000}"
    volumes:
      - .:/work
    command: npx playwright test
```

Run with:

```bash
UID=$(id -u) GID=$(id -g) docker compose run --rm playwright
```

## Local server pattern

```yaml
services:
  app:
    image: node:22-bookworm-slim
    working_dir: /work
    volumes:
      - .:/work
    command: sh -lc "npm ci && npm run dev -- --host 0.0.0.0"
    expose:
      - "3000"

  playwright:
    image: mcr.microsoft.com/playwright:v1.59.1-noble
    working_dir: /work
    init: true
    ipc: host
    user: "${UID:-1000}:${GID:-1000}"
    volumes:
      - .:/work
    environment:
      BASE_URL: http://app:3000
    depends_on:
      - app
    command: npx playwright test
```

## Prohibited patterns

- Host `npx playwright install`.
- Floating Playwright Docker image tags such as `latest`.
- Host browser automation against Chrome, Chromium, Edge, Safari, or Firefox.
- Mounting `$HOME`, SSH keys, cloud credentials, browser profiles, or token stores into the browser container by default.
- Running privileged browser containers unless explicitly required and approved.
