---
name: sandboxed-browser-testing
description: Use this skill whenever browser, UI, E2E, Playwright, Puppeteer, screenshot, visual regression, or web automation testing is needed. It requires all browser tests to run only inside an isolated Docker sandbox, never on the host browser or host Playwright installation.
---

# Sandboxed Browser Testing

Use this workflow whenever a task requires web browser testing, UI automation, screenshots, E2E checks, visual regression, or Playwright/Puppeteer-style validation.

## Hard requirements

- Docker must be available before browser testing; verify with `docker --version`.
- If Docker is missing or not running, explain that browser tests require Docker and ask before installing packages or changing system services.
- Run browser tests only inside Docker containers.
- Prefer the official Playwright Docker image (`mcr.microsoft.com/playwright`) when Playwright is needed.
- Use the image tag that matches the project's `@playwright/test` version when possible; otherwise use the pinned default in this skill.
- Pin the image to a specific version; do not use floating tags such as `latest`.
- Include `--init` for one-shot containers unless there is a project-specific reason not to.
- Do not install browsers on the host.
- Do not run host commands such as `npx playwright install`, host `playwright test`, host `chromium`, host `google-chrome`, or host browser automation tools.
- Do not mount secrets into the browser container unless the user explicitly asks and the test requires them.
- Use disposable containers with `--rm`.
- Mount only the project directory needed for testing.
- Use non-root container execution when practical.
- Keep browser access scoped to local development URLs unless the user explicitly asks to test a remote programming-related URL.

## Default Docker Playwright command

If Docker is missing and package installation is approved, install Docker through the host OS package manager and verify it first. Do not install Playwright browsers on the host as a fallback.

From the target project root, use this pattern:

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

If the project uses npm scripts, prefer the existing script inside the same container:

```bash
docker run --rm \
  --init \
  --ipc=host \
  -u "$(id -u):$(id -g)" \
  -v "$PWD:/work" \
  -w /work \
  mcr.microsoft.com/playwright:v1.59.1-noble \
  npm run test:e2e
```

## Local app testing

If a local dev server is needed, run both the app and Playwright in Docker. Prefer an existing `docker compose` setup when present. If none exists, use an isolated Docker network:

```bash
docker network create playwright-sandbox
```

Start the app container on that network, then run Playwright against the app container name, not the host browser. Remove the network after testing:

```bash
docker network rm playwright-sandbox
```

If the app must run on the host, use `--add-host=host.docker.internal:host-gateway` and target `http://host.docker.internal:<port>`, but only when containerizing the app is impractical.

## Adopting existing online patterns

The preferred upstream pattern is the official Playwright Docker workflow documented at `https://playwright.dev/docs/docker`: use `mcr.microsoft.com/playwright:<version>-noble`, `--rm`, `--init`, and `--ipc=host`; run as `pwuser` plus a seccomp profile for untrusted crawling/scraping; match the image version to the project Playwright dependency whenever possible. If the repository already has a documented Docker-based Playwright, Puppeteer, browserless, Selenium, or Docker Compose setup, use that existing setup instead of inventing a new one, provided it keeps browser execution inside containers.

Read `references/docker-playwright.md` for templates and decision rules.

## Verification checklist

Before running browser tests, verify:

- [ ] The command invokes `docker run` or `docker compose`.
- [ ] Browser execution happens inside a container.
- [ ] The container is disposable or clearly isolated.
- [ ] The mounted paths are minimal.
- [ ] No host browser install or host Playwright browser cache is required.
- [ ] Remote URLs are used only when explicitly provided or clearly programming-related.
