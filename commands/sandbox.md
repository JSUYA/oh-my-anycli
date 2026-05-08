---
description: "Run browser tests (Playwright/Puppeteer) inside a Docker sandbox so the host browser, profiles, and cookies are never touched."
argument_hint: "[target URL or dev-server, optional scenario description]"
allowed_tools: [bash, read, edit]
routes_to_skill: sandboxed-browser-testing
---

<command-instruction>
Run the `sandboxed-browser-testing` skill workflow on the user's request.

When to use: User asks to "run web tests", "test the login flow", "scrape this page", "screenshot this URL", "run Playwright/Puppeteer", or invokes "/sandbox". Also use proactively whenever the agent is tempted to launch chrome/chromium/firefox locally on the user's host.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`sandboxed-browser-testing`) is not installed in this environment, follow the
workflow described in skills/sandboxed-browser-testing/SKILL.md.
</command-instruction>
