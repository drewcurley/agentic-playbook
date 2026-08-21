# `.githooks/` — Procedure-Enforcing Git Hooks

Stack-agnostic POSIX shell hooks that enforce `AGENTS.md` procedure at commit and push time.

## Install (one-time, per fresh clone)

```sh
scripts/setup-hooks.sh
```

That sets `core.hooksPath` to `.githooks/` and makes the hooks executable. To opt out (not recommended):

```sh
git config --unset core.hooksPath
```

## What each hook does

| Hook | What it blocks | Why |
|------|----------------|-----|
| `pre-commit` | Direct commit to `main` / `master` / `production` / `release` / `trunk` | `AGENTS.md` § 7 — feature-branch workflow |
| `pre-commit` | Any staged content containing `[insert … here]` placeholders | `AGENTS.md` § 8 — hard gate |
| `pre-commit` | Staged content containing AWS keys, private-key blocks, GitHub/Slack/OpenAI/Anthropic tokens (basic regex scan) | Architect redline |
| `pre-commit` | (warn only) `/docs/*` change — flags that commit-msg will require the consensus assertion | `AGENTS.md` § 0 |
| `pre-commit` | (warn only) Hand-edits to `tasks/INDEX.md` — it's a derived view | `tasks/README.md` |
| `commit-msg` | Commit messages missing a Task ID (`T-NNN` or `T-NNN.M`) | `AGENTS.md` § 7 step 8 |
| `commit-msg` | `/docs/*` change without `unanimous-consensus: T-NNN` in the message | `AGENTS.md` § 8 hard gate |
| `pre-push` | Force-push to a protected branch | Safety |

## Bypass policy

`--no-verify` skips local hooks but **does not skip Continuous Integration**. The same checks run server-side via `scripts/ci-checks.sh` — currently in **Azure DevOps** (`azure-pipelines.yml`), since GitHub Actions is not yet approved for general org use (the Actions equivalent is parked at `.github/workflows-disabled/checks.yml`). CI will block the merge. Don't waste a round trip — fix the issue locally.

Genuine false positives (e.g., a regex hit on a legitimate test fixture) are resolved by sanitizing the diff or, as a last resort, an Architectural Decision Record approved by the Directly Responsible Individual.

## Customizing for your stack

These hooks are intentionally stack-neutral. To layer in formatter/linter/type-checker hooks for `[insert language here]`, use the `pre-commit` framework via the template at `.pre-commit-config.yaml`. Both layers can run together.
