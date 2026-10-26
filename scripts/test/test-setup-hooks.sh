#!/usr/bin/env sh
# Fixture test for scripts/setup-hooks.sh.
#
# Stack-neutral: POSIX sh + git only. Runs setup-hooks.sh in a throwaway git repo
# and asserts it installs the hooks and only points operators at CI files that
# exist. Deterministic (no network, no wall-clock, no random; global/system git
# config ignored).
#
# Run:  sh scripts/test/test-setup-hooks.sh
# Exit: 0 all pass, 1 any failure.

set -u

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
playbook_src=$(CDPATH='' cd -- "$test_dir/../.." && pwd)
sut="$playbook_src/scripts/setup-hooks.sh"

GIT_CONFIG_GLOBAL=/dev/null
GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf "  PASS: %s\n" "$1"; }
bad() { fail=$((fail + 1)); printf "  FAIL: %s\n" "$1" >&2; }

echo "test-setup-hooks.sh"

root=$(mktemp -d 2>/dev/null || mktemp -d -t sh)
nogit=$(mktemp -d 2>/dev/null || mktemp -d -t sh)
trap 'rm -rf "$root" "$nogit"' EXIT
mkdir -p "$root/.githooks"
for h in pre-commit commit-msg pre-push; do
  printf '#!/bin/sh\nexit 0\n' > "$root/.githooks/$h"
done
( cd "$root" && git init -q )
out=$( cd "$root" && sh "$sut" 2>&1 ); rc=$?

# 1) Installs: exit 0, core.hooksPath set, hooks executable.
if [ "$rc" -eq 0 ]; then ok "exits 0"; else bad "exits 0 (rc=$rc: $out)"; fi
hp=$( cd "$root" && git config core.hooksPath || true )
if [ "$hp" = ".githooks" ]; then ok "sets core.hooksPath to .githooks"; else bad "sets core.hooksPath (got '$hp')"; fi
if [ -x "$root/.githooks/pre-commit" ] && [ -x "$root/.githooks/commit-msg" ] && [ -x "$root/.githooks/pre-push" ]
then ok "makes hooks executable"; else bad "makes hooks executable"; fi

# 2) Every CI file/script the guidance names exists (it once pointed at
#    .github/workflows/checks.yml after that file was parked — T-012).
named=$(printf '%s\n' "$out" | grep -oE '[A-Za-z0-9_./-]+\.(yml|yaml|sh)' || true)
missing_paths=''
for p in $named; do [ -f "$playbook_src/$p" ] || missing_paths="$missing_paths $p"; done
if [ -n "$named" ] && [ -z "$missing_paths" ]; then ok "names only CI files that exist"
else bad "names missing CI file(s):${missing_paths:- none named}"; fi

# 3) Outside a git repo: refuses with exit 1 and says why.
err=$( cd "$nogit" && GIT_CEILING_DIRECTORIES="$nogit/.." sh "$sut" 2>&1 >/dev/null ); rc=$?
if [ "$rc" -eq 1 ] && printf '%s' "$err" | grep -qF "Not in a git repository"; then ok "refuses outside a git repo"
else bad "refuses outside a git repo (rc=$rc, stderr: $err)"; fi

echo
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
