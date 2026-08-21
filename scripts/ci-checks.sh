#!/usr/bin/env sh
# ci-checks.sh — server-side mirror of .githooks/, shared by every CI system.
#
# WHY this exists: the procedure gates must run identically whether CI is GitHub
# Actions, Azure DevOps, or anything else. Keeping the logic here (not inline in a
# pipeline YAML) means the platforms can't drift. Each pipeline just calls this
# script with the diff range; the PR-body-template check is platform-specific
# (different APIs) and stays in the pipeline.
#
# Usage:   sh scripts/ci-checks.sh <base-sha> <head-sha>
#   <base-sha>  merge-base / target-branch tip (range start, exclusive)
#   <head-sha>  tip being validated (range end)
# Exit:    0 all checks pass, 1 any failure. Prints findings to stderr.
#
# Mirrors: .githooks/pre-commit (placeholders, secrets) + .githooks/commit-msg
#          (task ID, /docs consensus). Keep the three in sync.

set -u

base="${1:?usage: ci-checks.sh <base-sha> <head-sha>}"
head="${2:?usage: ci-checks.sh <base-sha> <head-sha>}"

fail=0
err() { printf 'CI-CHECK FAIL: %s\n' "$*" >&2; fail=1; }

rng="$base...$head"
added=$(git diff "$rng" -U0 | grep '^+' | grep -v '^+++' || true)

# --- 1) Unreplaced [insert ... here] placeholders (allowlist-aware) ----------
allow_file=".placeholder-allow"
allowed() {
  [ -f "$allow_file" ] || return 1
  while IFS= read -r pat; do
    case "$pat" in ''|\#*) continue ;; esac
    # shellcheck disable=SC2254  # glob match intended
    case "$1" in $pat) return 0 ;; esac
  done < "$allow_file"
  return 1
}
for f in $(git diff --name-only --diff-filter=ACMR "$rng"); do
  allowed "$f" && continue
  f_added=$(git diff "$rng" -U0 -- "$f" | grep '^+' | grep -v '^+++' || true)
  if printf '%s\n' "$f_added" | grep -qE '\[insert [^]]+ here\]'; then
    printf '%s\n' "$f_added" | grep -nE '\[insert [^]]+ here\]' | sed "s#^#  $f: #" >&2
    err "Unreplaced [insert ... here] placeholder in '$f' (not allowlisted; see .placeholder-allow)."
  fi
done

# --- 2) Basic secret scan ----------------------------------------------------
secret_patterns='AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[ps]_[A-Za-z0-9]{36,}|xox[abprs]-[A-Za-z0-9-]+|sk-[A-Za-z0-9]{20,}|sk-ant-[A-Za-z0-9_-]{20,}'
if printf '%s\n' "$added" | grep -qE "$secret_patterns"; then
  err "Possible secret detected in diff. Sanitize before merge."
fi

# --- 3) Every non-merge commit references a Task ID --------------------------
for sha in $(git log --format=%H "$base..$head"); do
  msg=$(git log -1 --format=%B "$sha")
  first=$(printf '%s' "$msg" | head -n1)
  case "$first" in
    Merge*|Revert*|fixup!*|squash!*|amend!*) continue ;;
  esac
  if ! printf '%s' "$msg" | grep -qE '\bT-[0-9]+(\.[0-9]+)?\b'; then
    err "Commit $sha is missing a Task ID (T-NNN). First line: $first"
  fi
done

# --- 4) /docs/* changes require unanimous-consensus assertion ---------------
# Exception: docs/repos/** is a GENERATED mirror (scripts/aggregate-docs.sh) whose
# content was already gated by consensus in its SOURCE repo — re-gating the mirror
# would demand an assertion on every routine rollup refresh. So a commit needs the
# assertion only if it touches authored /docs files OUTSIDE docs/repos/.
docs_changed=$(git diff --name-only "$rng" | grep -E '^docs/' | grep -vE '^docs/repos/' || true)
if [ -n "$docs_changed" ]; then
  for sha in $(git log --format=%H "$base..$head"); do
    files=$(git show --name-only --pretty="" "$sha" | grep -E '^docs/' | grep -vE '^docs/repos/' || true)
    [ -z "$files" ] && continue
    msg=$(git log -1 --format=%B "$sha")
    if ! printf '%s' "$msg" | grep -qiE 'unanimous-consensus:[[:space:]]*T-[0-9]+(\.[0-9]+)?'; then
      err "Commit $sha touches authored /docs/* but is missing 'unanimous-consensus: T-NNN' in the message."
    fi
  done
fi

if [ "$fail" -eq 0 ]; then
  echo "ci-checks: all procedure gates passed ($rng)"
fi
exit "$fail"
