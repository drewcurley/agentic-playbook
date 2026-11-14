#!/usr/bin/env sh
# Every fixture suite runs in CI (starter T-015): each scripts/test/test-*.sh must be
# a step in azure-pipelines.yml and in the GitHub workflow (active or parked), so a
# new suite can't be added and silently never run. A commented-out step doesn't count.
# Every CI file also pins the same shellcheck version and checksum and uses both in its
# download (starter T-021), so the CI systems lint with the same binary. Starter T-022
# adds: one pinned Ubuntu image across both files; a least-privilege GitHub workflow
# (actions pinned by SHA, no ${{ }} in run: scripts); only one workflow path at a time;
# the local shellcheck steps in .githooks/README.md match the CI pin; and the docs no
# longer describe GitHub Actions as parked or unapproved. Starter T-024 adds: the
# safe-echo block is byte-identical in scripts/ci-checks.sh and .githooks/pre-commit;
# neither prints a raw file name or subject; every se_safe call checks its status; the
# scan decisions read content only (cut -f2-); every git diff/show pins its output
# shape; and both CI files run the two scan suites under bash as well.
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

# gh_workflow <root>: the GitHub workflow's path (active, else parked), or nothing.
gh_workflow() {
  for c in .github/workflows/checks.yml .github/workflows-disabled/checks.yml; do
    [ -f "$1/$c" ] && { echo "$c"; return 0; }
  done
}

# check_paths <root>: the workflow lives at one path, not both.
check_paths() {
  if [ -f "$1/.github/workflows/checks.yml" ] && [ -f "$1/.github/workflows-disabled/checks.yml" ]; then
    echo "FAIL: both .github/workflows/checks.yml and .github/workflows-disabled/checks.yml exist"
  fi
}

# check_images <root>: every uncommented vmImage:/runs-on: is the same pinned image.
check_images() {
  r=$1 all=''
  for c in azure-pipelines.yml .github/workflows/checks.yml .github/workflows-disabled/checks.yml; do
    [ -f "$r/$c" ] || continue
    imgs=$(sed -nE 's/^[[:space:]]*(vmImage|runs-on):[[:space:]]*([^[:space:]#]+).*/\2/p' "$r/$c")
    [ -n "$imgs" ] || echo "FAIL: $c names no runner image"
    for i in $imgs; do
      case "$i" in *-latest) echo "FAIL: $c uses the floating image $i" ;; esac
      all="$all
$i"
    done
  done
  n=$(printf '%s\n' "$all" | grep -v '^$' | sort -u | wc -l | tr -d ' ')
  [ "$n" -le 1 ] || echo "FAIL: the CI files use $n different images:$(printf '%s\n' "$all" | grep -v '^$' | sort -u | tr '\n' ' ')"
}

# check_gh_privs <root>: the GitHub workflow runs with least privilege.
check_gh_privs() {
  c=$(gh_workflow "$1")
  [ -n "$c" ] || return 0
  f="$1/$c"
  grep -qx 'permissions: {}' "$f" || echo "FAIL: $c has no top-level 'permissions: {}'"
  grep -n ': write' "$f" | grep -v '^[0-9]*:[[:space:]]*#' | sed "s|^|FAIL: $c grants write access: |"
  awk -v c="$c" '
    function report() {
      if (!perm) print "FAIL: " c " job " job " lacks permissions: contents: read"
      if (!to) print "FAIL: " c " job " job " has no timeout-minutes"
    }
    /^jobs:/ { injobs = 1; next }
    injobs && /^  [A-Za-z0-9_-]+:[[:space:]]*$/ { if (job != "") report(); job = $1; sub(/:$/, "", job); perm = 0; to = 0; next }
    job != "" && /^    permissions:/ { getline nxt; if (nxt ~ /^      contents: read[[:space:]]*$/) perm = 1 }
    job != "" && /^    timeout-minutes:/ { to = 1 }
    END { if (job != "") report() }' "$f"
  n_co=$(grep -c 'uses: actions/checkout@' "$f"); n_pc=$(grep -c 'persist-credentials: false' "$f")
  [ "$n_co" -eq "$n_pc" ] || echo "FAIL: $c has $n_co checkout steps but $n_pc with persist-credentials: false"
  grep -nE '^[[:space:]]*(- )?uses:' "$f" | grep -vE '@[0-9a-f]{40}([[:space:]]|$)' \
    | sed "s|^|FAIL: $c uses an action not pinned to a commit SHA: |"
  # ${{ }} inside a run: script is pasted into the shell text; values go through env:.
  awk -v c="$c" '
    /^[[:space:]]*(- )?run:/ { match($0, /^[[:space:]]*(- )?/); ind = RLENGTH; inrun = 1
      if ($0 ~ /\$\{\{/) print "FAIL: " c ":" NR " has ${{ }} in a run: script"; next }
    inrun { match($0, /^[[:space:]]*/)
      if ($0 !~ /^[[:space:]]*$/ && RLENGTH < ind) inrun = 0
      else if ($0 ~ /^[[:space:]]*-?[[:space:]]*[A-Za-z_-]+:/ && RLENGTH <= ind) inrun = 0
      else if ($0 ~ /\$\{\{/) print "FAIL: " c ":" NR " has ${{ }} in a run: script" }' "$f"
}

# check_az_timeouts <root>: every Azure job sets timeoutInMinutes (the default is 60).
check_az_timeouts() {
  [ -f "$1/azure-pipelines.yml" ] || return 0
  awk 'function report() { if (job != "" && !to) print "FAIL: azure-pipelines.yml job " job " has no timeoutInMinutes" }
    /^  - job:/ { report(); job = $3; to = 0; next }
    job != "" && /^    timeoutInMinutes:/ { to = 1 }
    END { report() }' "$1/azure-pipelines.yml"
}

# check_local_pin <root>: .githooks/README.md's local shellcheck steps use the CI pin.
check_local_pin() {
  [ -f "$1/azure-pipelines.yml" ] || return 0
  v=$(sed -n 's/^[[:space:]]*SHELLCHECK_VERSION:[[:space:]]*//p' "$1/azure-pipelines.yml" | head -n 1)
  h=$(sed -n 's/^[[:space:]]*SHELLCHECK_SHA256:[[:space:]]*//p' "$1/azure-pipelines.yml" | head -n 1)
  f="$1/.githooks/README.md"
  if [ ! -f "$f" ]; then echo "FAIL: .githooks/README.md is missing"; return 0; fi
  grep -qF "$v" "$f" || echo "FAIL: .githooks/README.md doesn't name the CI's shellcheck $v"
  grep -qF "$h" "$f" || echo "FAIL: .githooks/README.md doesn't give the CI's shellcheck checksum"
}

# check_framing <root>: the user-facing docs don't call GitHub Actions parked or unapproved.
check_framing() {
  for f in README.md AGENTS.md ADOPTING.md .githooks/README.md .githooks/pre-commit .githooks/commit-msg \
           .githooks/pre-push scripts/setup-hooks.sh scripts/setup-workspace.sh scripts/build_deck.py \
           tasks/T-002.md azure-pipelines.yml .github/workflows/checks.yml \
           .github/workflows-disabled/checks.yml; do
    [ -f "$1/$f" ] || continue
    grep -n -i -E 'not yet approved|unapproved|approved for (your|general|the) org|actions (is )?parked|parked (at|gh|github)|\(parked\)|ci-off' "$1/$f" \
      | sed "s|^|FAIL: $f still calls Actions parked or unapproved: |"
  done
}

# --- PR-controlled text never reaches the log (starter T-024) ------------------------
se_scripts='scripts/ci-checks.sh .githooks/pre-commit'

# check_block <root>: one safe-echo block per script, byte-identical in both.
check_block() {
  for s in $se_scripts; do
    [ -f "$1/$s" ] || { echo "FAIL: $s is missing"; return 0; }
    nb=$(grep -c '^# BEGIN safe-echo' "$1/$s"); ne=$(grep -c '^# END safe-echo$' "$1/$s")
    [ "$nb" -eq 1 ] || echo "FAIL: $s has $nb BEGIN safe-echo markers, not 1"
    [ "$ne" -eq 1 ] || echo "FAIL: $s has $ne END safe-echo markers, not 1"
  done
  sed -n '/^# BEGIN safe-echo/,/^# END safe-echo$/p' "$1/scripts/ci-checks.sh" > "$tmp/blk1"
  sed -n '/^# BEGIN safe-echo/,/^# END safe-echo$/p' "$1/.githooks/pre-commit" > "$tmp/blk2"
  [ -s "$tmp/blk1" ] || echo "FAIL: scripts/ci-checks.sh has no safe-echo block"
  cmp -s "$tmp/blk1" "$tmp/blk2" || echo "FAIL: the safe-echo blocks in scripts/ci-checks.sh and .githooks/pre-commit differ"
}

# check_unsanitized <root>: no message or printf expands a raw name or subject. Comment
# lines are skipped; $sf, $f_diff and the like don't match.
check_unsanitized() {
  for s in $se_scripts; do
    [ -f "$1/$s" ] || continue
    grep -n '' "$1/$s" | grep -v '^[0-9]*:[[:space:]]*#' \
      | grep -E '(^|[[:space:];&|:])(err|fail|die|warn)[[:space:]]+"[^"]*\$\{?(f|first|hit|index_hits)([^A-Za-z0-9_]|$)' \
      | sed "s|^|FAIL: $s prints an unsanitized name: |"
    grep -n '' "$1/$s" | grep -v '^[0-9]*:[[:space:]]*#' \
      | grep -E '(printf|echo)[^|]*\$\{?(f|first|hit|index_hits)([^A-Za-z0-9_]|$)[^|]*$' \
      | sed "s|^|FAIL: $s prints an unsanitized name: |"
  done
}

# check_se_status <root>: every $(se_safe "...") is followed by ||, so a sanitizer
# failure blocks under bash too (bash drops set -e inside $( )).
check_se_status() {
  for s in $se_scripts; do
    [ -f "$1/$s" ] || continue
    grep -n 'se_safe "[^"]*")' "$1/$s" | grep -v '^[0-9]*:[[:space:]]*#' \
      | grep -vE 'se_safe "[^"]*")[[:space:]]*[|][|]' \
      | sed "s|^|FAIL: $s doesn't check se_safe's status: |"
  done
}

# check_decisions <root>: each grep -q over diff content reads a cut -f2- capture
# (content only), never the N<TAB>content or raw diff text; at least two per script.
check_decisions() {
  for s in $se_scripts; do
    [ -f "$1/$s" ] || continue
    awk -v s="$s" '
      /^[ \t]*#/ { next }
      /=[$][(]printf .*[|] cut -f2-[)]/ { v = $0; sub(/^[ \t]*/, "", v); sub(/=.*/, "", v); cut[v] = 1 }
      /printf .*[|] grep -q/ && match($0, /"[$][A-Za-z_][A-Za-z0-9_]*"/) {
        v = substr($0, RSTART + 2, RLENGTH - 3)
        if (v ~ /^(added|added_n|added_lines|f_added|f_n|f_diff|full_diff|staged_diff)$/) {
          n++; if (!(v in cut)) print "FAIL: " s ":" NR " decides on $" v ", not a cut -f2- capture"
        }
      }
      END { if (n < 2) print "FAIL: " s " has " n + 0 " decision greps on diff content, not at least 2" }' "$1/$s"
  done
}

# check_diff_flags <root>: every $(git ... diff|show ...) pins the output shape, and
# each script unsets GIT_DIFF_OPTS.
check_diff_flags() {
  for s in $se_scripts; do
    [ -f "$1/$s" ] || continue
    awk -v s="$s" '
      /^[ \t]*#/ { next }
      /[$][(]git ([^ ]+ )*(diff|show) / { n++
        if (!index($0, "-c diff.relative=false")) print "FAIL: " s ":" NR " runs git without -c diff.relative=false"
        if (!index($0, "-c diff.suppressBlankEmpty=false")) print "FAIL: " s ":" NR " runs git without -c diff.suppressBlankEmpty=false"
        if (!index($0, "--no-color")) print "FAIL: " s ":" NR " runs git without --no-color"
        if (!index($0, "--submodule=short")) print "FAIL: " s ":" NR " runs git without --submodule=short"
      }
      END { if (!n) print "FAIL: " s " runs no git diff or show" }' "$1/$s"
    grep -qx 'unset GIT_DIFF_OPTS' "$1/$s" || echo "FAIL: $s doesn't unset GIT_DIFF_OPTS"
  done
}

# check_git_quiet <root>: every git call is a $(git ... 2>/dev/null) capture. Git's own
# warnings quote a repo's .gitattributes and .gitmodules, which a PR controls.
check_git_quiet() {
  for s in $se_scripts; do
    [ -f "$1/$s" ] || continue
    awk -v s="$s" '
      /^[ \t]*#/ { next }
      { a = $0; c = gsub(/[$][(]git /, "", a); b = $0; q = gsub(/2>\/dev\/null[)]/, "", b); n += c
        if (q < c) print "FAIL: " s ":" NR " runs git without 2>/dev/null"
        if ($0 ~ /(^|[;&|])[ \t]*git /) print "FAIL: " s ":" NR " runs git outside a $( ) capture" }
      END { if (!n) print "FAIL: " s " runs no git capture" }' "$1/$s"
  done
}

# check_se_where <root>: se_where is only ever handed the sanitized name, $sf.
check_se_where() {
  for s in $se_scripts; do
    [ -f "$1/$s" ] || continue
    grep -n 'se_where' "$1/$s" | grep -v '^[0-9]*:[[:space:]]*#' | grep -v 'se_where() {' \
      | grep -v 'se_where "[$]sf"' | sed "s|^|FAIL: $s passes se_where an unsanitized path: |"
  done
}

# check_bash_steps <root>: each CI file has a step running the two scan suites with
# SH: bash (Ubuntu's sh is dash; bash drops set -e inside $( )). A step is one list item.
# Only the bare form counts: a quoted SH: "bash" is not recognised.
check_bash_steps() {
  for c in azure-pipelines.yml $(gh_workflow "$1"); do
    [ -f "$1/$c" ] || continue
    for suite in scripts/test/test-ci-checks.sh scripts/test/test-pre-commit.sh; do
      awk -v s="$suite" '
        function done_step() { if (hs && hb) found = 1; hs = 0; hb = 0 }
        /^[ \t]*- / { done_step() }
        { line = $0; sub(/^[ \t]*-?[ \t]*/, "", line) }
        line == "script: sh " s || line == "run: sh " s { hs = 1 }
        line == "SH: bash" { hb = 1 }
        END { done_step(); exit !found }' "$1/$c" || echo "FAIL: $c has no SH: bash step for $suite"
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
report "every CI file pins the same shellcheck ($root)" "$(check_pins "$root")"
report "the GitHub workflow lives at one path ($root)" "$(check_paths "$root")"
report "both CI files pin the same runner image ($root)" "$(check_images "$root")"
report "the GitHub workflow runs with least privilege ($root)" "$(check_gh_privs "$root")"
report "every Azure job has a timeout ($root)" "$(check_az_timeouts "$root")"
report "the local shellcheck steps match the CI pin ($root)" "$(check_local_pin "$root")"
report "the docs don't call GitHub Actions parked or unapproved ($root)" "$(check_framing "$root")"
report "the safe-echo block is identical in both scripts ($root)" "$(check_block "$root")"
report "no script prints a raw name or subject ($root)" "$(check_unsanitized "$root")"
report "every se_safe call checks its status ($root)" "$(check_se_status "$root")"
report "the scan decisions read content only ($root)" "$(check_decisions "$root")"
report "every git diff/show pins its output shape ($root)" "$(check_diff_flags "$root")"
report "both CI files run the scan suites under bash ($root)" "$(check_bash_steps "$root")"
report "every git call discards git's own stderr ($root)" "$(check_git_quiet "$root")"
report "se_where only gets the sanitized name ($root)" "$(check_se_where "$root")"

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

# --- Image, privilege, path, local-pin and framing fixtures (starter T-022) ---------
gw() {  # gw <path>: a least-privilege workflow with two jobs
  mkdir -p "$(dirname "$1")"
  cat > "$1" <<'EOF'
on: pull_request
permissions: {}
jobs:
  a:
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    permissions:
      contents: read
    env:
      X: ${{ github.sha }}
    steps:
      - uses: actions/checkout@0123456789abcdef0123456789abcdef01234567 # v9
        with:
          persist-credentials: false
      - run: |
          echo "$X"
  b:
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@0123456789abcdef0123456789abcdef01234567 # v9
        with:
          persist-credentials: false
      - name: s
        run: sh x.sh
EOF
}
fxg() {
  rm -rf "$tmp/fxg"; mkdir -p "$tmp/fxg/.githooks"
  gw "$tmp/fxg/.github/workflows/checks.yml"
  printf 'pool:\n  vmImage: ubuntu-24.04  # pinned\n  # vmImage: ubuntu-latest\n  SHELLCHECK_VERSION: v1.0\n  SHELLCHECK_SHA256: %s\n' "$sha" > "$tmp/fxg/azure-pipelines.yml"
  printf 'Run shellcheck v1.0 (sha256 %s) locally.\n' "$sha" > "$tmp/fxg/.githooks/README.md"
  printf 'GitHub Actions is the default CI. To use only Azure, park the workflow.\n' > "$tmp/fxg/README.md"
}
edit_fx() {  # edit_fx <file> <sed expression>
  sed "$2" "$1" > "$tmp/x" && mv "$tmp/x" "$1"
}
first() {  # first <file> <old line text> [<new line text>]: replace (or drop) the first exact line
  awk -v o="$2" -v n="${3-}" -v drop=$# 'done != 1 && $0 == o { done = 1; if (drop == 2) next; $0 = n } { print }' \
    "$1" > "$tmp/x" && mv "$tmp/x" "$1"
}
g="$tmp/fxg/.github/workflows/checks.yml"
printf 'jobs:\n  - job: a\n    timeoutInMinutes: 5\n  - job: b\n    displayName: b\n' > "$tmp/fxt.yml"
mkdir -p "$tmp/fxt"; mv "$tmp/fxt.yml" "$tmp/fxt/azure-pipelines.yml"
expect_fail "an Azure job without a timeout is caught" "job b has no timeoutInMinutes" "$(check_az_timeouts "$tmp/fxt")"
fxg; report "fixture: a pinned, least-privilege setup passes" "$(check_paths "$tmp/fxg"; check_images "$tmp/fxg"; check_gh_privs "$tmp/fxg"; check_local_pin "$tmp/fxg"; check_framing "$tmp/fxg")"
fxg; gw "$tmp/fxg/.github/workflows-disabled/checks.yml"
expect_fail "both workflow paths at once is caught" "both .github/workflows/checks.yml and" "$(check_paths "$tmp/fxg")"
fxg; first "$g" '    runs-on: ubuntu-24.04' '    runs-on: ubuntu-latest'
expect_fail "a job on ubuntu-latest is caught" "uses the floating image ubuntu-latest" "$(check_images "$tmp/fxg")"
fxg; edit_fx "$tmp/fxg/azure-pipelines.yml" 's/vmImage: ubuntu-24.04/vmImage: ubuntu-22.04/'
expect_fail "two different images are caught" "use 2 different images" "$(check_images "$tmp/fxg")"
fxg; edit_fx "$g" '/^permissions: {}$/d'
expect_fail "a missing top-level permissions: {} is caught" "has no top-level 'permissions: {}'" "$(check_gh_privs "$tmp/fxg")"
fxg; first "$g" '      contents: read' '      contents: write'
out=$(check_gh_privs "$tmp/fxg")
expect_fail "a job with write access is caught" "grants write access" "$out"
expect_fail "...and named as lacking contents: read" "job a lacks permissions: contents: read" "$out"
fxg; first "$g" '    timeout-minutes: 5'
expect_fail "a job without timeout-minutes is caught" "job a has no timeout-minutes" "$(check_gh_privs "$tmp/fxg")"
fxg; first "$g" '          persist-credentials: false'
expect_fail "a checkout that keeps credentials is caught" "2 checkout steps but 1 with persist-credentials: false" "$(check_gh_privs "$tmp/fxg")"
fxg; first "$g" '      - uses: actions/checkout@0123456789abcdef0123456789abcdef01234567 # v9' '      - uses: actions/checkout@v4'
expect_fail "an action pinned by tag is caught" "not pinned to a commit SHA" "$(check_gh_privs "$tmp/fxg")"
fxg
# shellcheck disable=SC2016  # the ${{ }} is the fixture's text
edit_fx "$g" 's/echo "\$X"/echo "${{ github.sha }}"/'
expect_fail "\${{ }} in a run: script is caught" "has \${{ }} in a run: script" "$(check_gh_privs "$tmp/fxg")"
fxg
# shellcheck disable=SC2016  # the ${{ }} is the fixture's text
edit_fx "$g" 's/run: sh x.sh/run: sh x.sh ${{ github.sha }}/'
expect_fail "\${{ }} in a one-line run: is caught" "has \${{ }} in a run: script" "$(check_gh_privs "$tmp/fxg")"
fxg; edit_fx "$tmp/fxg/.githooks/README.md" 's/v1.0/v0.9/'
expect_fail "local steps naming another shellcheck are caught" "doesn't name the CI's shellcheck v1.0" "$(check_local_pin "$tmp/fxg")"
fxg; edit_fx "$tmp/fxg/.githooks/README.md" "s/$sha/b${sha#a}/"
expect_fail "local steps with another checksum are caught" "doesn't give the CI's shellcheck checksum" "$(check_local_pin "$tmp/fxg")"
fxg; printf 'GitHub Actions is not yet approved for general org use.\n' >> "$tmp/fxg/README.md"
expect_fail "\"not yet approved\" wording is caught" "README.md still calls Actions parked or unapproved" "$(check_framing "$tmp/fxg")"
fxg; printf 'Azure DevOps now; GitHub Actions parked.\n' >> "$tmp/fxg/README.md"
expect_fail "\"Actions parked\" wording is caught" "README.md still calls Actions parked or unapproved" "$(check_framing "$tmp/fxg")"

# --- safe-echo fixtures (starter T-024) ----------------------------------------------
# fxs: copies of this tree's two scripts, so each fixture mutates the real code.
fxs() {
  rm -rf "$tmp/fxs"; mkdir -p "$tmp/fxs/scripts" "$tmp/fxs/.githooks"
  cp "$root/scripts/ci-checks.sh" "$tmp/fxs/scripts/ci-checks.sh"
  cp "$root/.githooks/pre-commit" "$tmp/fxs/.githooks/pre-commit"
}
ci="$tmp/fxs/scripts/ci-checks.sh"; pc="$tmp/fxs/.githooks/pre-commit"
fxs; report "fixture: this tree's scripts pass every safe-echo check" \
  "$(check_block "$tmp/fxs"; check_unsanitized "$tmp/fxs"; check_se_status "$tmp/fxs"; check_decisions "$tmp/fxs"; check_diff_flags "$tmp/fxs"; check_git_quiet "$tmp/fxs"; check_se_where "$tmp/fxs")"
fxs; edit_fx "$pc" 's/NR <= 20/NR <= 21/'
expect_fail "a drifted safe-echo block is caught" "safe-echo blocks in scripts/ci-checks.sh and .githooks/pre-commit differ" "$(check_block "$tmp/fxs")"
fxs; printf '# BEGIN safe-echo again\n' >> "$ci"
expect_fail "a second BEGIN marker is caught" "scripts/ci-checks.sh has 2 BEGIN safe-echo markers" "$(check_block "$tmp/fxs")"
fxs; edit_fx "$pc" '/^# END safe-echo$/d'
expect_fail "a missing END marker is caught" ".githooks/pre-commit has 0 END safe-echo markers" "$(check_block "$tmp/fxs")"
# shellcheck disable=SC2016  # the $f etc. are the fixtures' text
for line in '  err "Unreplaced placeholder in $f"' "  die \"git diff -- '\$f' failed.\"" '  fail "bad ${f}"' \
            '  warn "$index_hits is regenerated"' "  printf 'First line: %s\\n' \"\$first\""; do
  fxs; printf '%s\n' "$line" >> "$ci"
  expect_fail "an unsanitized message is caught: $line" "scripts/ci-checks.sh prints an unsanitized name" "$(check_unsanitized "$tmp/fxs")"
done
# shellcheck disable=SC2016
for line in '  err "Unreplaced placeholder in $sf"' "  die \"bad \$f_diff\"" '  # err "x $f"' \
            "  printf '%s\\n' \"\$f\" | grep -q x"; do
  fxs; printf '%s\n' "$line" >> "$pc"
  report "fixture: a safe line isn't flagged: $line" "$(check_unsanitized "$tmp/fxs")"
done
fxs
# shellcheck disable=SC2016
printf '  sf=$(se_safe "$f")\n' >> "$pc"
expect_fail "an unchecked se_safe call is caught" ".githooks/pre-commit doesn't check se_safe's status" "$(check_se_status "$tmp/fxs")"
fxs
# shellcheck disable=SC2016
edit_fx "$ci" 's/printf '"'"'%s\\n'"'"' "$added" | grep -qE/printf '"'"'%s\\n'"'"' "$added_n" | grep -qE/'
expect_fail "a decision on numbered lines is caught" "decides on \$added_n, not a cut -f2- capture" "$(check_decisions "$tmp/fxs")"
fxs
# shellcheck disable=SC2016
edit_fx "$pc" 's/printf '"'"'%s\\n'"'"' "$f_added" | grep -qE/printf '"'"'%s\\n'"'"' "$f_diff" | grep -qE/'
expect_fail "a decision on the raw diff is caught" "decides on \$f_diff, not a cut -f2- capture" "$(check_decisions "$tmp/fxs")"
for flag in ' -c diff.relative=false' ' -c diff.suppressBlankEmpty=false' ' --no-color' ' --submodule=short'; do
  fxs; edit_fx "$ci" "s/$flag//"
  expect_fail "a git diff without$flag is caught" "runs git without$flag" "$(check_diff_flags "$tmp/fxs")"
done
fxs; edit_fx "$pc" '/^unset GIT_DIFF_OPTS$/d'
expect_fail "a script that keeps GIT_DIFF_OPTS is caught" ".githooks/pre-commit doesn't unset GIT_DIFF_OPTS" "$(check_diff_flags "$tmp/fxs")"
fxs
# shellcheck disable=SC2016  # the $... is the fixture's sed text
edit_fx "$ci" 's|"$from" "$head" -U0 2>/dev/null)|"$from" "$head" -U0)|'
expect_fail "a git call that shows git's stderr is caught" "scripts/ci-checks.sh:" "$(check_git_quiet "$tmp/fxs")"
expect_fail "...naming the missing redirect" "runs git without 2>/dev/null" "$(check_git_quiet "$tmp/fxs")"
fxs; printf 'git diff --cached --name-only\n' >> "$pc"
expect_fail "a bare git command is caught" ".githooks/pre-commit:" "$(check_git_quiet "$tmp/fxs")"
expect_fail "...as running outside a capture" "runs git outside a \$( ) capture" "$(check_git_quiet "$tmp/fxs")"
fxs
# shellcheck disable=SC2016  # the $... is the fixture's sed text
edit_fx "$pc" 's/| se_where "$sf"$/| se_where "$f"/'
expect_fail "se_where handed a raw name is caught" ".githooks/pre-commit passes se_where an unsanitized path" "$(check_se_where "$tmp/fxs")"

# bash-step fixtures: an Azure file and a workflow, each with dash and bash runs.
fxb() {
  rm -rf "$tmp/fxb"; mkdir -p "$tmp/fxb/.github/workflows"
  cat > "$tmp/fxb/azure-pipelines.yml" <<'EOF'
      - script: sh scripts/test/test-ci-checks.sh
        displayName: ci-checks
      - script: sh scripts/test/test-ci-checks.sh
        displayName: ci-checks (bash)
        env:
          SH: bash
      - script: sh scripts/test/test-pre-commit.sh
        displayName: pre-commit
      - script: sh scripts/test/test-pre-commit.sh
        displayName: pre-commit (bash)
        env:
          SH: bash
EOF
  cat > "$tmp/fxb/.github/workflows/checks.yml" <<'EOF'
      - name: ci-checks
        run: sh scripts/test/test-ci-checks.sh
      - name: ci-checks (bash)
        env:
          SH: bash
        run: sh scripts/test/test-ci-checks.sh
      - name: pre-commit
        run: sh scripts/test/test-pre-commit.sh
      - name: pre-commit (bash)
        run: sh scripts/test/test-pre-commit.sh
        env:
          SH: bash
EOF
}
fxb; report "fixture: bash steps in both CI files pass" "$(check_bash_steps "$tmp/fxb")"
fxb; first "$tmp/fxb/azure-pipelines.yml" '          SH: bash' '          SH: dash'
expect_fail "a missing Azure bash step is caught" "azure-pipelines.yml has no SH: bash step for scripts/test/test-ci-checks.sh" "$(check_bash_steps "$tmp/fxb")"
fxb; first "$tmp/fxb/.github/workflows/checks.yml" '        run: sh scripts/test/test-pre-commit.sh' '        run: sh scripts/test/test-commit-msg.sh'
first "$tmp/fxb/.github/workflows/checks.yml" '        run: sh scripts/test/test-pre-commit.sh' '        run: sh scripts/test/test-commit-msg.sh'
expect_fail "a workflow without a bash pre-commit step is caught" ".github/workflows/checks.yml has no SH: bash step for scripts/test/test-pre-commit.sh" "$(check_bash_steps "$tmp/fxb")"
fxb; edit_fx "$tmp/fxb/azure-pipelines.yml" 's/^          SH: bash$/          # SH: bash/'
expect_fail "a commented-out SH: bash doesn't count" "azure-pipelines.yml has no SH: bash step" "$(check_bash_steps "$tmp/fxb")"
fxb; printf '      - script: sh scripts/test/test-ci-checks.sh\n      - script: echo x\n        env:\n          SH: bash\n' > "$tmp/fxb/azure-pipelines.yml"
expect_fail "SH: bash on another step doesn't count" "azure-pipelines.yml has no SH: bash step for scripts/test/test-ci-checks.sh" "$(check_bash_steps "$tmp/fxb")"

echo
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
