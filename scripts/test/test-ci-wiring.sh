#!/usr/bin/env sh
# Every fixture suite runs in CI (starter T-015): each scripts/test/test-*.sh must be
# a step in azure-pipelines.yml and in the GitHub workflow (active or parked), so a
# new suite can't be added and silently never run. A commented-out step doesn't count.
# Every CI file also pins the same shellcheck version and checksum and uses both in its
# download (starter T-021), so the CI systems lint with the same binary.
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

# check_pins <root>: one "FAIL: ..." line per shellcheck pin problem in the CI files.
check_pins() {
  r=$1
  ci_files=''
  for c in azure-pipelines.yml .github/workflows/checks.yml .github/workflows-disabled/checks.yml; do
    [ -f "$r/$c" ] && ci_files="$ci_files $c"
  done
  [ -n "$ci_files" ] || { echo "FAIL: no CI file found"; return 0; }
  first='' want=''
  for c in $ci_files; do
    for k in SHELLCHECK_VERSION SHELLCHECK_SHA256; do
      n=$(grep -c "^[[:space:]]*$k:" "$r/$c")
      [ "$n" -eq 1 ] || echo "FAIL: $c sets $k $n times, not once"
    done
    v=$(sed -n 's/^[[:space:]]*SHELLCHECK_VERSION:[[:space:]]*//p' "$r/$c" | head -n 1)
    h=$(sed -n 's/^[[:space:]]*SHELLCHECK_SHA256:[[:space:]]*//p' "$r/$c" | head -n 1)
    case "$h" in
      *[!0-9a-f]*|'') echo "FAIL: $c's SHELLCHECK_SHA256 is not a sha256 hex digest" ;;
      *) [ "${#h}" -eq 64 ] || echo "FAIL: $c's SHELLCHECK_SHA256 is not a sha256 hex digest" ;;
    esac
    # shellcheck disable=SC2016  # the ${...} is the CI file's text, not ours
    grep -qF 'releases/download/${SHELLCHECK_VERSION}/' "$r/$c" \
      || echo "FAIL: $c doesn't download the pinned SHELLCHECK_VERSION"
    # shellcheck disable=SC2016
    grep -q '"${SHELLCHECK_SHA256}  .*" | sha256sum -c' "$r/$c" \
      || echo "FAIL: $c doesn't check the download against SHELLCHECK_SHA256"
    # ...and a mismatch must stop the job: the next line's handler exits 1.
    awk '/sha256sum -c/ { getline nxt; if (nxt ~ /\|\| \{.*exit 1/) ok = 1 } END { exit !ok }' "$r/$c" \
      || echo "FAIL: $c doesn't fail the job on a checksum mismatch"
    if [ -z "$first" ]; then first=$c want="$v $h"
    elif [ "$v $h" != "$want" ]; then echo "FAIL: $c pins shellcheck '$v $h', $first pins '$want'"; fi
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
report "every CI file pins the same shellcheck ($root)" "$(check_pins "$root")"

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

# --- Shellcheck pin fixtures --------------------------------------------------------
sha=$(printf 'a%.0s' 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 \
  33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64)
# pin_file <path> <version> <sha>: a CI file that pins, downloads and checks shellcheck.
pin_file() {
  # shellcheck disable=SC2016  # the ${...} is the fixture's text
  printf '  SHELLCHECK_VERSION: %s\n  SHELLCHECK_SHA256: %s\n          url="x/releases/download/${SHELLCHECK_VERSION}/y"\n          echo "${SHELLCHECK_SHA256}  $tarball" | sha256sum -c - \\\n            || { echo "mismatch"; exit 1; }\n' "$2" "$3" > "$1"
}
fxp() {
  rm -rf "$tmp/fxp"; mkdir -p "$tmp/fxp/.github/workflows-disabled"
  pin_file "$tmp/fxp/azure-pipelines.yml" v1.0 "$sha"
  pin_file "$tmp/fxp/.github/workflows-disabled/checks.yml" v1.0 "$sha"
}
fxp; report "fixture: matching pins pass" "$(check_pins "$tmp/fxp")"
fxp; pin_file "$tmp/fxp/.github/workflows-disabled/checks.yml" v1.1 "$sha"
expect_fail "a different version is caught" "pins shellcheck 'v1.1" "$(check_pins "$tmp/fxp")"
fxp; pin_file "$tmp/fxp/.github/workflows-disabled/checks.yml" v1.0 "b${sha#a}"
expect_fail "a different checksum is caught" "pins shellcheck 'v1.0 b" "$(check_pins "$tmp/fxp")"
fxp; pin_file "$tmp/fxp/azure-pipelines.yml" v1.0 "${sha#a}"
expect_fail "a short checksum is caught" "azure-pipelines.yml's SHELLCHECK_SHA256 is not a sha256 hex digest" "$(check_pins "$tmp/fxp")"
fxp; grep -v SHELLCHECK_SHA256: "$tmp/fxp/azure-pipelines.yml" > "$tmp/x" && mv "$tmp/x" "$tmp/fxp/azure-pipelines.yml"
expect_fail "a missing checksum pin is caught" "azure-pipelines.yml sets SHELLCHECK_SHA256 0 times" "$(check_pins "$tmp/fxp")"
fxp
# shellcheck disable=SC2016  # the ${...} is the fixture's text
sed 's|${SHELLCHECK_VERSION}|v1.0|' "$tmp/fxp/azure-pipelines.yml" > "$tmp/x" && mv "$tmp/x" "$tmp/fxp/azure-pipelines.yml"
expect_fail "a pin the download doesn't use is caught" "azure-pipelines.yml doesn't download the pinned SHELLCHECK_VERSION" "$(check_pins "$tmp/fxp")"
fxp; grep -v 'sha256sum -c' "$tmp/fxp/azure-pipelines.yml" > "$tmp/x" && mv "$tmp/x" "$tmp/fxp/azure-pipelines.yml"
expect_fail "a download that skips the checksum is caught" "azure-pipelines.yml doesn't check the download against SHELLCHECK_SHA256" "$(check_pins "$tmp/fxp")"
fxp; sed 's/exit 1; }/true; }/' "$tmp/fxp/azure-pipelines.yml" > "$tmp/x" && mv "$tmp/x" "$tmp/fxp/azure-pipelines.yml"
expect_fail "a mismatch that doesn't stop the job is caught" "azure-pipelines.yml doesn't fail the job on a checksum mismatch" "$(check_pins "$tmp/fxp")"
fxp; mkdir -p "$tmp/fxp/.github/workflows"; mv "$tmp/fxp/.github/workflows-disabled/checks.yml" "$tmp/fxp/.github/workflows/"
pin_file "$tmp/fxp/.github/workflows/checks.yml" v2.0 "$sha"
expect_fail "an un-parked workflow is checked too" ".github/workflows/checks.yml pins shellcheck 'v2.0" "$(check_pins "$tmp/fxp")"

echo
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
