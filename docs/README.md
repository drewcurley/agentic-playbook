# `/docs` — Project Living Memory

This folder is the project's **living memory and source of truth**. Every AI agent (Claude Code, Codex, Cursor, etc.) is required by `AGENTS.md` to read every file here at the start of every session before doing any work.

## The bar this folder must meet

The test for whether `/docs/` is good enough is a single sentence:

> **An agent who has read only `/docs/` should be able to make a commit with high confidence that it will not break an existing route, data contract, integration, or behavior.**

That is a much higher bar than "documentation that describes the project." It means the docs must be **complete enough** to enumerate everything an autonomous change could break, and **accurate enough** that nothing in them is a plausible-sounding guess. Both are enforced by the **Grounding & Completeness Protocol** in `AGENTS.md` § 6.0 — read it before drafting or reviewing any doc.

## Why this folder matters

Without it, every session starts cold. The agents re-derive architecture from grep, re-discover conventions by trial and error, re-invent the wheel each time, and — worst — invent **wrong** facts that look plausible. A confident agent acting on a wrong fact ships a confident, wrong commit. This folder prevents that — but only if it is grounded in real code and kept current with it.

## The Grounding & Completeness Protocol (summary)

Full version in `AGENTS.md` § 6.0. No agent may sign off on a doc unless it is:

- **Grounded, not guessed** — every claim traceable to a real file / route / schema / config / workflow; cite paths where practical.
- **Free of invented facts** — anything unconfirmed is written `UNKNOWN — needs human confirmation`, never as if settled.
- **Exhaustive where it's a contract** — routes, schemas, events, public signatures, env vars, flags, integrations are listed in full, not sampled. No "etc." in a contract inventory.
- **Explicit about invariants & blast radius** — each contract notes what must stay true and what depends on it.
- **Verified** — the drafting agent records how it checked the doc against the code; reviewers re-check against the source, not just the prose.
- **Self-dating** — each doc names the code paths that, when changed, require it to be updated.

Greenfield repo with little code yet? Mark the doc **forward-looking** (intended state) rather than **descriptive** (what exists). Never blur the two.

## Hard rule — unanimous consensus

**No file in this folder may be added, edited, or removed without sign-off from all 9 agents** defined in `AGENTS.md`. The Review Coordinator (`.claude/agents/review-coordinator.md`) drives this process. One wrong fact here propagates into every future session, so the bar is deliberately high.

If a single agent BLOCKs a `/docs/*` change, the change does not land.

## What goes here

If `/docs/` is empty (which it is in this starter), the **first task of the first session** is to run the **Docs Bootstrap Workflow** (`AGENTS.md` § 6) to populate it.

Recommended files — rename or omit anything that doesn't apply to your stack:

### Tier 1 — required before any feature work begins

Tier 1 includes the **contract-critical docs** (`contracts.md`, `api.md`, `data-model.md`) on purpose: the moment feature work begins, an agent must already have the full inventory of what it could break.

| File | Owner (lead author) | Purpose |
|------|---------------------|---------|
| `architecture.md` | Architect | System overview, services, data flow, trust boundaries on `[insert cloud provider here]`. |
| `contracts.md` ⭐ | Backend + Data Engineer + Architect | **The exhaustive, code-grounded inventory** of every route/endpoint, request/response contract, event/message schema, public interface/signature, third-party integration, environment variable, feature flag, cron/queue, and cross-cutting invariant. The single most important doc for safe autonomous commits. Must be complete (§ 6.0(3)), not a sample. May point to reproducible machine-readable sources (OpenAPI / schema dumps) as long as the pointers are exact. |
| `api.md` | Backend | API surface narrative: protocol, conventions, auth model, versioning/deprecation, and **how to add or change a route safely** (the rules behind the `contracts.md` list). |
| `data-model.md` | Data Engineer | Schema overview, **every** key table/collection with columns, indexes, PII classification, migration approach for `[insert database here]`, and **how to change the schema safely** (reversibility, deploy sequencing, backfill). |
| `stack.md` | Architect | Languages, frameworks, services in use, and *why* each was chosen. |
| `testing.md` | Test Engineer | Test strategy, levels, coverage gates, test-data approach, and the **regression-safety check** an agent runs to prove a change didn't break a documented contract. |
| `deployment.md` | DevOps | Environments, Continuous Integration / Continuous Delivery pipeline on `[insert Continuous Integration provider here]`, promotion path, rollback. |
| `ownership.md` | Architect + Analyst | Directly Responsible Individual map for multi-engineer teams — who owns what, who tiebreaks, on-call rotation pointer. Mirrors `.github/CODEOWNERS`. |
| `onboarding.md` | Analyst | First-day path for new engineers: read order, development setup, communication channels, first-pull-request expectations. |
| `decisions/` (skeleton + Architectural Decision Record 0001) | Architect | One Architectural Decision Record per significant decision; never edit a past Architectural Decision Record, supersede it. |
| `reviews/` (skeleton) | Review Coordinator | Review artifacts from past pull requests, organized by branch. |

### Tier 2 — required by end of the first feature sprint

| File | Owner (lead author) | Purpose |
|------|---------------------|---------|
| `domain.md` | Data Engineer + Analyst | Business domain, entities, key relationships. |
| `ux.md` | UX Designer | Personas, primary journeys, design-system pointers, accessibility baseline. |
| `glossary.md` | Analyst | Every term used in the codebase, defined once. |
| `runbooks/` | DevOps | One file per on-call procedure. |

> **Tier 1 vs. Tier 2 is a discipline tool, not a license to skip.** Both tiers carry the unanimous 9-agent consensus rule. Tier 2 missing past the first sprint is a process failure that should be retrospected.

## How to use this folder during a session

**You are an agent.** At session start:

1. List every file under `/docs/`.
2. Read every file (or, for very large repos, at least the files relevant to the user's request — but ALWAYS read `architecture.md`, `contracts.md`, `data-model.md`, `domain.md`, `glossary.md`, and `stack.md`).
3. Acknowledge to the user what you loaded — one line: *"Loaded N docs: architecture.md, contracts.md, domain.md, …"*
4. **Before changing anything, check `contracts.md`.** If your change touches a documented route, schema field, event, public signature, integration, env var, or flag, treat it as a contract change: run the regression-safety check (`AGENTS.md` § 7) and update `contracts.md` in the same pull request.
5. Proceed with the user's request, applying what you learned.

**You are a human reviewing a pull request.** Check that any `/docs/*` change has the review artifact attached and 9-of-9 sign-offs. If not, comment "blocked: needs unanimous consensus per AGENTS.md".

## Anti-patterns

- ❌ Editing a doc to match a code change without running the review cycle.
- ❌ Adding a "draft" doc that no one's signed off on — drafts live on a branch, not in `/docs/`.
- ❌ Leaving unreplaced `[insert … here]` placeholders. Either fill them in, remove the line, or open an Architectural Decision Record explaining why it's still undecided.
- ❌ Writing prescriptive style/lint rules here — those belong in tooling configs, not in living memory.
- ❌ **Inventing a fact because it sounds right.** If it isn't confirmed by the code or the human, it's `UNKNOWN`, not a sentence that reads as settled. A plausible guess in living memory is a landmine.
- ❌ **Sampling a contract inventory.** "The main routes are …" or "tables include …" is a BLOCK. Contracts are listed in full or the doc points to an exact, reproducible machine-readable source.
- ❌ **Letting `contracts.md` drift behind the code.** A change to a documented contract and its doc update are one atomic pull request, never "I'll update the docs later."
