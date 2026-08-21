#!/usr/bin/env sh
# Fixture test for scripts/ci-checks.sh.
#
# Stack-neutral: POSIX sh + git only. Builds throwaway git repos in a temp dir,
# makes commits that should pass/fail each gate, and asserts ci-checks.sh exits
# accordingly. Deterministic (no network, no wall-clock, no random).
#
# Run:  sh scripts/test/test-ci-checks.sh
# Exit: 0 all pass, 1 any failure.

set -u

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
playbook_src=$(CDPATH='' cd -- "$test_dir/../.." && pwd)
sut="$playbook_src/scripts/ci-checks.sh"

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf "  PASS: %s\n" "$1"; }
bad() { fail=$((fail + 1)); printf "  FAIL: %s\n" "$1" >&2; }
# expect_rc <actual> <pass-if:0|nonzero> <description>
expect_rc() {
  case "$2" in
    0)       if [ "$1" -eq 0 ]; then ok "$3"; else bad "$3"; fi ;;
    nonzero) if [ "$1" -ne 0 ]; then ok "$3"; else bad "$3"; fi ;;
  esac
}

# Build a repo with a baseline commit; echo its path. Copies the real ci-checks.sh
# and a .placeholder-allow so allowlist behavior matches production.
make_repo() {
  root=$(mktemp -d 2>/dev/null || mktemp -d -t cc)
  mkdir -p "$root/scripts"
  cp "$sut" "$root/scripts/ci-checks.sh"
  printf '# allowlist\nREADME.md\n' > "$root/.placeholder-allow"
  (
    cd "$root" && git init -q && git config user.email t@t && git config user.name t \
      && git config commit.gpgsign false
    echo "baseline" > file.txt
    git add -A && git commit -qm "baseline T-000"
  )
  echo "$root"
}

# run_checks <root>: run ci-checks.sh over base(first commit)..head(HEAD); echo rc.
run_checks() {
  ( cd "$1" \
    && base=$(git rev-list --max-parents=0 HEAD) \
    && head=$(git rev-parse HEAD) \
    && sh scripts/ci-checks.sh "$base" "$head" >/dev/null 2>&1; echo $? )
}

echo "test-ci-checks.sh"

# 1) Clean change with a Task ID passes.
r=$(make_repo)
( cd "$r" && echo "clean line" >> file.txt && git add -A && git commit -qm "feat: clean T-101" )
rc=$(run_checks "$r"); expect_rc "$rc" 0 "clean change passes"
rm -rf "$r"

# 2) Unreplaced placeholder fails.
r=$(make_repo)
( cd "$r" && printf 'use [insert thing here] now\n' >> file.txt && git add -A && git commit -qm "feat: ph T-102" )
rc=$(run_checks "$r"); expect_rc "$rc" nonzero "placeholder in code fails"
rm -rf "$r"

# 3) Placeholder in an allowlisted file passes.
r=$(make_repo)
( cd "$r" && printf 'doc with [insert thing here]\n' >> README.md && git add -A && git commit -qm "docs: ph in allowlisted T-103" )
rc=$(run_checks "$r"); expect_rc "$rc" 0 "placeholder in allowlisted file passes"
rm -rf "$r"

# 4) Secret (fake AWS key) fails. Build the literal at runtime so this test file
#    itself never contains a string the secret-scanner (hook/CI) would flag.
r=$(make_repo)
fake_key="AKIA$(printf 'IOSFODNN7EXAMPLE')"
( cd "$r" && printf 'key=%s\n' "$fake_key" >> file.txt && git add -A && git commit -qm "chore: secret T-104" )
rc=$(run_checks "$r"); expect_rc "$rc" nonzero "secret pattern fails"
rm -rf "$r"

# 5) Commit missing a Task ID fails.
r=$(make_repo)
( cd "$r" && echo "x" >> file.txt && git add -A && git commit -qm "feat: no task id here" )
rc=$(run_checks "$r"); expect_rc "$rc" nonzero "missing Task ID fails"
rm -rf "$r"

# 6) docs/* change without consensus assertion fails.
r=$(make_repo)
( cd "$r" && mkdir -p docs && echo "doc" >> docs/x.md && git add -A && git commit -qm "docs: change T-106" )
rc=$(run_checks "$r"); expect_rc "$rc" nonzero "docs change without consensus fails"
rm -rf "$r"

# 7) docs/* change WITH consensus assertion passes.
r=$(make_repo)
( cd "$r" && mkdir -p docs && echo "doc" >> docs/x.md && git add -A \
   && git commit -qm "docs: change T-107

unanimous-consensus: T-107" )
rc=$(run_checks "$r"); expect_rc "$rc" 0 "docs change with consensus passes"
rm -rf "$r"

echo
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
