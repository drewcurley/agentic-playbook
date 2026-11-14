---
id: T-NNN
title: <one-line imperative — e.g. "Add single sign-on login flow">
parent: —
owner: <agent-name — analyst | architect | data-engineer | backend-engineer | frontend-engineer | ux-designer | sdet | devops | review-coordinator>
state: proposed
spec_format: 1   # task-file format version; the ready check reads it (tasks/README.md#definition-of-ready)
branch: —
pr: —
commit: —   # optional — derived after merge (git log --grep T-NNN); never hand-record your own SHA
review_artifact: —
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# T-NNN — <title>

## Description
What this task delivers. Why now. Link to source request (issue / Slack thread / meeting note).

## Users and stakeholders
<!-- Who asked (the requester), who uses it daily, who else is affected. `None.` is fine. -->
- …

## Acceptance criteria
<!-- One testable checkbox per outcome. Edge and error cases are criteria of their own. -->
- [ ] <given> … <when> … <then> …
- [ ] …

## Non-functional requirements
<!-- Performance; security and privacy; accessibility; reliability; data and compliance (name any regulation). One line is fine, e.g. `n/a — docs-only change.` -->
- …

## Assumptions
<!-- Each guess written down so it can be proven wrong. `None.` is fine. -->
- …

## Open questions
<!-- Only what the requester can answer. `None.` is fine. The task can't enter in-review while one is open. One line each, e.g.:
- [ ] Q1 — Which regions launch first?
- [x] Q2 — Is CSV export needed? — Answer (2026-01-05, Jane Doe, https://github.com/org/repo/pull/12#issuecomment-1): not this quarter.
- [x] Q3 — Which SSO providers? — Deferred to T-042: needs the vendor review first.
-->
- …

## Out of scope
- …

## Plan
<!-- Written once the spec is ready, before plan review: what changes, which files, what approach. -->

## Subtasks
<!-- Only if this task has subtasks. Each subtask lives in its own file. -->
- [T-NNN.1](./T-NNN.1.md) — <title>
- [T-NNN.2](./T-NNN.2.md) — <title>

## Risks / dependencies
- …

## Notes
<!-- Blockers, decisions, supersessions. Append; never rewrite. -->

## Activity log
<!-- Append-only. One line per transition. -->
- YYYY-MM-DD — proposed by <agent or human>
- YYYY-MM-DD — moved to in-review once ready (spec ready, plan drafted)
- YYYY-MM-DD — plan signed off by <agents>
- YYYY-MM-DD — plan approved by <owner/DRI>: "<their exact words>" (<comment URL> | in session)   # tasks/README.md#plan-approval
- YYYY-MM-DD — moved to in-progress on branch <name>
- YYYY-MM-DD — completed in PR #<n>; review at <path>   # set state=completed in THIS pr, not a follow-up
