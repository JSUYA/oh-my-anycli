---
description: Run browser tests (Playwright/Puppeteer) inside a Docker sandbox so the host browser, profiles, and cookies are never touched.
argument_hint: "[target URL or dev-server, optional scenario description]"
allowed_tools: [bash, read, edit]
---

<command-instruction>
Invoke the `sandboxed-browser-testing` skill.

Hard rules (do not relax without explicit user approval):

1. The browser MUST run inside a Docker container. Never launch
   `chrome`, `chromium`, `firefox`, `chromedriver`, or `geckodriver`
   directly on the host, and never run `npx playwright install` outside
   the container.
2. Use the official Microsoft image `mcr.microsoft.com/playwright:latest`
   unless the project's `package.json` pins a specific Playwright
   version, in which case match it.
3. Mount only a fresh `mktemp -d` output directory and (for project test
   suites) the project root. Never mount `$HOME`, the SSH agent socket,
   or `/var/run/docker.sock`.
4. If `docker info` fails, surface the one-line fix
   (`opencode-anycli --setup-docker`, then `newgrp docker`) and STOP.
   Do not attempt to install a browser on the host as a workaround.
5. Report the exact `docker run` command before executing, then the
   stdout (status + title), the screenshot path, and any error verbatim.
</command-instruction>
