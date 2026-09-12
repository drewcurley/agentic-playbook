# Agentic Starter

[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-db61a2?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/drewcurley)

A drop-in starter that standardizes how AI coding agents (Claude Code, Codex, Cursor, etc.) collaborate on a project. Works two ways:

- **Single repo** — fork it; the fork *is* your project. `/docs`, `/tasks`, and code live together.
- **Multi-repo project (workspace model)** — fork it as a **shared playbook** that governs a project split across several repos (e.g. `web` / `api` / `infra`) without merging them. The playbook holds project-wide docs + a **cross-repo integration map**; each code repo adopts the playbook's conventions and hooks and keeps its own living memory. This is how a team gets AI to work *across all repos of one project* and make **well-informed** cross-repo changes — an agent changing a contract in one repo *sees which sibling repos consume it* and follows a producer-before-consumer protocol. (Cross-repo safety is **review-enforced, not mechanically guaranteed** — enforcement is per-repo; see the honest limits in [`AGENTS.md` § 6.5](./AGENTS.md).) See the [workspace section below](#multi-repo-the-workspace-model).

It encodes:

- **A 9-agent specialist team** with explicit roles, authorities, and conflict-resolution rules.
- **A 3-round review cycle** that gates every commit.
- **Non-negotiable redlines** per agent, calibrated for enterprise / worldwide / high-stakes use.
- **The 7 strategic lenses** that must clear before any major decision is implemented.
- **A session-start procedure** that grounds every agent in `/docs/` before writing code — and builds `/docs/` (with unanimous consensus) if it doesn't exist.
- **Procedure-enforcing git hooks** plus a server-side Continuous Integration mirror so the conventions aren't optional.
- **Stack-agnostic placeholders** so teams using any cloud, language, or framework can adopt it.

---

## Quickstart

> **Adopting this in a real repo?** Follow **[`ADOPTING.md`](./ADOPTING.md)** — the ordered fork→enforced checklist. It's the difference between conventions that are *enforced* and conventions that merely *look* enforced. The steps below are the 30-second version; `ADOPTING.md` covers the load-bearing parts (CI + branch protection) the quickstart glosses.

The fast path from fork to first agent session. Everything else in this README and `AGENTS.md` is **reference you consult**, not gospel you must read first.

**Single repo** (most common — the fork *is* your project):

```sh
# 1. Copy this starter into your repo (or use it as a template).
# 2. Replace placeholders:
grep -rl '\[insert ' . | xargs $EDITOR        # fill in stack, handles, product name
# 3. Install the procedure hooks (one-time):
sh scripts/setup-hooks.sh
# 4. Start your agent (claude / codex / …). It reads AGENTS.md, then bootstraps /docs on first run.
```

→ You can **skip the entire [workspace section](#multi-repo-the-workspace-model)** below; it's only for multi-repo projects.

**Multi-repo project** (one product across several repos — the fork is a shared *playbook*): see [Multi-repo: the workspace model](#multi-repo-the-workspace-model) for the five-step adoption path. The short version: fork as `playbook/`, fill in `workspace.manifest.md`, check the code repos out beside it, run `sh playbook/scripts/setup-workspace.sh`, then populate `integration-map.md`.

---

## Why this exists

AI coding agents are powerful but inconsistent. The same agent given the same task two weeks apart can produce two very different solutions — different architectural assumptions, different test discipline, different security posture, different awareness of what already exists in the codebase. This starter is the antidote: it gives every agent a stable set of conventions to read at session start, a defined set of specialist roles to inhabit during review, redlines that don't bend under deadline pressure, and a mechanical enforcement layer so the conventions hold even when nobody is watching.

It is calibrated for **high-stakes, worldwide, enterprise** software work. There is a documented [scaling-down path](#scaling-down) for smaller teams and lower-stakes projects.

---

## What's in here

```
.
├── AGENTS.md                       # ⭐ Canonical project conventions. Read this first.
├── ADOPTING.md                     # ⭐ Fork→enforced checklist. Do this when adopting the starter.
├── CLAUDE.md                       # Thin pointer to AGENTS.md so Claude Code uses the same procedure.
├── README.md                       # This file — orientation and walkthrough.
├── workspace.manifest.md           # Multi-repo only: the project's repo roster (see AGENTS.md § 6.5).
├── .gitignore                      # Ignores .claude/settings.local.json, .env*, etc.
├── azure-pipelines.yml             # ACTIVE CI — Azure DevOps mirror of .githooks/ (runs scripts/ci-checks.sh).
├── .github/
│   ├── CODEOWNERS                  # Human review routing — replace placeholders with real handles.
│   ├── pull_request_template.md    # Pull-request template with agent sign-offs + redline check.
│   └── workflows-disabled/
│       └── checks.yml              # Parked GH Actions mirror (GH Actions not yet approved).
│                                   # git mv back to .github/workflows/ to re-enable.
├── .githooks/                      # Stack-neutral procedure-enforcing git hooks.
│   ├── README.md                   # What each hook blocks + bypass policy.
│   ├── pre-commit                  # Branch, placeholders, secrets, /docs warning.
│   ├── commit-msg                  # Task-ID + /docs unanimous-consensus assertion.
│   └── pre-push                    # Block force-push to protected branches.
├── scripts/
│   ├── setup-hooks.sh              # Single repo: git config core.hooksPath .githooks
│   ├── setup-workspace.sh          # Multi-repo: install hooks into every repo in the manifest.
│   ├── ci-checks.sh                # Shared CI gate logic — called by Azure DevOps + (parked) GH Actions.
│   └── test/test-setup-workspace.sh# Fixture tests for setup-workspace.sh.
├── .pre-commit-config.yaml         # Optional pre-commit framework template (stack lint/format).
├── .claude/
│   ├── settings.json               # Project-level Claude Code settings (committed).
│   │                               # Personal overrides go in .claude/settings.local.json (gitignored).
│   └── agents/                     # One subagent per specialist. Invocable from Claude Code.
│       ├── analyst.md
│       ├── architect.md
│       ├── data-engineer.md
│       ├── backend-engineer.md
│       ├── frontend-engineer.md
│       ├── ux-designer.md
│       ├── sdet.md
│       ├── devops.md
│       └── review-coordinator.md
├── tasks/                          # One file per task — parallel-safe ledger.
│   ├── README.md                   # Convention.
│   ├── INDEX.md                    # Derived at-a-glance view; regenerated by Review Coordinator.
│   ├── _TEMPLATE.md                # Copy this for new tasks.
│   ├── T-001.md                    # Parent: bootstrap /docs/ folder.
│   ├── T-001.1.md … T-001.17.md    # Seeded bootstrap subtasks (Tier 1 + Tier 2; T-001.17 = contracts.md).
│   └── T-002.md                    # Seeded: adopt the workspace model (multi-repo only).
└── docs/
    ├── README.md                   # Convention for the project's living docs + the Grounding & Completeness Protocol.
    │                               # Agents read every file in /docs/ at session start.
    │                               # Bootstrap produces (Tier 1): architecture, contracts ⭐, api, data-model,
    │                               # stack, testing, deployment, ownership, onboarding, decisions/, reviews/.
    │                               # contracts.md = the exhaustive, code-grounded inventory of everything an
    │                               # autonomous commit could break (routes, schemas, events, integrations, env, flags).
    └── integration-map.md          # Multi-repo only: the authoritative cross-repo seams (see AGENTS.md § 6.5).
```

---

## The two-ledger model

This starter maintains two living ledgers, each with its own rule:

- **`/docs/*`** — the project's *understanding and source of truth*: architecture, the exhaustive contract inventory (`contracts.md`), domain, decisions, ownership, onboarding, deployment. Built to a standard — an agent reading only `/docs/` can commit without breaking an existing route, data contract, integration, or behavior (the **Grounding & Completeness Protocol**, `AGENTS.md` § 6.0). Edits require **unanimous 9-agent consensus** plus the standard human approval. Slow on purpose. Wrong facts here propagate into every future session.
- **`/tasks/*`** — the project's *work-in-flight*: one file per task, tracked through `proposed → in-review → in-progress → completed | blocked | cancelled`. Updated as part of the normal review cycle. Fast on purpose, and parallel-safe — engineers working on different tasks don't collide on a single ledger file.

---

## Multi-repo: the workspace model

Most real projects are **one product across several repos** that can't easily be merged. This starter supports that without a monorepo migration and without submodules. Full spec in [`AGENTS.md` § 6.5](./AGENTS.md); the shape:

```
<workspace-root>/                 # a plain folder, not a repo
├── playbook/                     # ← this fork, shared & committed by the team
│   ├── AGENTS.md, .claude/agents/, .githooks/
│   ├── workspace.manifest.md     # ⭐ the repo roster (web, api, infra, …)
│   ├── docs/
│   │   ├── architecture.md       #    project-WIDE architecture
│   │   └── integration-map.md    # ⭐ the cross-repo seams (APIs, events, env, stores)
│   ├── tasks/                    #    project-level / cross-repo work
│   └── scripts/setup-workspace.sh#    installs hooks into every repo
├── web/    (its own repo)        # ← adopts the playbook: own docs/ (contracts.md), tasks/, hooks
├── api/    (its own repo)
└── infra/  (its own repo)
```

**How it makes cross-repo changes safe.** An agent launched in *any one* repo reads the playbook's `integration-map.md` first, learns the full repo roster from the manifest, then reads the home repo's `contracts.md`. So when it changes `api`'s route, the integration map tells it *"`web` consumes this"* — and the regression-safety check (`AGENTS.md` § 7) forces a backward-compatible change or a coordinated, producer-before-consumer follow-up. That cross-repo blast-radius signal is exactly what disconnected repos can't give an agent.

**Adopting it (low-friction, mostly scripted):**

1. Fork this starter as your team's **playbook** repo; fill in `workspace.manifest.md` with your repos.
2. Check the code repos out as **siblings** of `playbook/`.
3. Run `sh playbook/scripts/setup-workspace.sh` — installs hooks into every repo, reports any that are missing. Re-run after cloning on a new machine or adding a repo.
4. Wire the CI mirror (Azure DevOps `azure-pipelines.yml`) into each repo, populate `integration-map.md`, and run each repo's own docs bootstrap. Tracked by the seeded task `tasks/T-002.md`.

**Honest limit:** git enforcement is per-repo, so hooks install per-repo (the script does it) and a cross-repo change is two coordinated pull requests, not one atomic commit. The integration map + regression-safety check keep them in step.

> **Single-repo projects ignore all of this** — no `workspace.manifest.md`, no workspace; the starter runs repo-local exactly as before.

---

## The two review gates

Both required for every non-lightweight pull request:

- **Agent review** — the 3-round, 9-specialist cycle defined in `AGENTS.md` § 2. Gates domain expertise and redline compliance.
- **Human review** — at least one approver per `.github/CODEOWNERS`. Gates judgment and accountability.

Agent sign-off does not replace human review. Both are required.

---

## How it works in practice

The system has a specific feel once you're inside it. The walkthroughs below show what a typical interaction looks like.

### A typical session

You open your terminal, change to the repo, and start your AI tool of choice — for example `claude` or `codex`.

Before the agent answers your first request, it runs the **Session Start Procedure** (`AGENTS.md` § 0):

1. **Reads every file in `/docs/`** — architecture, **contracts** (the exhaustive route/schema/integration/env inventory), api, data-model, stack, ownership, onboarding, decisions, etc. This is the project's living memory and source of truth. The agent acknowledges in one line: *"Loaded 11 docs: architecture.md, contracts.md, api.md, …"* — and treats `contracts.md` as binding before changing anything.
2. **Reads `tasks/INDEX.md`** — to see what's in flight, who's on it, and what's stuck. If your request relates to an existing task, the agent references its identifier (`T-NNN`) instead of starting parallel work.
3. **If `/docs/` is empty** — the session's only job becomes building it. The agent tells you so plainly and runs the Docs Bootstrap Workflow before any feature work.

Only after this grounding does the agent answer your request. You can verify this happened: there will be a one-line acknowledgement before any real work.

### A typical pull request

You ask the agent to implement a feature. It does this:

1. **Opens or updates a task file** at `tasks/T-NNN.md` (copying `tasks/_TEMPLATE.md` for new work, picking the next free identifier, setting `state: proposed`).
2. **Creates a feature branch** named `feat/<short-name>` from `main`. The pre-commit hook blocks any direct commit to `main`.
3. **Drafts a plan** — what changes, which files, what approach — and runs the **3-round review** on the plan:
   - **Round 1 (Analysis):** Analyst + Architect + Data Engineer review for scope, security, schema concerns.
   - **Round 2 (Implementation):** Backend + Frontend + UX Designer review for feasibility and user impact.
   - **Round 3 (Verification):** Test Engineer + DevOps review for test coverage and deployment safety.
   - The **Review Coordinator** orchestrates rounds, gathers sign-offs, and produces the review artifact at `/docs/reviews/<branch>/`.
4. **Writes the code** only after the plan is signed off.
5. **Runs the 3-round review on the build** itself.
6. **Runs the regression-safety check** (`AGENTS.md` § 7) — diffs the change against `/docs/contracts.md`, confirms any touched route/schema/event/integration/env var was intended, reflects it back into `contracts.md` (+ `api.md`/`data-model.md`) in the same pull request, and runs the contract/integration/e2e tests that guard it. Records "contracts touched = …; compatibility = …" in the artifact.
7. **Updates the task file in the same PR** — sets `state: completed`, fills in `branch`, `pr` (number), `review_artifact` path, appends to activity log. (No follow-up "mark it done" PR: the ledger update rides in the work PR, so `completed` reaches `main` only when this PR merges. The merge `commit` SHA isn't hand-recorded — it's derived later if needed.)
8. **Commits** with a message that references the task identifier: `feat(area): one-line summary T-NNN`. The commit-msg hook blocks any commit missing a Task identifier.
9. **Pushes immediately** after sign-off (no asking).
10. **Opens a pull request** using `.github/pull_request_template.md` — which already includes slots for all 9 agent sign-offs, 7 strategic lenses (for major decisions), the review artifact link, the regression-safety / contracts-touched section, risk classification, and an explicit redline-cross check.
11. **At least one human reviewer** approves per `.github/CODEOWNERS`. Continuous Integration runs the procedure mirror (`scripts/ci-checks.sh`, via Azure DevOps `azure-pipelines.yml` while GitHub Actions is unapproved) — placeholders, secrets, task identifier, `/docs/*` consensus assertion, pull-request template completeness — all server-side, all bypass-proof.

You'll notice the procedure feels heavy on the first pull request and natural by the third. The friction is calibrated to catch the failures that are expensive in this kind of work.

### A typical /docs change

Documentation lives behind a stronger gate than code:

1. You change `/docs/architecture.md` (or any file under `/docs/`) on a branch.
2. The pre-commit hook warns that the commit-msg hook will require a consensus assertion.
3. You write the commit message: `docs(architecture): clarify trust boundary in payment flow T-042` *plus* a line `unanimous-consensus: T-042` certifying that all 9 agents reviewed and signed off (drives by the Review Coordinator).
4. The commit-msg hook lets it through. Continuous Integration verifies the assertion server-side.
5. The pull request requires all 9 agents to sign off in the template — not just the rounds-appropriate subset.

If unanimous consent stalls, the tiebreaker rule applies (`AGENTS.md` § 3 — the Directly Responsible Individual for the affected area decides, with the reasoning recorded as an Architectural Decision Record).

### A typical lightweight change

For typo fixes, lockfile bumps, comment-only edits, formatter-only churn, and generated-file refreshes, the **lightweight path** (`AGENTS.md` § 5) applies:

- One agent (the Review Coordinator) reviews + one human approver.
- Declared in the pull-request template as "Lightweight review" with one-line justification.
- The Review Coordinator BLOCKs if the change is mis-classified.
- The full list of "does NOT qualify" lives in `AGENTS.md` § 5 — anything user-visible, schema-touching, security-relevant, dependency-introducing, or `/docs`-touching always runs the full cycle.

---

## Getting started in a new project

1. **Copy this folder into a fresh repo** (or use it as a template).
2. **Replace placeholders.** Search for `[insert ` across the repo and fill in your stack details (cloud, framework, database, Continuous Integration provider, secret manager, handles in `CODEOWNERS`, etc.). The full placeholder list is in `AGENTS.md` § 10. The pre-commit hook will block any commit that still contains unreplaced placeholders.
3. **Install hooks:** `sh scripts/setup-hooks.sh` (one-time, per fresh clone). See `.githooks/README.md` for what each hook enforces.
4. **Optional — install the pre-commit framework** if you want stack-specific formatters and linters layered in: `pip install pre-commit && pre-commit install`. Uncomment the relevant stanzas in `.pre-commit-config.yaml`.
5. **Start a session with your AI tool of choice.** It will read `AGENTS.md` (or `CLAUDE.md` for Claude Code, which points to `AGENTS.md`) and follow the session-start procedure.
6. **Let the agents build `/docs/`.** On the first session, since `/docs/` is empty, the agents run the **Docs Bootstrap Workflow** (`AGENTS.md` § 6) to populate it — held to the **Grounding & Completeness Protocol** (`AGENTS.md` § 6.0): grounded in real code, no invented facts, exhaustive where it's a contract. The standard is that an agent who has read only `/docs/` can commit without breaking an existing route, data contract, integration, or behavior. **Tier 1** of the bootstrap (`architecture.md`, **`contracts.md`** ⭐, `api.md`, `data-model.md`, `stack.md`, `testing.md`, `deployment.md`, `ownership.md`, `onboarding.md`, plus the `decisions/` and `reviews/` skeletons) must complete before any feature work — the contract-critical docs are in Tier 1 so the inventory exists before the first feature commit. **Tier 2** (`domain.md`, `ux.md`, `glossary.md`, `runbooks/`) must complete by the end of your first feature sprint. All 17 bootstrap subtasks are pre-seeded in `tasks/T-001*`.
7. **Then work normally.** Every subsequent session begins with the agents re-reading `/docs/` + `tasks/INDEX.md`, then proceeding with whatever you ask. The review cycle gates every commit; Continuous Integration mirrors the local hooks server-side.

---

## Common scenarios — what happens when

**The procedure says BLOCK but the situation genuinely warrants the change.** Crossing an agent redline requires a documented Architectural Decision Record at `/docs/decisions/` accepted by the area's Directly Responsible Individual and leadership. The override is itself reviewable. Redlines are not aspirational — they are the points at which "no" needs a real justification on paper.

**Two humans disagree on the call.** The named Directly Responsible Individual for the affected area decides (per `/docs/ownership.md` and `.github/CODEOWNERS`). If the disagreement spans areas, the next level up decides. Either way, the decision is recorded as an Architectural Decision Record so future engineers can trace the why.

**An agent veto stalls a `/docs/*` change.** Unanimous consent is powerful but can deadlock. See `AGENTS.md` § 0 Step 4 — escalate via the tiebreaker rule, with the reasoning recorded. Persistent vetoes against documented reasoning are themselves reviewable.

**The bootstrap is taking too long for the team's patience.** Tier 1 is the line that should not move — every engineer needs that context. Tier 2 can be deferred beyond the first sprint *if* it's tracked. Missing Tier 2 past one quarter is a flag.

**I'm a small team and 9 agents feels like overkill.** See `AGENTS.md` § 12 — *Scaling Down*. One human can wear multiple agent hats; the lightweight-review threshold can be raised with a documented Architectural Decision Record; Tier 2 docs can be deferred further. What you should *not* turn off: redlines, hooks + Continuous Integration mirror, unanimous consensus on `/docs/*`.

**My stack isn't represented anywhere.** That's intentional. Search the repo for `[insert ` and fill in your stack details. Examples in the placeholder table (`AGENTS.md` § 10) span major clouds, frameworks, databases, and Continuous Integration providers — but you decide what the project actually uses.

---

## Hard rules (from `AGENTS.md` § 8)

- No code without a reviewed plan.
- No commit without agent sign-off.
- No merge without at least one human approver per `.github/CODEOWNERS`.
- No commit without passing automated tests.
- No manual-only testing — every test runs in Continuous Integration.
- No intentional tech debt — build it right or don't build it.
- No edits to `/docs/*` without unanimous 9-agent consensus.
- No agent redline crossed without a documented Architectural Decision Record accepted by the area Directly Responsible Individual and leadership.
- No lightweight-review claim on a change that doesn't qualify.

---

## Why both `AGENTS.md` and `CLAUDE.md`?

- `AGENTS.md` is the convention Codex (and increasingly other agents) read by default.
- `CLAUDE.md` is what Claude Code reads by default.
- `CLAUDE.md` here is intentionally **a thin pointer** to `AGENTS.md` so there's only one source of truth. Edit `AGENTS.md`; never duplicate its content. The goal is identical procedure regardless of which command-line tool the engineer happens to use.

---

## Customizing for your team

The agent definitions in `.claude/agents/*.md` are intentionally written to be edited. If your team needs:

- **Different agents** — add or remove files, update the roster table in `AGENTS.md` § 1.
- **Different review rounds** — update `AGENTS.md` § 2.
- **A 10th lens, or fewer lenses** — update `AGENTS.md` § 4.
- **Different branch naming** — update `AGENTS.md` § 7.
- **Different redlines** — edit `.claude/agents/<agent>.md`. Changes to redlines themselves always run the full review cycle.

Just keep the change list in one place: `AGENTS.md`. `CLAUDE.md`, the hooks, the pull-request template, and the rest follow.

---

## Scaling down

See `AGENTS.md` § 12 for the full scaling-down guidance. The TL;DR (sic — kept here as the section is explicitly about pragmatism):

- One human can wear multiple agent hats, as long as the review still runs role-by-role.
- The lightweight-review threshold can be raised with a documented Architectural Decision Record.
- Tier 2 docs can be deferred, but never abandoned.
- Redlines, hooks + Continuous Integration mirror, and unanimous consensus on `/docs/*` do **not** scale down. They're calibrated to the worst-case stakes for a reason.

---

## Feedback

If you find a rough edge while using this starter on a real project, write it up as an Architectural Decision Record in your project's `/docs/decisions/` so the next team benefits. Improvements to the starter itself land via pull request against this repository, following the same procedure the starter defines.
