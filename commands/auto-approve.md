---
description: opencode-anycli의 auto-approve 사용법을 안내합니다 (재시작 명령 + 한계 설명).
argument_hint: "(인자 없음)"
allowed_tools: [bash, read]
---

<command-instruction>
Invoke the `auto-approve` skill. Do not pretend a runtime toggle exists —
opencode's permission system is loaded at session start. The honest answer
is:

   Restart with: opencode-anycli --auto-approve

Aliases: --yolo, -y. Or set OPENCODE_ANYCLI_AUTO_APPROVE=1 in the user's
shell profile.

Reply with three short blocks:
1. The exact restart command.
2. One paragraph on what gets auto-approved (every documented opencode
   permission key set to "allow", with user-set "deny" rules preserved).
3. One paragraph on why there is no runtime toggle, and the brief risk
   warning (only use in throwaway dirs, branches with frequent commits,
   never on production credentials).

The cline subprocess already runs with --yolo; the user only needs to
care about the OUTER opencode permission layer.
</command-instruction>
