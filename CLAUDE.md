# Claude Code — Project Entry Point

> **All project conventions, the 9-agent team, the 7 strategic lenses, the review cycle, and the session-start procedure live in [`AGENTS.md`](./AGENTS.md).**
>
> `AGENTS.md` is the canonical source of truth. This file exists so Claude Code finds the same procedure that Codex and other agents read from `AGENTS.md`. Do not duplicate content here — keep them in sync by editing `AGENTS.md` only.

## Read this first, every session

1. Open and read **[`AGENTS.md`](./AGENTS.md)** in full.
2. Follow the **Session Start Procedure** at the top of that file: first detect whether you're in a single repo or a multi-repo **workspace** (a `workspace.manifest.md` next to a `playbook/`), then read `/docs` (and the playbook's `integration-map.md` in the workspace model), or bootstrap docs if missing.
3. Then respond to the user's request, applying the agent team, review cycle, and hard gates defined there.

> **This repo may be a project, or a shared playbook.** If it contains a `workspace.manifest.md`, this is the **shared playbook** for a multi-repo project (see `AGENTS.md` § 6.5) — the code lives in sibling repos. Otherwise it's a single-repo project. The session-start procedure handles both.

## Claude-Code-specific notes

- Subagents are defined in [`.claude/agents/`](./.claude/agents/). Invoke them via the `Task` / `Agent` tool, one per specialist.
- The Review Coordinator (`.claude/agents/review-coordinator.md`) is the entry point when running a review cycle — it dispatches the other agents.
- Project permissions and settings live in [`.claude/settings.json`](./.claude/settings.json).

## Anything not covered here

→ See `AGENTS.md`. If `AGENTS.md` doesn't cover it, ask the user — don't guess.
