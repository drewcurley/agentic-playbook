#!/usr/bin/env sh
# Every fixture suite runs in CI (starter T-015): each scripts/test/test-*.sh must be
# a step in azure-pipelines.yml and in the GitHub workflow (active or parked), so a
# new suite can't be added and silently never run. A commented-out step doesn't count.
#
# Run:  sh scripts/test/test-ci-wiring.sh
#       CI_WIRING_ROOT=<dir> sh scripts/test/test-ci-wiring.sh   (check another tree)
# Exit: 0 all pass, 1 any failure.

set -u
LC_ALL=C; export LC_ALL

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
root="${CI_WIRING_ROOT:-$(CDPATH='' cd -- "$test_dir/../.." && pwd)}"

tmp=$(mktemp -d 2>/dev/null || mktemp -d -t cw)
trap 'rm -rf "$tmp"' EXIT

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf "  PASS: %s\n" "$1"; }
bad() { fail=$((fail + 1)); printf "  FAIL: %s\n" "$1" >&2; }

# check_wiring <root>: one "FAIL: ..." line per suite missing from a CI file.
check_wiring() {
  r=$1
  ci_files=''
  for c in azure-pipelines.yml .github/workflows/checks.yml .github/workflows-disabled/checks.yml; do
    [ -f "$r/$c" ] && ci_files="$ci_files $c"
  done
  [ -n "$ci_files" ] || { echo "FAIL: no CI file found"; return 0; }
  ( cd "$r" && find scripts/test -maxdepth 1 -type f -name 'test-*.sh' | sort ) | while IFS= read -r suite; do
    for c in $ci_files; do
      # A step line: "- script: sh <suite>" (ADO) or "run: sh <suite>" (Actions).
      awk -v s="$suite" '
        { line = $0; sub(/^[ \t]*-?[ \t]*/, "", line) }
        line == "script: sh " s || line == "run: sh " s { found = 1 }
        END { exit !found }' "$r/$c" || echo "FAIL: $suite is not a step in $c"
    done
  done
}

# report <description> <check output>
report() {
  if printf '%s\n' "$2" | grep -q '^FAIL'; then
    bad "$1"; printf '%s\n' "$2" | grep '^FAIL' | sed 's/^/    /' >&2
  else ok "$1"; fi
}
# expect_fail <description> <needle> <check output>
expect_fail() {
  if printf '%s\n' "$3" | grep -qF -- "$2"; then ok "$1"
  else bad "$1 (wanted '$2'; got: $3)"; fi
}

echo "test-ci-wiring.sh"

report "every suite runs in every CI file ($root)" "$(check_wiring "$root")"

# --- Fixtures -------------------------------------------------------------------
fx() {
  rm -rf "$tmp/fx"; mkdir -p "$tmp/fx/scripts/test" "$tmp/fx/.github/workflows-disabled"
  printf '#!/bin/sh\n' > "$tmp/fx/scripts/test/test-a.sh"
  printf '#!/bin/sh\n' > "$tmp/fx/scripts/test/helper.sh"   # not a suite
  printf 'steps:\n  - script: sh scripts/test/test-a.sh\n    displayName: a\n' > "$tmp/fx/azure-pipelines.yml"
  printf 'jobs:\n  t:\n    steps:\n      - name: a\n        run: sh scripts/test/test-a.sh\n' > "$tmp/fx/.github/workflows-disabled/checks.yml"
}
fx; report "fixture: a wired suite passes (non-suite scripts are ignored)" "$(check_wiring "$tmp/fx")"
fx; printf '#!/bin/sh\n' > "$tmp/fx/scripts/test/test-b.sh"
out=$(check_wiring "$tmp/fx")
expect_fail "an unwired suite is caught in azure-pipelines.yml" "test-b.sh is not a step in azure-pipelines.yml" "$out"
expect_fail "...and in the GitHub workflow" "test-b.sh is not a step in .github/workflows-disabled/checks.yml" "$out"
fx; printf '#!/bin/sh\n' > "$tmp/fx/scripts/test/test-b.sh"
printf '  # - script: sh scripts/test/test-b.sh\n' >> "$tmp/fx/azure-pipelines.yml"
printf '      - run: sh scripts/test/test-b.sh\n' >> "$tmp/fx/.github/workflows-disabled/checks.yml"
out=$(check_wiring "$tmp/fx")
expect_fail "a commented-out step doesn't count" "test-b.sh is not a step in azure-pipelines.yml" "$out"
if printf '%s\n' "$out" | grep -qF 'not a step in .github'; then bad "a '- run:' step counts (got: $out)"
else ok "a '- run:' step counts"; fi
fx; printf '  - script: sh scripts/test/test-a.sh.bak\n' > "$tmp/fx/azure-pipelines.yml"
expect_fail "a step for a different file doesn't count" "test-a.sh is not a step in azure-pipelines.yml" "$(check_wiring "$tmp/fx")"
fx; rm "$tmp/fx/azure-pipelines.yml" "$tmp/fx/.github/workflows-disabled/checks.yml"
expect_fail "no CI file at all is a failure, not a pass" "no CI file found" "$(check_wiring "$tmp/fx")"

echo
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
