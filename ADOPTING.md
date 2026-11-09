# Adopting this starter — fork → enforced, in order

This is the one checklist that takes a fork from "files copied" to "the conventions
are actually enforced." **Do these in order.** The framework's whole value is
*enforcement* — until branch protection + an active CI check are in place, every
gate (hooks, review cycle, redlines) is advisory and a `--no-verify` push to `main`
bypasses all of it. That includes Claude Code's push prompts in `.claude/settings.json`:
they catch a push that names a protected branch, but not a bare `git push` while on `main`.

> **Single repo vs. multi-repo:** if your project spans several repos, this fork is
> the shared **playbook** — do steps 1–6 in the playbook, then repeat steps 3–5
> (hooks + CI + branch protection) in **each** code repo. See `AGENTS.md` § 6.5.

---

## 1. Fork / copy the repo
Use it as a template or copy the tree into a fresh repo. Keep the directory layout.

`LICENSE` is the starter's MIT license. Keep it, because MIT requires the notice to stay
with copies of these files. Your own code can carry whatever terms you choose.

**Then decide about `.starter/`: will you pull future updates from this starter?**
- **No** (template copy, no upstream sync): `git rm -r .starter` in your first PR. It is the
  starter's own task and decision history, and nothing depends on it.
- **Yes, or not sure:** keep it. Agents ignore it (`AGENTS.md` session start), and deleting
  it would cause a conflict on every sync. You can delete it later. Pick "keep" if you might
  ever add the starter as an upstream remote.

**Then decide about the overview deck.** It describes this starter, not your project, and
nothing depends on it. To drop it, remove all three files in one PR:
`git rm Agentic-Starter-Overview.pptx scripts/build_deck.py scripts/requirements-deck.txt`.
Keep `scripts/test/test-deck.sh` and its CI job: CI then installs nothing and the suite
prints a `SKIP:` line. Removing only some of the three fails the suite. If you delete the
suite as well, remove the `deck` job from both CI files. Under GitHub Actions, also remove
`overview deck (build + compare)` from the required checks.

Your `tasks/` and `docs/` start clean: the docs-bootstrap seeds (`T-001*`, `T-002`) plus
templates. Code and docs that cite **"starter T-0NN"** mean the upstream repo's
`.starter/tasks/T-0NN.md`, not your own T-0NN. Both ledgers use `T-NNN` IDs, so in a synced
repo `git log --grep T-NNN` can match starter commits too.

**Existing forks only: syncing across this change (starter T-015).** Upstream moved its own
history out of `tasks/` and `docs/` into `.starter/`. If the sync conflicts:

- **`tasks/INDEX.md`:** delete the rows for tasks whose files now live in `.starter/tasks/`
  and keep your own.
- **A modify/delete conflict on a starter task, ADR or review file:** keep the file at its
  new path under `.starter/`, even if you had deleted it before. Those files are inert, and
  the ledger test checks that the folder is complete. If you don't want the starter's history
  at all, remove the whole folder instead: `git rm -r .starter`.

The sync also adds two CI steps:

- `scripts/test/test-task-ledgers.sh` fails if a seed task (`tasks/T-001*.md`,
  `tasks/T-002.md`) is missing: restore it from upstream and set `state: cancelled` instead
  of deleting it. While you keep `.starter/`, it also checks that the shipped docs don't
  point into `.starter/` at a file that isn't there, or at a starter file's old path.
- `scripts/test/test-ci-wiring.sh` fails if any `scripts/test/test-*.sh` isn't a step in
  both `azure-pipelines.yml` and the GitHub workflow, written `sh scripts/test/<name>.sh`.
  If you added suites of your own, wire them into both files that way.

**Existing forks only: syncing the deck refresh (starter T-016).** CI gains a `deck` job
that needs Python 3 with `venv`, and access to PyPI or to your own index through
`PIP_INDEX_URL`. If you changed the deck, the suite fails until you drop it as above, or
move your edits into `scripts/build_deck.py`, update the expected values in `test-deck.sh`,
and regenerate from the repo root:
`python3 -m venv ../deck-venv && ../deck-venv/bin/python -m pip install --require-hashes --only-binary :all: -r scripts/requirements-deck.txt && ../deck-venv/bin/python scripts/build_deck.py`.
A PyPI outage turns the required check red: re-run it, and don't use the § 5 break-glass.

**Existing forks only: syncing the push rules (starter T-017).** `scripts/test/test-claude-settings.sh`
fails if `.claude/settings.json` loses a push rule or `.githooks/pre-push` protects a branch
with no rule. Keep the rules, or add one for your branch: `"Bash(git push *<branch>*)"`.

**Existing forks only: syncing the hook file modes (starter T-018).** Upstream now commits the
hooks as executable. If you ran `setup-hooks.sh`, the sync can stop with "commit your changes
or stash them" on `.githooks/*`. If those files show no changes of your own in `git diff`
beyond the mode, run `git restore .githooks`, sync again, then `sh scripts/setup-hooks.sh`.

## 2. Replace every placeholder
```sh
grep -rl --exclude-dir=.starter '\[insert ' .   # find them all
```
Fill in stack, product name, and the **handles in `.github/CODEOWNERS`** (real GitHub
teams/users — these route human review). The pre-commit hook blocks any unreplaced
`[insert … here]`, so CI/commits will fail until this is done. That's intentional.

## 3. Install the git hooks
- **Single repo:** `sh scripts/setup-hooks.sh`
- **Multi-repo playbook:** `sh scripts/setup-workspace.sh` (installs into every repo in `workspace.manifest.md`)

Hooks are **per-repo and per-clone** — every teammate runs this once per fresh clone.
Hooks are the *local* gate; they do **not** survive `--no-verify`. The server-side
backstop is steps 4–5.

## 4. Wire the active CI (Azure DevOps)
GitHub Actions is parked (`.github/workflows-disabled/`, see `AGENTS.md` § 7). The
active CI is Azure DevOps:
1. In your Azure DevOps project, create a pipeline from `azure-pipelines.yml` against
   the GitHub repo (via a GitHub service connection).
2. **Turn on PR validation.** Azure DevOps **ignores the YAML `pr:` trigger for
   GitHub-hosted repos** — you MUST add **Project Settings → Repos → Branch policies
   → Build Validation** on `main`, pointing at the pipeline. Without this, PRs get
   no CI and the gate never runs.
3. (Optional) set a `GITHUB_TOKEN` pipeline secret to enable the PR-body template check.
4. **Land `scripts/` on `main` before requiring the check.** A PR build runs the
   gate from the *target* branch (`scripts/ci-pr-checks.sh`, starter T-014), so it fails
   closed if `main` has no `scripts/ci-checks.sh` yet. Merge the starter's files
   first, then turn on Build Validation.
5. **Fork PRs** (pipeline → Triggers → Pull request validation): leave **"Make
   secrets available to builds of forks" off** and require a team member's comment
   before a fork build runs. The checkout uses `persistCredentials: true`, so a
   build's job token is visible to the pipeline YAML — which a PR can edit.
6. **The `deck` job runs five third-party Python packages from PyPI** (hash-locked in
   `scripts/requirements-deck.txt`). It keeps no git credentials and maps no secrets, but
   Azure's job token still exists on the agent. In Project Settings → Pipelines → Settings,
   limit job authorization scope to the current project, and keep the build identity
   read-only on this repo. To use a mirror, set `PIP_INDEX_URL` as a non-secret pipeline
   variable pointing at an index that needs no login; the hashes still apply. On a
   self-hosted pool the job loses the per-job VM isolation it relies on, so keep it on
   hosted agents or drop the deck (§ 1).

> If/when GitHub Actions is approved for your org, instead do:
> `git mv .github/workflows-disabled/checks.yml .github/workflows/` and re-enable
> CodeQL in repo settings. Confirm a run appears on your first PR; if none does, push a
> commit to that PR. Each job reports as its own check, so require all three:
> `procedure checks`, `shell scripts (lint + test)` and
> `overview deck (build + compare)`. A run that never starts blocks nothing until they're
> required.

## 5. Protect `main` (the keystone) — do this AFTER step 4
Branch protection is what makes every other gate real. Configure on GitHub:
**Settings → Branches → Add branch ruleset (or protection rule) for `main`:**
- ✅ Require a pull request before merging
- ✅ Require approvals: **see "Solo vs. team" below** — and **Require review from Code Owners** *(team only)*
- ✅ Require status checks to pass — select your **Azure DevOps PR validation** check
  (it appears in the list only *after* it has run at least once — open a throwaway PR
  to make it report, then require it)
- ✅ Require branches to be up to date before merging
- ✅ Include administrators (no bypass) — the redlines apply to everyone
- ✅ Block force pushes

> **Solo vs. team — set the approval count to match headcount.** GitHub will **not**
> let you approve your own PR, so on a **one-person repo, set required approvals to `0`**
> (and leave code-owner review **off**) — otherwise every PR deadlocks. You still get
> every *mechanical* gate: no direct push to `main`, PR-based history, required CI
> check, no force-push. **The moment a second maintainer joins, raise approvals to ≥1
> and turn on "Require review from Code Owners"** — that restores the human peer-review
> gate. This is the one protection setting that scales with team size; everything else
> stays the same.

> **What CI can't protect on its own.** A PR build runs the PR's own pipeline YAML,
> and no file in the repo can stop a PR from editing it. The gate logic and the
> placeholder allowlist come from `main` (`scripts/ci-pr-checks.sh`), so weakening
> them takes a visible edit to the YAML or `scripts/ci-*.sh` — and `CODEOWNERS`
> routes those gate files to the devops team + security lead. That only binds once
> **"Require review from Code Owners"** is on; a solo repo relies on its one
> maintainer reading gate-file diffs. Consequences to know:
> - A change to `.placeholder-allow` or `scripts/ci-checks.sh` takes effect on the
>   **next** PR, not the one that makes it. Land an allowlist entry before the file
>   that needs it.
> - Once you've filled in `.github/CODEOWNERS`, remove its line from
>   `.placeholder-allow`, so a stray placeholder there gets caught.
>
> - The gates don't see Git LFS content (only the pointer is in git) or submodule
>   content (only the commit SHA); scan those where they live.
>
> **Break-glass (the gate on `main` itself is broken).** Because PRs are judged by
> `main`'s gate, a PR that fixes a broken gate can be blocked by it. An admin
> temporarily removes the required check — in GitHub (Settings → Branches) **and**
> in Azure DevOps (Branch policies → Build Validation), wherever it is required —
> runs the *fixed* `scripts/ci-checks.sh <base> <head>` by hand against the fix PR
> and pastes the output into the fix's task file, merges the fix PR with the usual
> reviews, and restores the check immediately. Record who, when and why in that
> task file. Never bypass for anything else.

> ⚠️ **Order matters / don't brick the repo:** do NOT require a status check that
> has never reported, and do NOT require Code-Owner review while `CODEOWNERS` still
> has placeholders — either makes *every* PR unmergeable. Finish steps 2 and 4 first.

## 6. First agent session — bootstrap the docs
Start your agent (`claude` / `codex` / …). On the first session `/docs/` is empty, so
the agent runs the **Docs Bootstrap Workflow** (`AGENTS.md` § 6) — Tier 1 (incl. the
exhaustive `contracts.md`) must land before feature work. Just let it run.

## 7. Multi-repo only — aggregate docs into the playbook
Once each repo has its `/docs`, make the playbook the **golden source of truth**:
```sh
sh scripts/aggregate-docs.sh        # mirrors every repo's /docs → playbook/docs/repos/
git add docs/repos && git commit ... # commit the rollup
```
Each repo's `/docs` stays the single writer for its own facts; the playbook holds the
project-wide docs (`integration-map.md`, …) **plus** this generated mirror. Session-start
re-checks for drift automatically and refreshes locally — see `AGENTS.md` § 6.6. Never
hand-edit `docs/repos/**`; edit the source repo's `/docs`.

---

## Definition of "shipped / enforced"
A repo is properly enforced when **all** are true:
- [ ] No `[insert … here]` placeholders remain (CI green).
- [ ] Hooks installed locally by each contributor (`core.hooksPath` = `.githooks`).
- [ ] Azure DevOps pipeline runs on every PR (branch-policy build validation on `main`).
- [ ] `main` is protected: PR required, the CI check required, admins included, force-push blocked, and approvals set to match headcount (**0 solo**; **≥1 + code-owner review** once a second maintainer joins).
- [ ] `CODEOWNERS` routes to real handles.
- [ ] Docs Tier 1 bootstrapped (`/docs/contracts.md` etc. exist).
- [ ] **(Multi-repo)** Playbook rollup current — `sh scripts/aggregate-docs.sh --check` passes.

Until every box is checked, treat the conventions as **advisory** and say so to the team —
don't let a half-configured repo masquerade as an enforced one.
