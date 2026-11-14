#!/usr/bin/env sh
# Fixture tests for the task-ready block (starter T-023): the definition of ready that
# scripts/ci-checks.sh (check 5) and .githooks/pre-commit (check 6) run on task files.
#
# The block is extracted from scripts/ci-checks.sh, with the safe-echo block it calls,
# and run directly on fixture files. Every failing case asserts the exact findings
# (code and location), never just the exit code. The cases run under every shell and
# every awk found here (sh, dash, bash --posix, busybox sh; awk, mawk, gawk, busybox
# awk), each awk put first on PATH through a shim directory. In CI a missing mawk,
# Ubuntu's default awk, is a FAIL; a missing gawk or busybox is a visible SKIP.
# Deterministic: temp files only, no git, no network.
#
# Run:  sh scripts/test/test-task-ready.sh
#       CI_CHECKS=<path> sh scripts/test/test-task-ready.sh   (test another copy)
# Exit: 0 all pass, 1 any failure.

set -u
LC_ALL=C; export LC_ALL

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH='' cd -- "$test_dir/../.." && pwd)
src="${CI_CHECKS:-$root/scripts/ci-checks.sh}"

tmp=$(mktemp -d 2>/dev/null || mktemp -d -t tr)
trap 'rm -rf "$tmp"' EXIT

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf "  PASS: %s\n" "$1"; }
bad() { fail=$((fail + 1)); printf "  FAIL: %s\n" "$1" >&2; }

echo "test-task-ready.sh"

# --- The block, extracted the way test-ci-wiring.sh compares it ------------------
lib="$tmp/lib.sh"
sed -n '/^# BEGIN safe-echo/,/^# END safe-echo$/p' "$src" > "$lib"
sed -n '/^# BEGIN task-ready/,/^# END task-ready$/p' "$src" > "$tmp/block.sh"
cat "$tmp/block.sh" >> "$lib"
if [ -s "$tmp/block.sh" ]; then ok "the task-ready block was extracted from ci-checks.sh"
else bad "the task-ready block was extracted from ci-checks.sh"; exit 1; fi

# drive.sh <path> <required> <base> <mode>: run tr_check on stdin; print its output
# and exit with its status, like the callers' `tr_rc=0; tr_out=$(...) || tr_rc=$?`.
cat > "$tmp/drive.sh" <<'EOF'
. "$TR_LIB"
tr_rc=0; tr_out=$(tr_check "$1" "$2" "$3" "$4") || tr_rc=$?
[ -z "$tr_out" ] || printf '%s\n' "$tr_out"
exit "$tr_rc"
EOF

# --- Shells and awks ---------------------------------------------------------------
in_ci=0
[ -z "${GITHUB_ACTIONS:-}" ] && [ -z "${TF_BUILD:-}" ] || in_ci=1
# Each shell is one word here; run_sh maps it to its command line.
shells='sh'
command -v dash >/dev/null 2>&1 && shells="$shells dash"
command -v bash >/dev/null 2>&1 && shells="$shells bash-posix"
command -v busybox >/dev/null 2>&1 && shells="$shells busybox-sh"
run_sh() {
  r_s=$1; shift
  case "$r_s" in
    bash-posix) bash --posix "$@" ;;
    busybox-sh) busybox sh "$@" ;;
    *) "$r_s" "$@" ;;
  esac
}
echo "shells: $shells"

# shim <name> <command...>: a directory whose `awk` runs <command...>.
shim() {
  d="$tmp/awk-$1"; mkdir -p "$d"; shift
  printf '#!/bin/sh\n: > "%s/hit"\nexec %s "$@"\n' "$d" "$*" > "$d/awk"; chmod +x "$d/awk"
}
sys_awk=$(command -v awk)
shim awk "$sys_awk"
awks='awk' awk_line='awk=ran'
for a in mawk gawk; do
  if p=$(command -v "$a" 2>/dev/null); then shim "$a" "$p"; awks="$awks $a"; awk_line="$awk_line $a=ran"
  else awk_line="$awk_line $a=skipped"; fi
done
if p=$(command -v busybox 2>/dev/null) && "$p" awk 'BEGIN { exit 0 }' 2>/dev/null; then
  shim busybox "$p awk"; awks="$awks busybox"; awk_line="$awk_line busybox=ran"
else awk_line="$awk_line busybox=skipped"; fi
echo "awks: $awk_line"
case " $awks " in
  *" mawk "*) ;;
  *) if [ "$in_ci" = 1 ]; then bad "mawk (Ubuntu's default awk) must run in CI"; else echo "  SKIP: mawk is not installed here"; fi ;;
esac
for a in gawk busybox; do case " $awks " in *" $a "*) ;; *) echo "  SKIP: $a is not installed here" ;; esac; done
# TR_DISCOVER_ONLY=1 stops here (the self-test of the rule above runs it).
if [ -n "${TR_DISCOVER_ONLY:-}" ]; then [ "$fail" -eq 0 ]; exit; fi
# The rule itself: in CI, a PATH without mawk fails. Run this file's discovery with a
# PATH holding only the tools it needs, and no mawk.
mkdir -p "$tmp/nomawk"
for c in sh dirname mktemp sed cat rm mkdir chmod; do ln -s "$(command -v "$c")" "$tmp/nomawk/$c"; done
ln -s "$sys_awk" "$tmp/nomawk/awk"
o=$(GITHUB_ACTIONS=1 TR_DISCOVER_ONLY=1 PATH="$tmp/nomawk" "$(command -v sh)" "$test_dir/test-task-ready.sh" 2>&1); r=$?
case "$sys_awk" in
  *mawk*) echo "  SKIP: the system awk is mawk, so the no-mawk PATH can't be built" ;;
  *) if [ "$r" -ne 0 ] && printf '%s\n' "$o" | grep -qF "FAIL: mawk (Ubuntu's default awk) must run in CI"; then ok "in CI, a missing mawk fails the suite"
     else bad "in CI, a missing mawk fails the suite (rc=$r)"; fi ;;
esac

# --- Fixtures ----------------------------------------------------------------------
f="$tmp/T-1.md"
# ready <state> [<spec_format line>]: a ready task file whose Open questions section
# is last, so lines added with `add` land in it. Its lines:
#   1 ---  2 id  3 state  4 spec_format  5 ---  6 title  7 Users  8 x  9 AC  10 item
#   11 NFR  12 x  13 Assumptions  14 x  15 Out of scope  16 x  17 Open questions  18 None.
ready() {
  {
    printf -- '---\nid: T-1\nstate: %s\n%s\n---\n# T-1 - a task\n' "$1" "${2-spec_format: 1}"
    printf '## Users and stakeholders\n- the owner\n## Acceptance criteria\n- [ ] it works\n'
    printf '## Non-functional requirements\nn/a - a test.\n## Assumptions\nNone.\n'
    printf '## Out of scope\nNone.\n## Open questions\nNone.\n'
  } > "$f"
}
add() { printf '%s\n' "$@" >> "$f"; }
# edit <sed expression>: change the fixture in place.
edit() { sed "$1" "$f" > "$f.x" && mv "$f.x" "$f"; }

# findings <output>: one "CODE location" line per finding. Only codes, line numbers
# and fixed section names, so a failing case can't print fixture content.
findings() {
  printf '%s\n' "$1" | sed -n 's/^  \(SPEC_[A-Z_]*\) [^ ]*\(.*\) (.*$/\1\2/p' | sed 's/: / /'
}

# expect <description> <rc> [<finding>...]: run the fixture through the block (as
# tasks/T-1.md unless $TR_PATH, required $TR_REQ, base $TR_BASE, mode $TR_MODE) under
# the current shell and awk; the status and the findings (in any order) must match.
expect() {
  e_d=$1 e_rc=$2; shift 2
  e_want=''
  for e_w in "$@"; do e_want="$e_want$e_w
"; done
  e_out=$(PATH="$tmp/awk-$cur_awk:$PATH" TR_LIB="$lib" run_sh "$cur_sh" "$tmp/drive.sh" "${TR_PATH:-tasks/T-1.md}" "${TR_REQ:-0}" "${TR_BASE:--}" "${TR_MODE:-100644}" < "$f"); e_got=$?
  e_f=$(findings "$e_out" | sort)
  # The summary's count must equal the findings parsed, so no line is silently dropped.
  e_n=$(printf '%s\n' "$e_out" | sed -n '1s/^Task .* is not ready (\([0-9]*\) problems*):$/\1/p')
  e_c=$(printf '%s\n' "$e_f" | grep -c .)
  if [ "$e_got" -eq 1 ] && [ "$e_n" != "$e_c" ]; then e_got=99; fi
  e_wf=$(printf '%s' "$e_want" | sort)
  if [ "$e_got" -eq "$e_rc" ] && [ "$e_f" = "$e_wf" ]; then ok "[$cur_sh/$cur_awk] $e_d"
  else
    bad "[$cur_sh/$cur_awk] $e_d (rc=$e_got, want $e_rc)"
    printf '%s\n' "$e_wf" | sed 's/^/      want: /' >&2
    printf '%s\n' "$e_f" | sed 's/^/      got:  /' >&2
  fi
  last_out=$e_out
}
pass0() { expect "$1" 0; }

# --- The cases, run once per shell and awk -------------------------------------------
cases() {
  # Criterion 1: the template.
  cp "$root/tasks/_TEMPLATE.md" "$f"
  pass0 "the template passes while proposed"
  edit 's/^state: proposed$/state: in-review/'
  tl=$(grep -n '^- \[ \] <given>' "$f" | cut -d: -f1)
  expect "the template in review fails with exactly its empty sections and the placeholder criterion" 1 \
    "SPEC_EMPTY_SECTION Users and stakeholders" "SPEC_EMPTY_SECTION Non-functional requirements" \
    "SPEC_EMPTY_SECTION Assumptions" "SPEC_EMPTY_SECTION Open questions" "SPEC_EMPTY_SECTION Out of scope" \
    "SPEC_PLACEHOLDER_AC line $tl"
  # Criterion 10: the template's example lines, uncommented, give exactly one open question.
  cp "$root/tasks/_TEMPLATE.md" "$f"; edit 's/^state: proposed$/state: in-review/'
  awk '/^## Open questions$/ { s = 1; print; next } s && /^<!--/ { next } s && /^-->$/ { s = 0; next } { print }' "$f" > "$f.x" && mv "$f.x" "$f"
  ol=$(grep -n '^- \[ \] Q1' "$f" | cut -d: -f1)
  expect "the template's example lines give exactly one open question" 1 \
    "SPEC_EMPTY_SECTION Users and stakeholders" "SPEC_EMPTY_SECTION Non-functional requirements" \
    "SPEC_EMPTY_SECTION Assumptions" "SPEC_OPEN_QUESTION line $ol" "SPEC_EMPTY_SECTION Out of scope" \
    "SPEC_PLACEHOLDER_AC line $tl"
  # ...and so do the README's.
  # shellcheck disable=SC2016  # markdown fences, not expansions
  sed -n '/^## Definition of ready$/,/^## /p' "$root/tasks/README.md" | sed -n '/^```text$/,/^```$/p' | grep '^- \[' > "$tmp/ex" || :
  ready in-review; cat "$tmp/ex" >> "$f"
  nx=$(grep -c '' "$tmp/ex")
  ex_open=$(grep -n '^- \[ \]' "$f" | sed -n '2p' | cut -d: -f1)
  if [ "$nx" -ge 3 ]; then expect "the README's example lines ($nx) give exactly one open question" 1 "SPEC_OPEN_QUESTION line $ex_open"
  else bad "the README's Definition of ready has at least 3 example lines in a text fence (found $nx)"; fi

  ready in-review; pass0 "a ready fixture passes in review"
  for s in proposed in-progress completed blocked cancelled; do ready "$s"; pass0 "a ready fixture passes in $s"; done

  # Criterion 2: the frontmatter fails closed.
  ready in-review; printf '\357\273\277' > "$f.x"; cat "$f" >> "$f.x"; mv "$f.x" "$f"
  expect "a BOM fails" 1 "SPEC_FRONTMATTER line 1"
  ready in-review; edit 's/$/\r/'
  expect "CRLF fails at line 1" 1 "SPEC_FRONTMATTER line 1"
  ready in-review; edit '1d'
  expect "no opening --- fails" 1 "SPEC_FRONTMATTER line 1"
  ready in-review; edit '5d'
  expect "an unclosed frontmatter fails" 1 "SPEC_FRONTMATTER line 1"
  ready in-review; edit 's/^state: in-review$/State: In-Review/'
  expect "State: In-Review fails" 1 "SPEC_FRONTMATTER line 3"
  ready in-review; edit 's/^state: in-review$/state: inreview/'
  expect "state: inreview fails" 1 "SPEC_FRONTMATTER line 3"
  ready in-review; edit 's/^state: in-review$/state: in-review\nstate: proposed/'
  expect "two state: lines fail" 1 "SPEC_FRONTMATTER line 4"
  ready in-review; edit '3d'
  expect "no state: line fails" 1 "SPEC_FRONTMATTER line 4"
  ready in-review; edit 's/^spec_format: 1$/spec_format: 1\nspec_format: 1/'
  expect "two spec_format: lines fail" 1 "SPEC_FRONTMATTER line 5"
  ready in-review; edit 's/^state: in-review$/state: in-review  # comment/'
  pass0 "state: in-review  # comment passes"
  ready in-review; edit 's/^state: in-review$/  STATE: in-review/'
  pass0 "an indented, upper-case state key passes"
  ready in-review; i=19; while [ "$i" -le 40 ]; do add 'filler'; i=$((i + 1)); done; edit '40s/$/\r/'
  expect "a CR on body line 40 only fails there" 1 "SPEC_FRONTMATTER line 40"
  ready in-review; add '- [ ] q'; edit 's/$/\r/'
  expect "CRLF plus an open question reports both" 1 "SPEC_FRONTMATTER line 1" "SPEC_OPEN_QUESTION line 19"
  : > "$f"; expect "an empty file fails" 1 "SPEC_FRONTMATTER line 1"
  ready in-review; edit '3d'; add '- [ ] q'
  expect "with no state, no state rule runs" 1 "SPEC_FRONTMATTER line 4"

  # Criterion 3: open questions.
  for b in '-' '*' '+' '1.' '2)'; do
    ready in-review; add "$b [ ] q"; expect "an open '$b' item fails" 1 "SPEC_OPEN_QUESTION line 19"
  done
  ready in-review; add '- [X] q — Answer (2026-11-11, owner, in session): yes'; pass0 "[X] with an answer passes"
  for b in '[]' '[-]' '[ x]' '[x ]' '[y]'; do
    ready in-review; add "- $b q"; expect "an invalid box $b fails" 1 "SPEC_OPEN_QUESTION line 19"
  done
  ready in-review; add '<!-- c --> - [ ] q'; expect "an item after an inline comment counts" 1 "SPEC_OPEN_QUESTION line 19"
  ready in-review; add '- [x] q — Answer (2026-11-11, owner, in session): yes, and' '  it goes on here'
  pass0 "an answer that wraps onto an indented line passes"
  ready in-review; add '- [x] q' '  Answer (2026-11-11, owner, in session): yes'
  expect "an Answer header only on the next line fails" 1 "SPEC_UNANSWERED line 19"
  ready in-review; add '- [x] q — Answer (2026-11-11, owner): yes'; expect "an answer with no source fails" 1 "SPEC_UNANSWERED line 19"
  ready in-review; add '- [x] q — Answer (2026-11-11, owner, https://github.com/o/r/pull/1#issuecomment-2): yes'
  pass0 "an answer with a URL source passes"
  ready in-review; add '- [x] q — Answer (2026-11-11, Jane, PM, in session): yes'; pass0 "a <who> with a comma passes"
  ready in-review; add '- [x] q — Answer (2026-11-11, in session, Jane): x'
  expect "the source before the name fails" 1 "SPEC_UNANSWERED line 19"
  ready in-review; add '- [x] q — Answer (2026-11-11, owner, in session): '; expect "an empty answer fails" 1 "SPEC_UNANSWERED line 19"
  ready in-review; add '- [x] q — Answer (2026-1-11, owner, in session): yes'; expect "a 2026-1-11 date fails" 1 "SPEC_UNANSWERED line 19"
  ready in-review; add '- [x] q — Answer (2026-11-11, Jane (PM), in session): yes'; expect "parentheses in <who> fail" 1 "SPEC_UNANSWERED line 19"
  ready in-review; add '- [x] q — Answer (2026-11-11, , in session): yes'; expect "an empty <who> fails" 1 "SPEC_UNANSWERED line 19"
  ready in-review; add '- [x] q — Answer (2026-11-11, owner, ftp://x): yes'; expect "a non-http source fails" 1 "SPEC_UNANSWERED line 19"
  ready in-review; add '- [x] q'; expect "a checked item with neither fails" 1 "SPEC_UNANSWERED line 19"
  ready in-review; add '- [x] q — Deferred to T-: x'; expect "Deferred to T-: x fails" 1 "SPEC_UNANSWERED line 19"
  ready in-review; add '- [x] q — Deferred to T-24.1.2: why'; pass0 "Deferred to T-24.1.2: why passes"
  ready in-review; add '- [x] q — Deferred to T-24: '; expect "a deferral with no reason fails" 1 "SPEC_UNANSWERED line 19"
  ready in-review; add '- [x] q — Deferred to T-24:  two spaces'; pass0 "a deferral with two spaces passes, like an answer"
  ready in-review; add '- [x] q — Answer (2026-11-11, Jane, in session): 是'; pass0 "a non-ASCII answer passes"
  ready in-review; add '- [x] q — Answer (2026-11-11, Jane, in session): !!'; expect "an answer of only ASCII punctuation fails" 1 "SPEC_UNANSWERED line 19"
  ready in-review; add '<!-- - [ ] q -->'; pass0 "an item inside a one-line comment is ignored"
  ready in-review; add '<!--' '- [ ] q' '-->'; pass0 "an item inside a multi-line comment is ignored"
  ready in-review; add '```' '- [ ] q' '```'; pass0 "an item inside a backtick fence is ignored"
  ready in-review; add '~~~~' '- [ ] q' '~~~~~'; pass0 "an item inside a longer tilde fence is ignored"
  ready in-review; add '> - [ ] q'; pass0 "an item inside a blockquote is ignored"
  ready in-review; add '````' '```' '- [ ] q'; expect "a ```` fence is not closed by \`\`\`" 1 "SPEC_UNCLOSED line 19"
  ready in-review; add '```' '~~~' '- [ ] q'; expect "a \`\`\` fence is not closed by ~~~" 1 "SPEC_UNCLOSED line 19"
  ready in-review; add '### Details' '- [ ] q'; expect "a level-3 heading doesn't end Open questions" 1 "SPEC_OPEN_QUESTION line 20"
  ready in-review; add '## Notes' '- [ ] q'; pass0 "a level-2 heading ends Open questions"
  ready in-review; add '## Notes' '## Open questions' '- [ ] q'
  expect "a second Open questions section is checked too" 1 "SPEC_OPEN_QUESTION line 21" "SPEC_DUPLICATE_SECTION line 20"
  ready completed; add '- [ ] q'; expect "an open question in completed fails" 1 "SPEC_OPEN_QUESTION line 19"
  ready in-progress; add '- [ ] q'; expect "an open question added while in-progress fails" 1 "SPEC_OPEN_QUESTION line 19"
  if printf '%s\n' "$last_out" | grep -q '^    Fix: .*set state: blocked'; then ok "[$cur_sh/$cur_awk] ...and its Fix line points at blocked"
  else bad "[$cur_sh/$cur_awk] ...and its Fix line points at blocked"; fi
  for s in blocked cancelled proposed; do ready "$s"; add '- [ ] q'; pass0 "an open question in $s passes"; done
  ready in-review "id2: x"; add '- [ ] q'; expect "a legacy file in review still fails an open question" 1 "SPEC_OPEN_QUESTION line 19"
  ready in-review; add '- q without a box' '1. also none' '-[ ] no space'; pass0 "lines without a box are not items"

  # Criterion 4: the required sections.
  for s in 'Users and stakeholders' 'Acceptance criteria' 'Non-functional requirements' 'Assumptions' 'Out of scope' 'Open questions'; do
    ready in-review; awk -v h="## $s" '$0 == h { skip = 1; next } skip && /^## / { skip = 0 } !skip' "$f" > "$f.x" && mv "$f.x" "$f"
    expect "a missing $s fails" 1 "SPEC_MISSING_SECTION $s"
  done
  ready in-review; add '## Assumptions' 'More.'
  expect "a duplicate section fails" 1 "SPEC_DUPLICATE_SECTION line 19"
  ready proposed 'spec_format: 2'; expect "spec_format: 2 fails even when proposed" 1 "SPEC_VERSION_UNKNOWN line 4"
  ready in-review 'spec_format: 2'; expect "spec_format: 2 in review fails only on the version" 1 "SPEC_VERSION_UNKNOWN line 4"
  ready in-review 'spec_format:'; expect "an empty spec_format fails" 1 "SPEC_VERSION_UNKNOWN line 4"
  ready in-review 'spec_format: 1 # v1'; pass0 "spec_format: 1 with a comment passes"
  ready in-review; edit 's/^None\.$/…/'
  expect "sections holding only … are empty" 1 "SPEC_EMPTY_SECTION Assumptions" "SPEC_EMPTY_SECTION Open questions" "SPEC_EMPTY_SECTION Out of scope"
  ready in-review; edit 's/^None\.$/- …/'
  expect "sections holding only - … are empty" 1 "SPEC_EMPTY_SECTION Assumptions" "SPEC_EMPTY_SECTION Open questions" "SPEC_EMPTY_SECTION Out of scope"
  ready in-review; edit 's/^None\.$/n\/a/'; pass0 "a bare n/a is content"
  ready in-review; edit '18d'; add '```' 'text' '```'; expect "a section holding only a fence is empty" 1 "SPEC_EMPTY_SECTION Open questions"
  ready in-review; edit '18d'; add '<!-- a note -->'; expect "a section holding only a comment is empty" 1 "SPEC_EMPTY_SECTION Open questions"
  ready in-review; edit '18d'; add '' '   '; expect "a section holding only blank lines is empty" 1 "SPEC_EMPTY_SECTION Open questions"
  ready in-review; edit 's/^- \[ \] it works$/It works, in prose./'; expect "criteria in prose with no checkbox fail" 1 "SPEC_PLACEHOLDER_AC Acceptance criteria"
  ready in-review; edit 's/^- \[ \] it works$/- [ ] <given> a <when> b <then> c/'; expect "a <given> criterion fails" 1 "SPEC_PLACEHOLDER_AC line 10"
  ready in-review; edit 's/^- \[ \] it works$/- [x] it works/'; pass0 "a checked criterion passes"
  ready proposed; edit '/^## Assumptions$/d'; pass0 "a proposed task needs no sections"
  ready blocked; edit '/^## Assumptions$/d'; pass0 "a blocked task needs no sections"
  for h in '## Open Questions' '### Open questions' '## Open questions ##' '## Open questions (two)' '## Open questions:' '   ## Open questions' '##  Open   questions'; do
    ready in-review; edit "s/^## Open questions\$/$h/"
    expect "the loose heading '$h' fails with SPEC_HEADING" 1 "SPEC_HEADING line 17"
  done
  ready in-review; edit 's/^## Open questions$/    ## Open questions/'
  expect "4 leading spaces is not a heading" 1 "SPEC_MISSING_SECTION Open questions"
  ready in-review; edit 's/^## Out of scope$/## Out of scope (follow-ups)/'
  expect "## Out of scope (follow-ups) fails in a marked file" 1 "SPEC_HEADING line 15"
  ready in-review 'id2: x'; edit 's/^## Out of scope$/## Out of scope (x)/'; pass0 "a legacy file with ## Out of scope (x) passes"
  ready in-review 'id2: x'; edit 's/^## Open questions$/## Open Questions/'
  expect "a legacy file with ## Open Questions fails" 1 "SPEC_HEADING line 17"
  ready in-review 'id2: x'; edit '/^## Assumptions$/d'; pass0 "a legacy file needs no sections"
  ready in-review; add '```' '## Assumptions' '```'; pass0 "a fenced heading never starts a section"

  # Criterion 5: unclosed regions.
  ready in-review; add '<!-- never closed' '- [ ] q'; expect "an unclosed comment fails at its opening line" 1 "SPEC_UNCLOSED line 19"
  ready proposed; add '```'; expect "an unclosed fence fails in any state" 1 "SPEC_UNCLOSED line 19"
  ready proposed 'id2: x'; add '<!--'; expect "an unclosed comment fails in a legacy file" 1 "SPEC_UNCLOSED line 19"

  # Criteria 6 and 7: the marker and the name, mode and path rules.
  ready proposed 'id2: x'; TR_REQ=1 expect "a required marker that's missing fails" 1 "SPEC_MARKER_MISSING"
  ready proposed; TR_REQ=1 pass0 "a required marker that's present passes"
  ready proposed 'id2: x'; TR_BASE=1 expect "a removed marker fails" 1 "SPEC_MARKER_REMOVED"
  ready proposed 'id2: x'; TR_BASE=0 pass0 "a legacy file that stays legacy passes"
  ready proposed; TR_BASE=1 pass0 "a kept marker passes"
  ready in-review; TR_MODE=120000 expect "a symlink is not a file" 1 "SPEC_NOT_A_FILE"
  ready in-review; TR_MODE=160000 expect "a gitlink is not a file" 1 "SPEC_NOT_A_FILE"
  ready in-review; TR_MODE=many expect "a multi-entry index line is not a file" 1 "SPEC_NOT_A_FILE"
  ready in-review; TR_MODE=100755 pass0 "an executable file passes"
  for p in 'tasks/T-924a.md' 'Tasks/T-1.md' 'tasks/t-1.md' '"tasks/T-1\tx.md"' 'tasks/T-1/notes.md' 'tasks/T-1.MD' \
           'tasks/T-.md' 'tasks/T-1..2.md' 'tasks/T-1.2..md' '.starter/tasks/T-1.md.bak' '.Starter/tasks/T-1.md' 'tasks/T-912-notes.md'; do
    ready in-review; TR_PATH=$p expect "the bad name $p fails" 1 "SPEC_BAD_NAME"
  done
  for p in 'tasks/T-1.md' 'tasks/T-1.2.3.md' '.starter/tasks/T-923.md' 'tasks/T-0001.md'; do
    ready in-review; TR_PATH=$p pass0 "the task name $p passes"
  done
  ready in-review; TR_PATH='tasks/T-##vso[x].md' expect "a bad name with ##vso[ fails" 1 "SPEC_BAD_NAME"
  case "$last_out" in
    *'##vso['*) bad "[$cur_sh/$cur_awk] ...and is printed sanitized" ;;
    *'tasks/T-??vso?x?.md'*) ok "[$cur_sh/$cur_awk] ...and is printed sanitized" ;;
    *) bad "[$cur_sh/$cur_awk] ...and is printed sanitized (no sanitized name)" ;;
  esac
}

# --- Name and marker helpers (once) ---------------------------------------------------
# shellcheck disable=SC2016  # the $1 etc. are the child shell's
name_rc() { sh -c '. "$1"; tr_name "$2"' sh "$lib" "$1"; echo $?; }
for p in tasks/T-1.md .starter/tasks/T-9.2.md; do
  if [ "$(name_rc "$p")" = 0 ]; then ok "tr_name: $p is a task file"; else bad "tr_name: $p is a task file"; fi
done
for p in tasks .starter .starter/tasks Tasks .STARTER/TASKS; do
  if [ "$(name_rc "$p")" = 1 ]; then ok "tr_name: a changed ledger folder entry ($p) is a bad name"; else bad "tr_name: a changed ledger folder entry ($p) is a bad name"; fi
done
for p in tasks/INDEX.md tasks/_TEMPLATE.md tasks/README.md x/tasks/T-1.md docs/T-1.md .starter/README.md; do
  if [ "$(name_rc "$p")" = 3 ]; then ok "tr_name: $p is not a task file"; else bad "tr_name: $p is not a task file"; fi
done
if [ "$(name_rc 'tasks/T-1a.md')" = 1 ]; then ok "tr_name: tasks/T-1a.md is a bad name"; else bad "tr_name: tasks/T-1a.md is a bad name"; fi
# shellcheck disable=SC2016
need() { sh -c '. "$1"; tr_need "$2" "$3" "$4"' sh "$lib" "$@"; }
for c in 'A tasks/T-1.md 0 1' 'A tasks/T-1.md 1 0' 'A .starter/tasks/T-1.md 0 0' 'M tasks/T-1.md 0 0' 'T tasks/T-1.md 0 0'; do
  # shellcheck disable=SC2086  # split the case into its four words
  set -- $c
  if [ "$(need "$1" "$2" "$3")" = "$4" ]; then ok "tr_need $1 $2 root=$3 is $4"; else bad "tr_need $1 $2 root=$3 is $4"; fi
done
# shellcheck disable=SC2016
mark_rc() { sh -c '. "$1"; tr_marker' sh "$lib" < "$f"; echo $?; }
if ready proposed; [ "$(mark_rc)" = 0 ]; then ok "tr_marker: a marked file returns 0"; else bad "tr_marker: a marked file returns 0"; fi
if ready proposed 'id2: x'; [ "$(mark_rc)" = 1 ]; then ok "tr_marker: a legacy file returns 1"; else bad "tr_marker: a legacy file returns 1"; fi
if ready proposed; edit '1d'; [ "$(mark_rc)" = 1 ]; then ok "tr_marker: no frontmatter means no marker"; else bad "tr_marker: no frontmatter means no marker"; fi

for cur_sh in $shells; do
  for cur_awk in $awks; do
    # busybox sh runs its own awk applet, never the one on PATH, so under it the cases
    # run once, against busybox awk, and no shim can be proven to have run.
    if [ "$cur_sh" = busybox-sh ]; then
      [ "$cur_awk" = "${awks##* }" ] || continue
      echo "-- shell: $cur_sh, awk: busybox's own applet (it ignores PATH)"
      cases; continue
    fi
    echo "-- shell: $cur_sh, awk: $cur_awk"
    rm -f "$tmp/awk-$cur_awk/hit"
    cases
    if [ -e "$tmp/awk-$cur_awk/hit" ]; then ok "[$cur_sh/$cur_awk] the $cur_awk shim was the awk that ran"; else bad "[$cur_sh/$cur_awk] the $cur_awk shim was the awk that ran"; fi
  done
done
cur_sh=sh cur_awk=awk

# --- Criterion 8: output -----------------------------------------------------------------
# Every code has a reason and a Fix line; the list comes from the block's own source.
codes=$(sed -n "s/^tr_codes='\\(.*\\)'\$/\\1/p" "$tmp/block.sh")
src_codes=$(grep -oE 'SPEC_[A-Z_]*[A-Z]' "$tmp/block.sh" | sort -u | tr '\n' ' ')
for c in $src_codes; do
  case " $codes " in *" $c "*) ;; *) bad "the code $c in the block is listed in tr_codes" ;; esac
done
nc=0
for c in $codes; do
  nc=$((nc + 1))
  # shellcheck disable=SC2016
  w=$(sh -c '. "$1"; tr_why "$2" "Assumptions"' sh "$lib" "$c") || w=''
  l1=$(printf '%s\n' "$w" | sed -n '1p'); l2=$(printf '%s\n' "$w" | sed -n '2p')
  if [ -n "$l1" ] && [ "${l2#Fix: }" != "$l2" ] && [ "$(printf '%s\n' "$w" | grep -c '')" -eq 2 ]; then ok "$c has a reason and a Fix line"
  else bad "$c has a reason and a Fix line"; fi
done
if [ "$nc" -eq 14 ]; then ok "tr_codes lists 14 codes"; else bad "tr_codes lists 14 codes (got $nc)"; fi
ready in-review; add '- [ ] q' '- [x] r'
out=$(PATH="$tmp/awk-awk:$PATH" TR_LIB="$lib" sh "$tmp/drive.sh" tasks/T-1.md 0 - 100644 < "$f")
first=$(printf '%s\n' "$out" | sed -n '1p'); lastl=$(printf '%s\n' "$out" | sed -n '$p')
if [ "$first" = "Task tasks/T-1.md is not ready (2 problems):" ]; then ok "the summary line comes first"; else bad "the summary line comes first (got: $first)"; fi
if [ "$lastl" = "See tasks/README.md#definition-of-ready" ]; then ok "the README link comes last"; else bad "the README link comes last (got: $lastl)"; fi
nfix=$(printf '%s\n' "$out" | grep -c '^    Fix: ')
ready in-review; add '- [ ] q' '- [ ] r'
o2=$(PATH="$tmp/awk-awk:$PATH" TR_LIB="$lib" sh "$tmp/drive.sh" tasks/T-1.md 0 - 100644 < "$f")
if [ "$(printf '%s\n' "$o2" | grep -c '^    Fix: same as above\.$')" -eq 1 ]; then ok "a repeated code's Fix says 'same as above'"; else bad "a repeated code's Fix says 'same as above'"; fi
if [ "$nfix" -eq 2 ]; then ok "each finding has an indented Fix line"; else bad "each finding has an indented Fix line ($nfix)"; fi
if printf '%s\n' "$out" | grep -q 'Jane, PM, not Jane (PM)'; then ok "SPEC_UNANSWERED names the common slips"; else bad "SPEC_UNANSWERED names the common slips"; fi
ready in-review; add '- [ ] q'
out=$(PATH="$tmp/awk-awk:$PATH" TR_LIB="$lib" sh "$tmp/drive.sh" tasks/T-1.md 0 - 100644 < "$f")
if [ "$(printf '%s\n' "$out" | sed -n '1p')" = "Task tasks/T-1.md is not ready (1 problem):" ]; then ok "one finding says 1 problem"; else bad "one finding says 1 problem"; fi

# A canary in every line of a fixture never reaches the output, whatever the code.
can='##vso[task.logissue type=warning]T023-canary ::notice::T023-canary'
canarize() {  # canarize: put the canary on every line of $f that can carry one unchanged
  awk -v c="$can" '
    NR == 1 || $0 == "---" { print; if ($0 == "---") fmn++; next }
    fmn == 1 { print $0 " # " c; next }
    /^#/ || /^[ \t]*(```|~~~)/ || index($0, "<!--") || index($0, "-->") { print; next }
    { print $0 " <!-- " c " -->" }' "$f" > "$f.x" && mv "$f.x" "$f"
  printf '<!-- %s -->\n' "$can" >> "$f"
}
canary() {  # canary <description> <setup...>: the findings are the same, and no canary
  d=$1; shift
  "$@"
  o1=$(PATH="$tmp/awk-awk:$PATH" TR_LIB="$lib" sh "$tmp/drive.sh" "${TR_PATH:-tasks/T-1.md}" "${TR_REQ:-0}" "${TR_BASE:--}" "${TR_MODE:-100644}" < "$f")
  canarize
  o2=$(PATH="$tmp/awk-awk:$PATH" TR_LIB="$lib" sh "$tmp/drive.sh" "${TR_PATH:-tasks/T-1.md}" "${TR_REQ:-0}" "${TR_BASE:--}" "${TR_MODE:-100644}" < "$f")
  case "$o2" in
    *T023-canary*|*'##vso['*|*'::notice::'*) bad "canary: $d never echoes content" ;;
    *) if [ -n "$o2" ] && [ "$(findings "$o1")" = "$(findings "$o2")" ]; then ok "canary: $d never echoes content"
       else bad "canary: $d never echoes content (findings changed)"; fi ;;
  esac
}
c_open() { ready in-review; add '- [ ] q' '- [x] r' '- [-] s'; }
c_fm() { ready in-review; edit 's/^state: in-review$/state: bogus/'; }
c_sec() { ready in-review; edit '/^## Assumptions$/,/^None\.$/d'; add '## Users and stakeholders' 'x' '## Open Questions'; edit 's/^- \[ \] it works$/- [ ] <given> x/'; }
c_empty() { ready in-review; edit 's/^None\.$/…/'; edit 's/^- \[ \] it works$/prose/'; }
c_ver() { ready proposed 'spec_format: 9'; }
c_unc() { ready proposed; add '```'; }
c_mark() { ready proposed 'id2: x'; }
canary "open, invalid and unanswered questions" c_open
canary "a bad state" c_fm
canary "missing, duplicate and near-miss sections and a placeholder criterion" c_sec
canary "empty sections and prose criteria" c_empty
canary "an unknown version" c_ver
canary "an unclosed fence" c_unc
TR_REQ=1 canary "a missing marker" c_mark
TR_BASE=1 canary "a removed marker" c_mark
TR_MODE=120000 canary "a symlink" c_mark
TR_PATH='tasks/T-1x.md' canary "a bad name" c_mark
# Every code was reached by some case above.
all=$(for s in c_open c_fm c_sec c_empty c_ver c_unc; do "$s"; PATH="$tmp/awk-awk:$PATH" TR_LIB="$lib" sh "$tmp/drive.sh" tasks/T-1.md 0 - 100644 < "$f"; done)
for c in SPEC_OPEN_QUESTION SPEC_UNANSWERED SPEC_FRONTMATTER SPEC_MISSING_SECTION SPEC_DUPLICATE_SECTION SPEC_HEADING SPEC_PLACEHOLDER_AC SPEC_EMPTY_SECTION SPEC_VERSION_UNKNOWN SPEC_UNCLOSED; do
  if printf '%s\n' "$all" | grep -q "^  $c "; then ok "the canary fixtures reach $c"; else bad "the canary fixtures reach $c"; fi
done

# --- Criterion 9: internal errors return 2 ------------------------------------------------
# bad_awk <name> <script body>: an awk shim; "$real" runs the real awk.
bad_awk() {
  d="$tmp/bad-$1"; mkdir -p "$d"
  { printf '#!/bin/sh\nreal=%s\n' "$sys_awk"; printf '%s\n' "$2"; } > "$d/awk"; chmod +x "$d/awk"
}
# shellcheck disable=SC2016  # the shims' own text
bad_awk exit2 'cat >/dev/null; exit 2'
# shellcheck disable=SC2016
bad_awk exit1 '"$real" "$@"; exit 1'
# shellcheck disable=SC2016
bad_awk unknown '"$real" "$@"; printf "SPEC_BOGUS\t1\t0\n"'
# shellcheck disable=SC2016
bad_awk nomarker '"$real" "$@" | grep -v "^MARKER"'
# shellcheck disable=SC2016
bad_awk twomarkers '"$real" "$@" | sed "p"'
# shellcheck disable=SC2016
bad_awk lateline '"$real" "$@"; printf "SPEC_OPEN_QUESTION\t3\t0\n"'
# shellcheck disable=SC2016
bad_awk badline '"$real" "$@" | sed "s/^MARKER/SPEC_UNCLOSED\tx\t0\nMARKER/"'
# shellcheck disable=SC2016
bad_awk callercode '"$real" "$@" | sed "s/^MARKER/SPEC_BAD_NAME\t0\t0\nMARKER/"'
for s in exit2 exit1 unknown nomarker twomarkers lateline badline callercode; do
  ready in-review; add '- [ ] q'
  o=$(PATH="$tmp/bad-$s:$PATH" TR_LIB="$lib" sh "$tmp/drive.sh" tasks/T-1.md 0 - 100644 < "$f"); r=$?
  if [ "$r" -eq 2 ]; then ok "an awk that misbehaves ($s) is an internal error (2)"; else bad "an awk that misbehaves ($s) is an internal error (got $r: $o)"; fi
  # shellcheck disable=SC2016
  o=$(PATH="$tmp/bad-$s:$PATH" sh -c '. "$1"; tr_marker' sh "$lib" < "$f"); r=$?
  if [ "$r" -eq 2 ]; then ok "...and tr_marker returns 2 ($s)"; else bad "...and tr_marker returns 2 ($s, got $r)"; fi
done
# The caller's se_safe failing is an internal error too.
# shellcheck disable=SC2016
o=$(PATH="$tmp/bad-exit2:$PATH" sh -c '. "$1"; se_safe() { return 1; }; tr_check tasks/T-1.md 0 - 100644' sh "$lib" < "$f"); r=$?
if [ "$r" -eq 2 ]; then ok "a se_safe failure is an internal error (2)"; else bad "a se_safe failure is an internal error (got $r)"; fi

# --- Criterion 9: static greps on the block ----------------------------------------------
# static_scan <block file>: one "BANNED <what>" line per construct found. Comment lines
# are skipped. (IFS= and LC_ALL= appear only as one command's prefix assignments.)
static_scan() {
  sc_code=$(grep -v '^[ \t]*#' "$1")
  printf '%s\n' "$sc_code" | grep -qE '(^|[;&|({ ]|then |else |do )(die|err|fail)( |$|;)' && echo "BANNED die/err/fail"
  printf '%s\n' "$sc_code" | grep -qE '(^|[ \t])-v([ \t]|[A-Za-z_]|$)' && echo "BANNED -v"
  sc_nf=$(printf '%s\n' "$sc_code" | grep -cE '^[A-Za-z_][A-Za-z0-9_]*\(\)')
  sc_nt=$(printf '%s\n' "$sc_code" | grep -cE '^tr_[A-Za-z0-9_]*\(\) \{')
  { [ "$sc_nf" -eq "$sc_nt" ] && [ "$sc_nt" -ge 4 ]; } || echo "BANNED a function without the tr_ prefix"
  sc_nv=$(printf '%s\n' "$sc_code" | grep -oE '(^|[ ;(])[A-Za-z_][A-Za-z0-9_]*=' | sed 's/^[ ;(]//' | grep -vcE '^(tr_|IFS=$|LC_ALL=$)')
  [ "$sc_nv" -eq 0 ] || echo "BANNED a variable without the tr_ prefix"
  printf '%s\n' "$sc_code" | grep -qF '[[:' && echo "BANNED [[:"
  printf '%s\n' "$sc_code" | grep -qF '\s' && echo "BANNED backslash-s"
  printf '%s\n' "$sc_code" | grep -qF 'IGNORECASE' && echo "BANNED IGNORECASE"
  printf '%s\n' "$sc_code" | grep -qF 'gensub' && echo "BANNED gensub"
  printf '%s\n' "$sc_code" | grep -qE '\{[0-9]' && echo "BANNED {n,m}"
  # length(<name>) where <name> is subscripted anywhere: length of an array.
  printf '%s\n' "$sc_code" | awk '
    { line[NR] = $0; s = $0
      while (match(s, /[A-Za-z_][A-Za-z0-9_]*[[]/)) { arr[substr(s, RSTART, RLENGTH - 1)] = 1; s = substr(s, RSTART + RLENGTH) } }
    END { for (i = 1; i <= NR; i++) { s = line[i]
        while (match(s, /length[(][A-Za-z_][A-Za-z0-9_]*[)]/)) { n = substr(s, RSTART + 7, RLENGTH - 8); if (n in arr) f = 1; s = substr(s, RSTART + RLENGTH) } }
      if (f) print "BANNED length(array)" }'
  return 0
}
sc=$(static_scan "$tmp/block.sh")
if [ -z "$sc" ]; then ok "the static greps find nothing banned in the block"; else bad "the static greps find nothing banned in the block: $sc"; fi
if grep -q "^  LC_ALL=C awk '\$" "$tmp/block.sh"; then ok "the awk program was found in the block"; else bad "the awk program was found in the block"; fi
# Each construct planted in a copy of the real block must be caught, by name.
plant() {  # plant <what> <line>: append <line> to a copy of the block; expect "BANNED <what>"
  cp "$tmp/block.sh" "$tmp/planted.sh"; printf '%s\n' "$2" >> "$tmp/planted.sh"
  if static_scan "$tmp/planted.sh" | grep -qxF "BANNED $1"; then ok "the static greps catch a planted $1: $2"
  else bad "the static greps catch a planted $1: $2"; fi
}
plant 'die/err/fail' '  die "x"'
plant 'die/err/fail' '  x || err y'
plant 'die/err/fail' '  then fail z'
plant '-v' '  awk -v p=1'
plant '-v' '  awk -vx=1'
plant 'a function without the tr_ prefix' 'helper() { :; }'
plant 'a variable without the tr_ prefix' '  out=1'
plant '[[:' '    /[[:space:]]/ { x = 1 }'
plant 'backslash-s' '    /\s+/ { x = 1 }'
plant 'IGNORECASE' '    BEGIN { IGNORECASE = 1 }'
plant 'gensub' '    { x = gensub(/a/, "b", "g") }'
plant '{n,m}' '    /x{2}/ { y = 1 }'
# shellcheck disable=SC2016  # awk text
plant 'length(array)' '    { seen[$0] = 1; n = length(seen) }'

# --- Criterion 10: isolation, a bare environment, a UTF-8 locale -----------------------
ready in-review; add '- [ ] q'
# shellcheck disable=SC2016
iso=$(sh -c '
  . "$1"
  IFS=":" f=keep p=keep rc=7 out=keep; set -f
  tr_rc=0; tr_o=$(tr_check tasks/T-1.md 0 - 100644 < "$2") || tr_rc=$?
  tr_name tasks/T-1.md || :; tr_need A tasks/T-1.md 0 >/dev/null; tr_marker < "$2" || :
  case $- in *f*) sf=on ;; *) sf=off ;; esac
  printf "%s|%s|%s|%s|%s|%s|%s" "$IFS" "$f" "$p" "$rc" "$out" "$sf" "$tr_rc"' sh "$lib" "$f")
if [ "$iso" = ':|keep|keep|7|keep|on|1' ]; then ok "the block leaves IFS, f, p, rc, out and set -f alone"; else bad "the block leaves IFS, f, p, rc, out and set -f alone (got: $iso)"; fi
o=$(env -i PATH="$tmp/awk-awk:/usr/bin:/bin" TR_LIB="$lib" sh "$tmp/drive.sh" tasks/T-1.md 0 - 100644 < "$f"); r=$?
if [ "$r" -eq 1 ] && [ "$(findings "$o")" = "SPEC_OPEN_QUESTION line 19" ]; then ok "the block runs under env -i"; else bad "the block runs under env -i (rc=$r)"; fi
utf=$(locale -a 2>/dev/null | grep -iE '^(C|en_US)\.utf-?8$' | head -n 1)
if [ -n "$utf" ]; then
  ready in-review; edit 's/^None\.$/…/'; add '- [ ] café'
  o=$(LC_ALL=$utf PATH="$tmp/awk-awk:$PATH" TR_LIB="$lib" sh "$tmp/drive.sh" tasks/T-1.md 0 - 100644 < "$f"); r=$?
  if [ "$r" -eq 1 ] && [ "$(findings "$o")" = "$(printf 'SPEC_OPEN_QUESTION line 19\nSPEC_EMPTY_SECTION Assumptions\nSPEC_EMPTY_SECTION Out of scope')" ]; then ok "the block gives the same findings under $utf"; else bad "the block gives the same findings under $utf (rc=$r)"; fi
else echo "  SKIP: no UTF-8 locale here"; fi

echo
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
