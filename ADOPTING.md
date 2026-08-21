# Adopting this starter — fork → enforced, in order

This is the one checklist that takes a fork from "files copied" to "the conventions
are actually enforced." **Do these in order.** The framework's whole value is
*enforcement* — until branch protection + an active CI check are in place, every
gate (hooks, review cycle, redlines) is advisory and a `--no-verify` push to `main`
bypasses all of it.

> **Single repo vs. multi-repo:** if your project spans several repos, this fork is
> the shared **playbook** — do steps 1–6 in the playbook, then repeat steps 3–5
> (hooks + CI + branch protection) in **each** code repo. See `AGENTS.md` § 6.5.

---

## 1. Fork / copy the repo
Use it as a template or copy the tree into a fresh repo. Keep the directory layout.

## 2. Replace every placeholder
```sh
grep -rl '\[insert ' .          # find them all
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

> If/when GitHub Actions is approved for your org, instead do:
> `git mv .github/workflows-disabled/checks.yml .github/workflows/` and re-enable
> CodeQL in repo settings — then the check is `procedure-checks` with zero setup.

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
