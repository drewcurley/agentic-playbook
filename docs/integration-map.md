<!--
INTEGRATION MAP — template.

The authoritative, project-level record of the SEAMS between the repos that make
up this project: every cross-repo API call, event/message, shared env/config
contract, and shared data store. This is the file that makes a multi-repo project
safe to change — when an agent edits a contract in one repo, this map tells it
which OTHER repos consume that contract and would break.

This file lives in the PLAYBOOK repo (shared, central). Each repo's own
docs/contracts.md describes that repo's surface; this map connects them.

Held to the same Grounding & Completeness Protocol as every other doc
(AGENTS.md § 6.0): grounded in real code, no invented edges, EXHAUSTIVE — every
cross-repo dependency listed, not a sample. Changes require the /docs/*
unanimous-consensus gate.
-->

# Integration Map — [insert product name here]

> **The seams between repos.** Read this before changing any documented contract.
> If your change touches a row below, the **consumer** repo(s) are in your blast
> radius — run the cross-repo regression-safety check in `AGENTS.md` § 7.
>
> Repos and their individual contract inventories are listed in
> [`../workspace.manifest.md`](../workspace.manifest.md). (Relative paths in this
> template assume the adopted workspace layout — this file at `playbook/docs/` and
> the manifest at `playbook/`. In the unadopted starter fork the manifest is at the
> repo root, one level up from where the link resolves.)
>
> ⚠️ **Residual risk — a missing edge here is undetectable by tooling.** Because the
> repos are separate, no git hook or CI in one repo can see that another repo added
> a consumer. This map is therefore enforced **only by the § 6.0 review discipline**
> (exhaustive, grounded, no invented edges), not mechanically. Treat an absent edge
> as "not yet verified," not "proven safe." Keeping this map exhaustive is the price
> of avoiding a monorepo.

## How to read this

- A **producer** owns/exposes the contract (a route, an event, an env var it provides).
- A **consumer** depends on it. If the producer changes the contract, every consumer is at risk.
- Each edge cites where it lives in code on **both** sides, so the claim is verifiable (§ 6.0).
- `UNKNOWN — needs human confirmation` is the correct entry for any edge not yet verified. Never guess an edge.

## 1. Cross-repo API / RPC calls

> Auth is part of the contract, not a footnote: record how the consumer authenticates to the
> producer and where that credential rotates, or an auth change silently breaks the caller.
> Version + deprecation window bound the transient mixed-version window (§ 8) — without them,
> "keep the old shape alive a while" has no defined end.

| # | Consumer (repo → code site) | Producer (repo → endpoint) | Contract (shape) | Auth / credential + rotation | Version + deprecation window |
|---|------------------------------|-----------------------------|------------------|------------------------------|------------------------------|
| 1 | [insert repo → file] | [insert repo → `METHOD /path`] | [request/response shape or link to producer's contracts.md] | [e.g. service JWT minted by api, rotated via `KEY`] | [e.g. v2; old shape supported ≥ 1 release] |
| … | | | | | |

## 2. Events / messages / webhooks

> The two PRs of a cross-repo change can't pass CI atomically (§ 8), so there is **always** a
> window with mixed-schema messages in flight. Record the schema version and how long the
> consumer must tolerate the old one.

| # | Producer (repo → emit site) | Consumer(s) (repo → handler) | Event + schema (+ version) | Delivery guarantee | Idempotent consumer required? | Old-schema tolerance |
|---|------------------------------|------------------------------|-----------------------------|--------------------|-------------------------------|----------------------|
| 1 | [insert repo → file] | [insert repo → handler] | [event name + payload schema or link; v1] | [at-least-once / ordered] | yes/no | [e.g. accept v1 ≥ 30 days] |
| … | | | | | | |

## 3. Shared environment / config contracts

> Config one repo PROVIDES (e.g. infra) and another CONSUMES (e.g. api expects `DATABASE_URL`).

| # | Provided by (repo) | Consumed by (repo → read site) | Key | Required? | Notes |
|---|--------------------|-------------------------------|-----|-----------|-------|
| 1 | [insert repo] | [insert repo → file] | `[insert KEY]` | yes/no | [default, format, rotation] |
| … | | | | | |

## 4. Shared data stores / schemas

> A table/collection/bucket written by one repo and read by another. The most dangerous
> coupling — a schema change in the writer can silently break the reader. Two distinct
> things must be recorded: the **shape** the reader physically depends on (the thing a
> rename/drop/retype breaks) AND the **invariant** (business rules like soft-delete-only).
> Recording only the invariant misses the rename-a-column class of break.
>
> **Write access:** a shared store must have **exactly one writer per object** unless a row
> is explicitly marked multi-writer (and says which fields each owns). A second, undeclared
> writer is the most insidious shared-store bug — no schema diff catches it.
>
> **Changing a shared schema → use expand/migrate/contract (parallel change):**
> 1. **Expand** — add the new shape additively (writer dual-writes if needed). Backward-compatible.
> 2. **Migrate** — move every reader in this map onto the new shape; confirm each.
> 3. **Contract** — only after all listed readers are confirmed off the old shape, remove it.
> Producer-before-consumer ordering alone does **not** make the destructive contract step safe — the
> contract step is the one that silently breaks readers. See `AGENTS.md` § 6.5 / § 7.

| # | Writer (repo, single/multi) | Reader(s) (repo → query site) | Store + object | Shape contract the reader depends on | Invariant that must hold |
|---|------------------------------|-------------------------------|----------------|--------------------------------------|--------------------------|
| 1 | [insert repo — single-writer] | [insert repo → file] | [DB.table / bucket] | [exact columns/types/fields + read pattern] | [e.g. soft-delete only; money in minor units] |
| … | | | | | |

### 4a. Derived / denormalized cross-repo data

> Repo A maintains a cache, rollup, or denormalized copy of data repo B owns. Invisible
> unless recorded here, and it needs a reconciliation strategy or it silently drifts.

| # | Source of truth (repo → object) | Derived copy (repo → object) | Reconciliation strategy | Staleness tolerance |
|---|----------------------------------|------------------------------|-------------------------|---------------------|
| 1 | [insert repo → object] | [insert repo → object] | [event-driven / scheduled rebuild / on-read] | [e.g. ≤ 5 min] |
| … | | | | |

## 5. Shared libraries / packages

> Internal package published by one repo and depended on by another (version-coupled).

| # | Publisher (repo → package) | Dependents (repo) | Versioning | Breaking-change policy |
|---|-----------------------------|-------------------|------------|------------------------|
| 1 | [insert repo → `@scope/pkg`] | [insert repo(s)] | [semver?] | [deprecation window] |
| … | | | | |

## Cross-cutting cross-repo invariants

> System-wide truths that span repos and must never be violated by a single-repo change.
> Example: "auth tokens issued by `api` are validated by `web` using the shared JWKS — rotating
> the signing key requires a coordinated change in both."

- [insert invariant — and what breaks across repos if violated]
- …

## Freshness — the #1 adoption risk

A **stale map is worse than no map**: it produces confident, wrong cross-repo commits. Because no tooling can detect a missing edge across separate repos (see the header), freshness is a human discipline and the single biggest risk to this model's value. Mitigate it:
- Put a **"last verified: YYYY-MM-DD"** note on each edge (or each section) and treat an old date as "re-verify before trusting."
- Name an **owner** for this map in `ownership.md` who periodically reconciles it against the repos.

## Update-this-doc-when

Update this map in the same change that:
- adds, changes, or removes a cross-repo API call, event, shared env key, shared store object, or shared package;
- adds or removes a repo from the project (also update `../workspace.manifest.md`).

This is a `/docs/*` change → unanimous 9-agent consensus required.
