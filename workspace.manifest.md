<!--
WORKSPACE MANIFEST — template.

This file turns a forked starter into a SHARED PLAYBOOK that governs a single
project split across multiple git repositories. It tells every AI agent, at
session start, which repos make up the project and where each repo's living
memory lives — so an agent launched inside ONE repo can read across ALL of them
and make changes that won't break a sibling repo.

Fill in the repos for your project, commit this file to the playbook repo, and
keep it in sync with reality. The setup-workspace.sh script reads it.

If your project is a SINGLE repo, you don't need a workspace or this file — the
starter works repo-local out of the box. See AGENTS.md § 0.
-->

# Workspace Manifest — [insert product name here]

> **What this is.** This playbook repo is the shared, team-committed home of the
> conventions, the 9-agent team, and the cross-repo integration map for a single
> project that spans multiple repositories. The repos below are expected to be
> checked out **side by side** in the same parent folder (the "workspace"), with
> this playbook as a sibling. See `AGENTS.md` § 0 and `scripts/setup-workspace.sh`.

## Project

- **Name:** [insert product name here]
- **Playbook repo:** [insert git URL of this forked playbook]
- **Workspace layout:** repos are siblings of `playbook/` in a parent folder (see below).

```
<workspace-root>/
├── playbook/        # this repo — policy, agents, hooks, integration-map.md
├── <repo-1>/        # a project repo (own /docs, /tasks, installed hooks)
├── <repo-2>/
└── <repo-3>/
```

## Repositories in this project

> One row per repo. `dir` is the folder name under the workspace root. `contracts` is the
> path (within that repo) to its exhaustive contract inventory. Keep this table exhaustive —
> an agent uses it to know what else to read before making a cross-repo change.

<!-- A filled row looks like this (delete this comment once you've added real rows):
| `web` | Next.js frontend | git@github.com:acme/web.git | `main` | `docs/contracts.md` |
-->

| dir | role | git URL | default branch | contracts doc |
|-----|------|---------|----------------|---------------|
| `[insert repo-1 dir]` | [insert role — e.g. web frontend] | [insert git URL] | `main` | `docs/contracts.md` |
| `[insert repo-2 dir]` | [insert role — e.g. backend API] | [insert git URL] | `main` | `docs/contracts.md` |
| `[insert repo-3 dir]` | [insert role — e.g. infra/IaC] | [insert git URL] | `main` | `docs/contracts.md` |

## Cross-repo truth

- **Integration map (the seams):** [`docs/integration-map.md`](./docs/integration-map.md) — the authoritative record of how these repos depend on each other (APIs consumed, events exchanged, shared env/config contracts). Read it before any change to a documented contract; it is what flags cross-repo blast radius.
- **Project-level living memory:** this playbook's [`docs/`](./docs/) holds the project-wide `architecture.md` and the integration map. Each repo's *own* `docs/` holds that repo's `architecture.md`, `contracts.md`, `data-model.md`, etc.

## How an agent uses this file

1. On session start, after reading this playbook's `docs/` + `integration-map.md`, read this manifest to learn the full repo set.
2. Determine which repo the current working directory belongs to (the "home repo").
3. Read the home repo's own `/docs/` in full — especially its `contracts.md`.
4. Before changing any documented contract in the home repo, consult `integration-map.md` for **consumers in sibling repos**, and read those siblings' `contracts.md` for the affected surface. See `AGENTS.md` § 7 (regression-safety check).

## Maintenance

- Adding a repo to the project? Add a row here, run `scripts/setup-workspace.sh`, and add its edges to `integration-map.md`. This is a `/docs`-adjacent change — run it through the review cycle.
- This manifest is committed to the playbook repo and shared by the whole team. It is the single source of truth for "what repos make up this project."
