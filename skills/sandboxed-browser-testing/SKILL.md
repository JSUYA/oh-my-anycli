---
name: sandboxed-browser-testing
description: Run browser-based tests (Playwright / Puppeteer / curl-against-localhost) ONLY inside a Docker container so the host browser, profiles, cookies, and network are never touched. Refuses to run a browser directly on the host.
version: 1.0.0
when_to_use: User asks to "run web tests", "test the login flow", "scrape this page", "screenshot this URL", "run Playwright/Puppeteer", or invokes "/sandbox". Also use proactively whenever the agent is tempted to launch chrome/chromium/firefox locally on the user's host.
inputs:
  - name: target
    description: URL or local dev server to test (e.g. http://localhost:3000). Defaults to the project's dev script if detected.
  - name: scenario
    description: Optional natural-language description of what to test (login, screenshot, smoke). If absent, the skill runs a generic page-load + screenshot.
required_tools: [bash, read, edit]

# Attribution
# This skill follows the official Microsoft Playwright Docker image
# pattern (mcr.microsoft.com/playwright). The image is published by
# Microsoft and freely usable. The skill body is original work.
# Reference: https://playwright.dev/docs/docker
---

# Sandboxed browser testing skill

## Goal

Whenever the agent needs a browser, **always** run it inside a Docker
container, never against the user's local browser binary or local profile.
Reasons:

- The host browser holds the user's personal cookies, sessions, autofill,
  and extensions — a test run can corrupt or leak any of them.
- A test run can spawn long-lived background processes the agent forgets
  to clean up.
- A bug in the test target (e.g. visiting a malicious URL) is contained
  to the container's filesystem and network.
- Reproducibility: same Playwright + browser version on every machine.

## Hard requirements

Refuse to run if any of these is missing — emit the exact one-line fix:

| Requirement | Fix |
|---|---|
| `docker` on PATH | `opencode-anycli --setup-docker` |
| `docker info` works without sudo | `newgrp docker` (or log out / log in) after `--setup-docker` |
| `mcr.microsoft.com/playwright:latest` image | `docker pull mcr.microsoft.com/playwright:latest` (auto in Step 2) |
| Network egress to mcr.microsoft.com (one-time pull) | confirm with `docker pull hello-world` first |

The agent must NOT install Chrome/Chromium/Firefox on the host, and must
NOT execute `chromedriver`, `geckodriver`, or `npx playwright install`
outside the container. Refuse with a one-line explanation if asked.

## Steps

### Step 0 — pre-flight

```bash
# verify docker without sudo
docker info >/dev/null 2>&1 \
  && echo "docker OK" \
  || { echo "docker not available — run: opencode-anycli --setup-docker, then 'newgrp docker'"; exit 1; }
```

If this fails, STOP and surface the fix command. Do not proceed.

### Step 1 — pick image

The official Microsoft Playwright image is the default:

```bash
IMAGE="mcr.microsoft.com/playwright:latest"
```

Use a pinned version (e.g. `mcr.microsoft.com/playwright:v1.50.0-jammy`)
only if the project's `package.json` lists a specific Playwright version.

### Step 2 — pull image (one-time)

```bash
docker pull "$IMAGE"
```

If the user's network blocks `mcr.microsoft.com`, surface the failure
with the exact registry URL and stop — do not retry against random
mirrors without explicit user approval.

### Step 3 — run the test scenario in a container

For a generic page-load + screenshot:

```bash
TARGET="${1:-http://host.docker.internal:3000}"
OUTDIR="$(mktemp -d -t pw-sandbox-XXXX)"

docker run --rm \
  --network host \
  --ipc=host \
  -v "$OUTDIR":/out \
  -e TARGET="$TARGET" \
  "$IMAGE" \
  bash -c '
    npx -y playwright@latest install chromium >/dev/null 2>&1 || true
    cat > /tmp/test.mjs <<JS
import { chromium } from "playwright";
const target = process.env.TARGET;
const browser = await chromium.launch();
const page = await browser.newPage();
const resp = await page.goto(target, { waitUntil: "networkidle", timeout: 30000 });
console.log("status", resp?.status());
console.log("title", await page.title());
await page.screenshot({ path: "/out/screenshot.png", fullPage: true });
await browser.close();
JS
    node /tmp/test.mjs
  '

echo "Outputs in: $OUTDIR"
ls -la "$OUTDIR"
```

Notes:

- `--network host` lets the container reach `localhost:3000` on Linux.
  On macOS/Windows, replace with `--add-host=host.docker.internal:host-gateway`
  and use `http://host.docker.internal:3000` as `TARGET`.
- `--ipc=host` is recommended by Playwright docs to avoid OOM in headless Chromium.
- The `-v "$OUTDIR":/out` mount is the ONLY filesystem path shared with the
  host, and it is a fresh temp directory. No project files are mounted in.

### Step 4 — for project tests (Playwright suite already in repo)

If the project has its own `playwright.config.ts` and tests:

```bash
docker run --rm \
  --network host \
  --ipc=host \
  -v "$PWD":/work \
  -w /work \
  "$IMAGE" \
  bash -c "npm ci && npx playwright test --reporter=list"
```

This mounts the project (read-write — Playwright writes to `test-results/`),
but the browser still runs in the container. The host browser is never
launched.

### Step 5 — clean up

```bash
# `docker run --rm` already removes the container. Just remove the
# temp output dir if you copied what you needed:
rm -rf "$OUTDIR"
```

Do NOT prune images / volumes wholesale. If the user wants to free space:
```bash
docker image rm "$IMAGE"
```

## Output format

Reply with:

1. A one-paragraph plan (image + scenario + what gets mounted).
2. The exact `docker run` command(s) you propose (so the user can review
   before approval).
3. After running, the script's stdout (status, title, file list) plus a
   reference to the screenshot path.
4. If anything failed, the EXACT error line and the next thing to try
   (usually a `--setup-docker` or `newgrp docker` reminder).

## Anti-patterns

- Running `playwright`, `puppeteer`, `chromium`, `chrome`, `firefox`,
  `chromedriver`, or `geckodriver` directly on the host. Always
  containerize.
- `docker run --privileged` — unnecessary for browser tests; rejected.
- Mounting `$HOME` or anything outside the project root and `$OUTDIR`.
- `docker run -v /var/run/docker.sock:/var/run/docker.sock` (Docker-in-
  Docker socket exposure). Hard NO unless the user explicitly asks for
  it after being warned.
- Pinning to a Playwright version that doesn't match the project's
  `package.json` — silently uses a different browser engine.
- Pulling images from random registries (e.g. `playwright/playwright`).
  Use only `mcr.microsoft.com/playwright`.
- Skipping `--ipc=host` and getting OOM crashes the agent then "diagnoses"
  as flaky tests.
- Forgetting to copy the screenshot out before `rm -rf "$OUTDIR"`.

## When NOT to use this skill

- Pure-JS unit tests with no browser (use the project's `npm test` directly).
- Server-side integration tests that don't open a browser.
- Documentation lookups — no test execution needed at all.
