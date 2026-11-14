#!/usr/bin/env sh
# Fixture test for scripts/ci-checks.sh.
#
# Stack-neutral: POSIX sh + git only. Builds throwaway git repos in a temp dir,
# makes commits that should pass/fail each gate, and asserts ci-checks.sh exits
# accordingly. Deterministic (no network, no wall-clock, no random).
#
# Run:  sh scripts/test/test-ci-checks.sh
#       CI_CHECKS=<path> sh scripts/test/test-ci-checks.sh   (test another copy)
#       SH=dash sh scripts/test/test-ci-checks.sh            (run it under dash)
# Exit: 0 all pass, 1 any failure.

set -u

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
playbook_src=$(CDPATH='' cd -- "$test_dir/../.." && pwd)
sut="${CI_CHECKS:-$playbook_src/scripts/ci-checks.sh}"
case "$sut" in /*) ;; *) sut="$PWD/$sut" ;; esac
SH="${SH:-sh}"

# Stubs and scratch files live outside the fixture repos (make_repo runs git add -A).
tmp=$(mktemp -d 2>/dev/null || mktemp -d -t cc)
trap 'rm -rf "$tmp"' EXIT

# Ignore the runner's own git config, attributes and any inherited repo pointers.
mkdir -p "$tmp/home" "$tmp/xdg"
HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/xdg"
GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ATTR_NOSYSTEM=1
export HOME XDG_CONFIG_HOME GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM GIT_ATTR_NOSYSTEM
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE GIT_EXTERNAL_DIFF

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
    && "$SH" scripts/ci-checks.sh "$base" "$head" >/dev/null 2>&1; echo $? )
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

# 8) Private-key block fails. Its pattern starts with '-' (which silently disabled
#    the pre-commit scan, starter T-012); assembled at runtime for the same reason as 4).
r=$(make_repo)
d=-----
( cd "$r" && printf '%sBEGIN RSA PRIVATE KEY%s\n' "$d" "$d" >> file.txt && git add -A && git commit -qm "chore: key T-108" )
err=$( cd "$r" \
  && base=$(git rev-list --max-parents=0 HEAD) && head=$(git rev-parse HEAD) \
  && "$SH" scripts/ci-checks.sh "$base" "$head" 2>&1 >/dev/null ); rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$err" | grep -qF "Possible secret detected"; then ok "private key block fails"
else bad "private key block fails (rc=$rc, stderr: $err)"; fi
rm -rf "$r"

# 9) Secret scan fails closed: a grep that errors (exit 2) on the secret pattern
#    must fail the check, not read as "no match".
r=$(make_repo)
real_grep=$(command -v grep)
mkdir -p "$r/.stub"
cat > "$r/.stub/grep" <<EOF
#!/bin/sh
for a in "\$@"; do case "\$a" in *PRIVATE*) echo "grep: stub error" >&2; exit 2 ;; esac; done
exec "$real_grep" "\$@"
EOF
chmod +x "$r/.stub/grep"
( cd "$r" && echo "clean line" >> file.txt && git add file.txt && git commit -qm "feat: clean T-109" )
err=$( cd "$r" \
  && base=$(git rev-list --max-parents=0 HEAD) && head=$(git rev-parse HEAD) \
  && PATH="$r/.stub:$PATH" "$SH" scripts/ci-checks.sh "$base" "$head" 2>&1 >/dev/null ); rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$err" | grep -qF "Secret scanner error"; then ok "grep error fails closed"
else bad "grep error fails closed (rc=$rc, stderr: $err)"; fi
rm -rf "$r"

# --- Fail closed on git errors (starter T-013) ----------------------------------------
# Each case asserts: exit 1, ci-checks' own message, and no "all gates passed".

# make_stub <cmd> <exit>: a dir holding a <cmd> that, on the $STUB_NTH-th (default
# 1st) call whose argument string matches the glob $STUB_FAIL, prints an error,
# touches $STUB_HIT and exits <exit>; every other call runs the real <cmd>. Put it
# on PATH only for the script under test.
make_stub() {
  real=$(command -v "$1")
  mkdir -p "$tmp/stub-$1"
  cat > "$tmp/stub-$1/$1" <<EOF
#!/bin/sh
# shellcheck disable=SC2254
case "\$*" in \$STUB_FAIL)
  n=\$(( \$(cat "\$STUB_HIT.n" 2>/dev/null || echo 0) + 1 )); echo "\$n" > "\$STUB_HIT.n"
  if [ "\$n" -eq "\${STUB_NTH:-1}" ]; then : > "\$STUB_HIT"; echo "stub: injected $1 failure" >&2; exit $2; fi ;;
esac
exec "$real" "\$@"
EOF
  chmod +x "$tmp/stub-$1/$1"
}
make_stub git 128
make_stub grep 2
make_stub sed 2
make_stub awk 2
make_stub cut 1
make_stub tr 1

# run_ci <root> <base> <head> [<stubbed-cmd> <glob> [<nth>]]: run ci-checks.sh;
# sets $rc and $out (stdout + stderr).
run_ci() {
  rm -f "$tmp/hit" "$tmp/hit.n"
  if [ $# -ge 5 ]; then
    out=$( cd "$1" && PATH="$tmp/stub-$4:$PATH" STUB_FAIL="$5" STUB_NTH="${6:-1}" STUB_HIT="$tmp/hit" \
      "$SH" scripts/ci-checks.sh "$2" "$3" 2>&1 ); rc=$?
  else
    out=$( cd "$1" && "$SH" scripts/ci-checks.sh "$2" "$3" 2>&1 ); rc=$?
  fi
}

# expect_closed <needle> <description> [stubbed]: exit 1 naming <needle>, no pass
# line, and (when a stub was used) proof the targeted call actually ran.
# A needle starting with two spaces is a location line and must match a whole line.
# Failing output is shown through od -c, so it can't drive the CI log (starter T-024).
has() { case "$1" in '  '*) printf '%s\n' "$out" | grep -qxF -- "$1" ;; *) printf '%s' "$out" | grep -qF -- "$1" ;; esac; }
expect_closed() {
  if [ "$rc" -eq 1 ] && has "$1" \
     && ! printf '%s' "$out" | grep -qF "all procedure gates passed" \
     && { [ $# -lt 3 ] || [ -e "$tmp/hit" ]; }
  then ok "$2"; else bad "$2 (rc=$rc)"; printf '%s' "$out" | od -c | sed -n '1,30p' >&2; fi
}

# A repo whose range touches file.txt and an authored docs file, so every git
# call in ci-checks.sh is reached. Sets $r, $b (base), $h (head).
range_repo() {
  r=$(make_repo)
  ( cd "$r" && mkdir -p docs && echo "x" >> file.txt && echo "d" > docs/x.md && git add -A \
     && git commit -qm "docs: change T-110

unanimous-consensus: T-110" )
  b=$(cd "$r" && git rev-list --max-parents=0 HEAD); h=$(cd "$r" && git rev-parse HEAD)
}

# 10) Control: the range used below passes, with empty stderr, when nothing fails.
range_repo
err=$( cd "$r" && "$SH" scripts/ci-checks.sh "$b" "$h" 2>&1 >/dev/null ); rc=$?
if [ "$rc" -eq 0 ] && [ -z "$err" ]; then ok "fail-closed fixture passes with empty stderr when git works"
else bad "fail-closed fixture passes with empty stderr when git works (rc=$rc, stderr: $err)"; fi

# 11) Base / head that don't resolve to a commit.
run_ci "$r" deadbeef "$h";  expect_closed "Base 'deadbeef' does not resolve" "unresolvable base fails closed"
run_ci "$r" "$b" deadbeef;  expect_closed "Head 'deadbeef' does not resolve" "unresolvable head fails closed"
z=0000000000000000000000000000000000000000
run_ci "$r" "$z" "$h";      expect_closed "does not resolve to a commit" "all-zeros base fails closed"
blob=$(cd "$r" && git hash-object -w file.txt)
run_ci "$r" "$blob" "$h";   expect_closed "does not resolve to a commit" "non-commit (blob) base fails closed"

# 12) A base that looks like an option is never passed to git as one.
run_ci "$r" "--output=$tmp/pwned" "$h"
expect_closed "does not resolve to a commit" "option-like base fails closed"
# git would take the whole range as the path (pwned...<sha>), so look for any pwned*.
leaked=$(find "$tmp" -maxdepth 1 -name 'pwned*')
if [ -z "$leaked" ]; then ok "option-like base is not run as a git option"; else bad "option-like base wrote $leaked"; fi

# 13) No merge base (unrelated histories).
( cd "$r" && cur=$(git symbolic-ref --short HEAD) && git checkout -q --orphan other && git rm -rqf . \
   && echo o > o.txt && git add o.txt && git commit -qm "orphan T-111" && git checkout -q "$cur" )
o=$(cd "$r" && git rev-parse other)
run_ci "$r" "$o" "$h";      expect_closed "No merge base" "unrelated histories fail closed"

# 14) Each git call that feeds a gate fails closed when git errors.
# The range's commit list is just $h, so each gate's git calls happen once, in
# order; the docs gate's `git log -1` is the 2nd one (the task-ID gate's is 1st).
run_ci "$r" "$b" "$h" git '*diff *-U0';                        expect_closed "git diff $b..$h failed" "full diff error fails closed" stub
run_ci "$r" "$b" "$h" git '*--name-only --diff-filter=*'; expect_closed "git diff --name-only $b..$h failed" "changed-file list error fails closed" stub
run_ci "$r" "$b" "$h" git '*diff *-U0 -- *';                   expect_closed "git diff $b..$h -- 'docs/x.md' failed" "per-file diff error fails closed" stub
run_ci "$r" "$b" "$h" git 'log --format=%H *';                expect_closed "git log $b..$h failed" "commit list error fails closed" stub
run_ci "$r" "$b" "$h" git 'log -1 *' 1;                       expect_closed "git log -1 $h failed" "task-ID gate message error fails closed" stub
run_ci "$r" "$b" "$h" git 'log -1 *' 2;                       expect_closed "git log -1 $h failed" "docs gate message error fails closed" stub
run_ci "$r" "$b" "$h" git '*--no-renames --name-only [!-]*';           expect_closed "git diff --name-only $b..$h failed" "docs file list error fails closed" stub
run_ci "$r" "$b" "$h" git '*show *';                           expect_closed "git show $h failed" "per-commit file list error fails closed" stub

# 15) Filters fail closed too: a broken sed can't empty the diff or a file list,
#     and a broken placeholder grep can't read as "no placeholder".
run_ci "$r" "$b" "$h" awk '*diff --git*';                   expect_closed "Parsing the diff of $b..$h failed" "diff parser error fails closed" stub
run_ci "$r" "$b" "$h" cut '-f2-';                             expect_closed "Filtering the diff of $b..$h failed" "diff filter error fails closed" stub
run_ci "$r" "$b" "$h" tr '-c*';                               expect_closed "Sanitizing a file name failed" "sanitizer (tr) error fails closed" stub
run_ci "$r" "$b" "$h" sed '-n /^"*' 1;                     expect_closed "Filtering the changed-file list failed" "docs file list filter error fails closed" stub
run_ci "$r" "$b" "$h" sed '-n /^"*' 2;                     expect_closed "Filtering the files of $h failed" "per-commit docs filter error fails closed" stub
run_ci "$r" "$b" "$h" grep '*insert*';                        expect_closed "Placeholder scanner error" "placeholder grep error fails closed" stub
rm -rf "$r"

# 16) A grep that errors on the old '^+' line filter can't hide a secret.
r=$(make_repo)
( cd "$r" && printf 'key=AKIA%s\n' "IOSFODNN7EXAMPLE" >> file.txt && git add -A && git commit -qm "chore: secret T-112" )
b=$(cd "$r" && git rev-list --max-parents=0 HEAD); h=$(cd "$r" && git rev-parse HEAD)
run_ci "$r" "$b" "$h" grep '^+'
expect_closed "Possible secret detected" "secret still caught when a line-filter grep would error"
rm -rf "$r"

# 17) Shallow clone that lacks the base fails closed instead of scanning nothing.
r=$(make_repo)
( cd "$r" && echo "x" >> file.txt && git add -A && git commit -qm "feat: x T-113" )
b=$(cd "$r" && git rev-list --max-parents=0 HEAD)
git clone -q --depth 1 "file://$r" "$tmp/shallow"
h=$(cd "$tmp/shallow" && git rev-parse HEAD)
run_ci "$tmp/shallow" "$b" "$h"; expect_closed "Shallow checkout" "shallow clone missing the base fails closed"
rm -rf "$r" "$tmp/shallow"

# 18) Root mode (base = empty-tree SHA, what ci-base.sh prints for a root commit):
#     the whole tree and every commit are checked, not an empty head...head range.
#     ci-checks.sh stays untracked here so its own text isn't part of the tree.
root_repo() {  # root_repo <file-content> <message>: one-commit repo; sets $r, $h
  r=$(mktemp -d 2>/dev/null || mktemp -d -t cc)
  mkdir -p "$r/scripts"; cp "$sut" "$r/scripts/ci-checks.sh"
  ( cd "$r" && git init -q && git config user.email t@t && git config user.name t \
      && git config commit.gpgsign false && printf '%s\n' "$1" > file.txt \
      && git add file.txt && git commit -qm "$2" )
  h=$(cd "$r" && git rev-parse HEAD)
}
et=$(git hash-object -t tree /dev/null)
root_repo "clean" "chore: init T-114"; run_ci "$r" "$et" "$h"
if [ "$rc" -eq 0 ]; then ok "root mode: clean root commit passes"; else bad "root mode: clean root commit passes (rc=$rc, out: $out)"; fi
rm -rf "$r"
root_repo "key=AKIA$(printf 'IOSFODNN7EXAMPLE')" "chore: init T-115"; run_ci "$r" "$et" "$h"
expect_closed "Possible secret detected" "root mode: secret in a root commit fails"
rm -rf "$r"
root_repo "clean" "chore: init, no id"; run_ci "$r" "$et" "$h"
expect_closed "missing a Task ID" "root mode: root commit without a Task ID fails"
rm -rf "$r"

# --- Trusted allowlist and content the diff can't hide (starter T-014) ----------------
ph=$(printf 'use [%s thing here]' insert)
aws="key=AKIA$(printf 'IOSFODNN7EXAMPLE')"

# commit_on <root> <message>: commit everything in <root>; set $b (root) and $h (HEAD).
commit_on() {
  ( cd "$1" && git add -A && git commit -qm "$2" )
  b=$(cd "$1" && git rev-list --max-parents=0 HEAD); h=$(cd "$1" && git rev-parse HEAD)
}

# 19) CI_PLACEHOLDER_ALLOW replaces the working tree's allowlist, both ways.
printf '# none\n' > "$tmp/allow-none"; printf 'x.md\n' > "$tmp/allow-x"
r=$(make_repo); printf '%s\n' "$ph" >> "$r/README.md"; commit_on "$r" "docs: ph T-116"
out=$( cd "$r" && CI_PLACEHOLDER_ALLOW="$tmp/allow-none" "$SH" scripts/ci-checks.sh "$b" "$h" 2>&1 ); rc=$?
expect_closed "allowlist is read from the target branch" "CI_PLACEHOLDER_ALLOW without the file overrides the tree's allowlist"
out=$( cd "$r" && CI_PLACEHOLDER_ALLOW="" "$SH" scripts/ci-checks.sh "$b" "$h" 2>&1 ); rc=$?
expect_closed "Unreplaced" "CI_PLACEHOLDER_ALLOW set but empty allowlists nothing"
rm -rf "$r"
r=$(make_repo); printf '%s\n' "$ph" > "$r/x.md"; commit_on "$r" "docs: ph T-117"
out=$( cd "$r" && CI_PLACEHOLDER_ALLOW="$tmp/allow-x" "$SH" scripts/ci-checks.sh "$b" "$h" 2>&1 ); rc=$?
if [ "$rc" -eq 0 ]; then ok "CI_PLACEHOLDER_ALLOW with the file allowlists it"; else bad "CI_PLACEHOLDER_ALLOW with the file allowlists it (rc=$rc, out: $out)"; fi
rm -rf "$r"

# 20) Nothing can turn a secret into "Binary files differ" or an empty diff:
#     .gitattributes -diff / binary / textconv, an external diff, a NUL byte. Each
#     case first proves plain `git diff` really hides it, so it can't pass vacuously.
# check_hidden <root> <description> [VAR=value]: run plain diff and ci-checks.sh
# (with the optional env assignment), expect the secret hidden then caught.
check_hidden() {
  plain=$( cd "$1" && env ${3:+"$3"} git diff "$b" "$h" -U0 2>&1 ); prc=$?
  if [ "$prc" -ne 0 ] || printf '%s' "$plain" | grep -aq AKIA; then bad "$2: precondition (plain git diff must succeed and hide the secret; rc=$prc)"; fi
  out=$( cd "$1" && env ${3:+"$3"} "$SH" scripts/ci-checks.sh "$b" "$h" 2>&1 ); rc=$?
  expect_closed "Possible secret detected" "$2 can't hide a secret"
  rm -rf "$1"
}
r=$(make_repo); printf 's.cfg -diff\n' > "$r/.gitattributes"; printf '%s\n' "$aws" > "$r/s.cfg"
commit_on "$r" "chore: hidden T-118"; check_hidden "$r" ".gitattributes -diff"
r=$(make_repo); printf 's.cfg binary\n' > "$r/.gitattributes"; printf '%s\n' "$aws" > "$r/s.cfg"
commit_on "$r" "chore: hidden T-119"; check_hidden "$r" ".gitattributes binary"
r=$(make_repo); printf 's.cfg diff=hide\n' > "$r/.gitattributes"; printf '%s\n' "$aws" > "$r/s.cfg"
( cd "$r" && git config diff.hide.textconv true )
commit_on "$r" "chore: hidden T-120"; check_hidden "$r" "a textconv driver"
r=$(make_repo); printf '%s\n' "$aws" > "$r/s.cfg"
commit_on "$r" "chore: hidden T-121"; check_hidden "$r" "an external diff (GIT_EXTERNAL_DIFF)" GIT_EXTERNAL_DIFF=true
r=$(make_repo); printf 'x\000y\n%s\n' "$aws" > "$r/s.dat"
commit_on "$r" "chore: hidden T-122"; check_hidden "$r" "a NUL byte"

# 21) Binary content under a UTF-8 locale still passes (BSD sed/grep reject invalid
#     UTF-8 unless the script runs with LC_ALL=C). Only meaningful on macOS/BSD:
#     GNU sed never fails on these bytes, so on Linux CI this passes regardless.
r=$(make_repo); printf 'img\377\376\001\n' > "$r/logo.png"; commit_on "$r" "feat: logo T-123"
out=$( cd "$r" && LC_ALL=C.UTF-8 "$SH" scripts/ci-checks.sh "$b" "$h" 2>&1 ); rc=$?
if [ "$rc" -eq 0 ]; then ok "binary file under a UTF-8 locale passes"; else bad "binary file under a UTF-8 locale passes (rc=$rc, out: $out)"; fi
rm -rf "$r"

# 22) The per-file placeholder diff can't be hidden by .gitattributes either.
r=$(make_repo); printf 'x.cfg -diff\n' > "$r/.gitattributes"; printf '%s\n' "$ph" > "$r/x.cfg"
commit_on "$r" "chore: hidden ph T-124"
out=$( cd "$r" && "$SH" scripts/ci-checks.sh "$b" "$h" 2>&1 ); rc=$?
expect_closed "Unreplaced [insert ... here] placeholder in 'x.cfg'" "placeholder in a -diff file is caught"
rm -rf "$r"

# 23) Renaming an allowlisted file to a non-allowlisted path carries its placeholder
#     out (--no-renames shows the move as delete + add, so the content is checked).
r=$(make_repo); printf '%s\n' "$ph" > "$r/README.md"; commit_on "$r" "docs: allowlisted ph T-125"
mid=$h; ( cd "$r" && git mv README.md notes.md && git commit -qm "chore: move T-126" ); h=$(cd "$r" && git rev-parse HEAD)
out=$( cd "$r" && "$SH" scripts/ci-checks.sh "$mid" "$h" 2>&1 ); rc=$?
expect_closed "placeholder in 'notes.md'" "rename out of an allowlisted path is caught"
rm -rf "$r"

# 24) Filenames are data: no glob expansion, no pathspec magic, no quoting, no
#     word splitting can make a file's placeholder be checked as another path.
# name_case <filename> <needle> <description>: commit <filename> holding a placeholder
# (README.md, allowlisted, exists so a glob could expand to it); expect a failure.
name_case() {
  r=$(make_repo); echo readme > "$r/README.md"; printf '%s\n' "$ph" > "$r/$1"
  commit_on "$r" "chore: odd name T-127"
  out=$( cd "$r" && "$SH" scripts/ci-checks.sh "$b" "$h" 2>&1 ); rc=$?
  expect_closed "$2" "$3"
  [ ! -e "$r/PWNED" ] || : > "$tmp/PWNED"   # surface a payload that ran in the repo
  rm -rf "$r"
}
name_case 'READM[E].md'  "  READM?E?.md: line 1"  "glob-like filename isn't expanded to an allowlisted file"
name_case ':(top)x.md'   "  ??top?x.md: line 1"   "pathspec-magic filename is read literally"
name_case "$(printf 'caf\303\251.md')" "  caf??.md: line 1" "non-ASCII filename is checked"
name_case 'a b.md'       "  a b.md: line 1"       "filename with a space is checked whole"
name_case "$(printf 'a\tb.md')" "Unusual filename" "filename git must quote fails closed"
# A filename is never code: under GNU sed, `#;e cmd;#` in an interpolated sed script
# runs cmd. Expect its (sanitized) location reported and no PWNED file.
name_case 'x#;e touch PWNED;#.md' "  x??e touch PWNED??.md: line 1" "filename with sed syntax is reported, not run"
if [ ! -e PWNED ] && [ ! -e "$tmp/PWNED" ]; then ok "filename with sed syntax runs nothing"
else bad "filename with sed syntax ran a command (PWNED exists)"; fi
r=$(make_repo); mkdir -p "$r/docs"; echo d > "$r/docs/$(printf 'caf\303\251.md')"; commit_on "$r" "docs: odd name T-128"
out=$( cd "$r" && "$SH" scripts/ci-checks.sh "$b" "$h" 2>&1 ); rc=$?
expect_closed "touches authored /docs/*" "non-ASCII /docs filename still needs consensus"
rm -rf "$r"
r=$(make_repo); mkdir -p "$r/docs"; echo d > "$r/docs/$(printf 'a\tb.md')"; commit_on "$r" "docs: tab name T-129"
out=$( cd "$r" && "$SH" scripts/ci-checks.sh "$b" "$h" 2>&1 ); rc=$?
expect_closed "touches authored /docs/*" "/docs filename git must quote still needs consensus"
rm -rf "$r"

# 25) Moving a file out of /docs is a /docs change (--no-renames: the delete shows),
#     so it needs the consensus assertion like any other /docs edit.
r=$(make_repo); mkdir -p "$r/docs"; echo d > "$r/docs/x.md"
( cd "$r" && git add -A && git commit -qm "docs: add T-130

unanimous-consensus: T-130" )
mid=$(cd "$r" && git rev-parse HEAD)
( cd "$r" && mkdir notes && git mv docs/x.md notes/x.md && git commit -qm "chore: move doc out T-131" )
h=$(cd "$r" && git rev-parse HEAD)
out=$( cd "$r" && "$SH" scripts/ci-checks.sh "$mid" "$h" 2>&1 ); rc=$?
expect_closed "touches authored /docs/*" "moving a file out of /docs needs consensus"
rm -rf "$r"

# --- PR-controlled text never reaches the log; every added line is scanned (starter T-024)
# Canaries stay harmless if a failing case prints them in CI (a warning annotation,
# a notice), and failing output is shown through od -c so it can't drive the log.
vso='##vso[task.logissue type=warning]T024-canary'
ghc='::notice::T024-canary'
t24_fail() { bad "$1 (rc=$rc)"; printf '%s' "$out" | od -c | sed -n '1,30p' >&2; }
# t24 <description> <rc> <needle>...: exact rc, every needle in $out.
t24() {
  t24d=$1 t24rc=$2; shift 2; t24ok=1
  [ "$rc" -eq "$t24rc" ] || t24ok=0
  for t24n in "$@"; do has "$t24n" || t24ok=0; done
  if [ "$t24ok" = 1 ]; then ok "$t24d"; else t24_fail "$t24d"; fi
}
# absent <description> <needle>...: no needle in $out.
absent() {
  t24d=$1; shift; t24ok=1
  for t24n in "$@"; do ! printf '%s' "$out" | grep -qF -- "$t24n" || t24ok=0; done
  if [ "$t24ok" = 1 ]; then ok "$t24d"; else t24_fail "$t24d"; fi
}
# ci_on <root> [cwd]: run ci-checks.sh over $b..$h (from <cwd> when given); sets $rc, $out.
ci_on() { out=$( cd "${2:-$1}" && "$SH" "$1/scripts/ci-checks.sh" "$b" "$h" 2>&1 ); rc=$?; }

# 26) A line whose content starts with "++" is scanned (the old /^+++/d filter dropped it).
r=$(make_repo); printf 'ok\n++ %s\n' "$ph" > "$r/p.txt"; commit_on "$r" "chore: plusplus ph T-140"; ci_on "$r"
t24 "a ++-prefixed placeholder is caught, with its line" 1 "placeholder in 'p.txt'" "  p.txt: line 2"; rm -rf "$r"
r=$(make_repo); printf '++ %s\n' "$aws" > "$r/s.txt"; commit_on "$r" "chore: plusplus secret T-141"; ci_on "$r"
t24 "a ++-prefixed secret is caught" 1 "Possible secret detected"
absent "...and never echoed" "AKIA"; rm -rf "$r"
# Content that looks like diff syntax is only content: a line "diff --git a b" doesn't
# restart the parser and "@@ -1 +1 @@" isn't a hunk header, so the hit is on line 3.
r=$(make_repo); printf 'diff --git a b\n@@ -1 +1 @@\n%s\n' "$ph" > "$r/d.txt"; commit_on "$r" "chore: diff-like content T-160"; ci_on "$r"
t24 "content lines that look like diff --git and @@ are counted as lines" 1 "placeholder in 'd.txt'" "  d.txt: line 3"; rm -rf "$r"

# 27) Line numbers are new-file line numbers: two hunks, replacements (no '-' line is
#     counted, '+c' without ',d'), a '\ No newline' before the hit, a final line with no
#     newline, and CRLF content.
r=$(make_repo); printf 'l1\nl2\nl3\nl4\nl5\nl6\nl7\nl8\nl9\n' > "$r/m.txt"; commit_on "$r" "chore: base T-142"
printf 'l1\n%s\nl3\nl4\nl5\nl6\nl7\n%s\nl9\n' "$ph" "$ph" > "$r/m.txt"; commit_on "$r" "chore: two hunks T-142"
b=$(cd "$r" && git rev-parse HEAD~1); ci_on "$r"
t24 "hits in two replaced hunks report lines 2 and 8" 1 "  m.txt: line 2" "  m.txt: line 8"
absent "...and no other line" "m.txt: line 1" "m.txt: line 3" "m.txt: line 9"; rm -rf "$r"
r=$(make_repo); printf 'a' > "$r/n.txt"; commit_on "$r" "chore: base T-143"
printf 'a\n%s\n' "$ph" > "$r/n.txt"; commit_on "$r" "chore: grow T-143"; b=$(cd "$r" && git rev-parse HEAD~1); ci_on "$r"
t24 "a '\\ No newline' line before the hit isn't counted" 1 "  n.txt: line 2"; rm -rf "$r"
r=$(make_repo); printf 'x\n%s' "$ph" > "$r/e.txt"; commit_on "$r" "chore: no final newline T-144"; ci_on "$r"
t24 "a final line with no newline gets its line number" 1 "  e.txt: line 2"; rm -rf "$r"
r=$(make_repo); printf 'a\r\n%s\r\n' "$ph" > "$r/w.txt"; commit_on "$r" "chore: crlf T-145"; ci_on "$r"
t24 "a CRLF placeholder gets its line number" 1 "  w.txt: line 2"; rm -rf "$r"
r=$(make_repo); printf '%s\n' "$ph" > "$r/f1.txt"; printf 'ok\n%s\n' "$ph" > "$r/f2.txt"; commit_on "$r" "chore: two files T-161"; ci_on "$r"
t24 "two files in one diff each report their own line" 1 "placeholder in 'f1.txt'" "  f1.txt: line 1" "placeholder in 'f2.txt'" "  f2.txt: line 2"
absent "...and neither borrows the other's" "f1.txt: line 2" "f2.txt: line 1"; rm -rf "$r"

# 28) Content is never echoed: canaries in a placeholder line, a file name and a commit
#     subject come out sanitized, and the raw text never appears.
r=$(make_repo); printf '%s %s %s\n' "$ph" "$vso" "$ghc" > "$r/c.txt"; commit_on "$r" "chore: canary line T-146"; ci_on "$r"
t24 "a placeholder line with log commands reports only its location" 1 "  c.txt: line 1"
absent "...and never its content" "T024-canary" "##vso[" "::notice::" "use ["; rm -rf "$r"
r=$(make_repo); printf '%s\n' "$ph" > "$r/##vso[x]::y.md"; commit_on "$r" "chore: canary name T-147"; ci_on "$r"
t24 "a file name with log commands is sanitized" 1 "placeholder in '??vso?x???y.md'" "  ??vso?x???y.md: line 1"
absent "...and never printed raw" "##vso[" "]::y"; rm -rf "$r"
r=$(make_repo); echo x >> "$r/file.txt"; commit_on "$r" "chore: $vso $ghc"; ci_on "$r"
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -qxF "CI-CHECK FAIL: Commit $h is missing a Task ID (T-NNN). First line: chore? ??vso?task.logissue type?warning?T024-canary ??notice??T024-canary"
then ok "a commit subject with log commands is sanitized, exactly"; else t24_fail "a commit subject with log commands is sanitized, exactly"; fi
absent "...and never printed raw" "##vso[" "::notice::"; rm -rf "$r"
long=$(printf 'x%.0s' $(seq 1 300)); want=$(printf 'x%.0s' $(seq 1 200))
r=$(make_repo); echo x >> "$r/file.txt"; commit_on "$r" "$long"; ci_on "$r"
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -qxF "CI-CHECK FAIL: Commit $h is missing a Task ID (T-NNN). First line: $want..."
then ok "a 300-byte subject is cut to 200 bytes plus ..."; else t24_fail "a 300-byte subject is cut to 200 bytes plus ..."; fi
rm -rf "$r"

# 29) The FAIL line comes first, then at most 20 locations and a count of the rest.
r=$(make_repo); i=0; : > "$r/k.txt"; while [ "$i" -lt 25 ]; do printf '%s\n' "$ph" >> "$r/k.txt"; i=$((i + 1)); done
commit_on "$r" "chore: many T-148"; ci_on "$r"
n=$(printf '%s\n' "$out" | grep -c '^  k\.txt: line ')
fl=$(printf '%s\n' "$out" | grep -n 'Unreplaced' | cut -d: -f1); ll=$(printf '%s\n' "$out" | grep -n '^  k\.txt: line 1$' | cut -d: -f1)
if [ "$rc" -eq 1 ] && [ "$n" -eq 20 ] && printf '%s\n' "$out" | grep -qx '  ...and 5 more' \
   && printf '%s\n' "$out" | grep -qx '  k.txt: line 20' && [ -n "$fl" ] && [ -n "$ll" ] && [ "$fl" -lt "$ll" ]
then ok "25 hits print the FAIL line, then exactly 20 locations and '...and 5 more'"
else t24_fail "25 hits print the FAIL line, then exactly 20 locations and '...and 5 more' (n=$n)"; fi
rm -rf "$r"

# 30) Type changes are scanned: a file turned into a symlink whose target holds a
#     placeholder or a secret. A gitlink carries no content and passes.
r=$(make_repo); echo l > "$r/l.txt"; commit_on "$r" "chore: base T-149"
rm "$r/l.txt"; ln -s "$ph" "$r/l.txt"; commit_on "$r" "chore: symlink T-149"; b=$(cd "$r" && git rev-parse HEAD~1)
st=$(cd "$r" && git diff --name-status "$b" "$h")
case "$st" in T*) ;; *) bad "symlink precondition: name-status should be T (got: $st)" ;; esac
ci_on "$r"; t24 "a placeholder in a symlink type change is caught" 1 "placeholder in 'l.txt'" "  l.txt: line 1"; rm -rf "$r"
r=$(make_repo); echo l > "$r/l.txt"; commit_on "$r" "chore: base T-150"
rm "$r/l.txt"; ln -s "$aws" "$r/l.txt"; commit_on "$r" "chore: symlink T-150"; b=$(cd "$r" && git rev-parse HEAD~1)
ci_on "$r"; t24 "a secret in a symlink type change is caught" 1 "Possible secret detected"; rm -rf "$r"
# gitlink_repo: make_repo, then turn g.txt into a gitlink in a direct commit (git add -A
# would stage the gitlink's removal). Sets $r, $b, $h.
gl=1111111111111111111111111111111111111111
gitlink_repo() {
  r=$(make_repo); echo g > "$r/g.txt"; commit_on "$r" "chore: base $1"
  ( cd "$r" && git rm -q --cached g.txt && rm g.txt && git update-index --add --cacheinfo "160000,$gl,g.txt" \
      && git commit -qm "chore: gitlink $1" )
  b=$(cd "$r" && git rev-parse HEAD~1); h=$(cd "$r" && git rev-parse HEAD)
}
gitlink_repo T-151
if ! ( cd "$r" && git diff "$b" "$h" ) | grep -q '^+Subproject commit'; then bad "gitlink precondition: diff should show Subproject commit"; fi
err=$( cd "$r" && "$SH" scripts/ci-checks.sh "$b" "$h" 2>&1 >/dev/null ); rc=$?
if [ "$rc" -eq 0 ] && [ -z "$err" ]; then ok "a gitlink passes with empty stderr"; else out=$err; t24_fail "a gitlink passes with empty stderr"; fi
rm -rf "$r"

# 31) Git config can't change what's scanned. Each case first proves the setting really
#     changes a plain diff, so it can't pass vacuously.
ESC=$(printf '\033')
r=$(make_repo); printf '%s\n' "$ph" > "$r/p.txt"; printf '%s\n' "$aws" > "$r/s.txt"; ( cd "$r" && git config color.ui always )
commit_on "$r" "chore: colour T-152"
( cd "$r" && git diff "$b" "$h" ) | grep -q "$ESC" || bad "color.ui precondition: plain git diff should emit ESC"
ci_on "$r"; t24 "color.ui=always hides neither a placeholder nor a secret" 1 "placeholder in 'p.txt'" "Possible secret detected"; rm -rf "$r"
gitlink_repo T-153; printf '%s\n' "$ph" > "$r/p.txt"; ( cd "$r" && git add p.txt && git commit -qm "chore: ph T-153" && git config diff.submodule log )
b=$(cd "$r" && git rev-list --max-parents=0 HEAD); h=$(cd "$r" && git rev-parse HEAD)
( cd "$r" && git diff "$b" "$h" ) | grep -q '^Submodule' || bad "diff.submodule precondition: plain git diff should print Submodule"
ci_on "$r"; t24 "diff.submodule=log neither breaks the parser nor hides a placeholder" 1 "placeholder in 'p.txt'"; rm -rf "$r"
r=$(make_repo); mkdir -p "$r/sub"; echo s > "$r/sub/s.txt"; printf '%s\n' "$ph" > "$r/p.txt"; ( cd "$r" && git config diff.relative true )
commit_on "$r" "chore: relative T-154"
rel=$(cd "$r/sub" && git diff --name-only "$b" "$h") || rel='(git failed)'
[ "$rel" = "s.txt" ] || bad "diff.relative precondition: a plain diff from sub/ should list only s.txt (got: $rel)"
ci_on "$r" "$r/sub"; t24 "diff.relative=true run from a subdirectory still scans the whole tree" 1 "placeholder in 'p.txt'"; rm -rf "$r"
r=$(make_repo); printf 'a\n\nb\n' > "$r/z.txt"; commit_on "$r" "chore: base T-155"
printf 'a\n\n%s\n' "$ph" > "$r/z.txt"; ( cd "$r" && git config diff.suppressBlankEmpty true ); commit_on "$r" "chore: ph T-155"
b=$(cd "$r" && git rev-parse HEAD~1)
( cd "$r" && GIT_DIFF_OPTS=-u3 git diff "$b" "$h" -U0 ) | grep -q '^ a$' || bad "GIT_DIFF_OPTS precondition: -u3 should override -U0"
( cd "$r" && git diff "$b" "$h" -U1 ) | grep -qx '' || bad "diff.suppressBlankEmpty precondition: a context diff should print a bare empty line"
out=$( cd "$r" && GIT_DIFF_OPTS=-u3 "$SH" scripts/ci-checks.sh "$b" "$h" 2>&1 ); rc=$?
t24 "GIT_DIFF_OPTS and diff.suppressBlankEmpty can't change the diff" 1 "  z.txt: line 3"; rm -rf "$r"
# All of them at once, on a range with a gitlink, a blank context line and a file in
# sub/, run from sub/: a clean change still passes.
# (Explicit git add: add -A would stage the gitlink's removal.)
gitlink_repo T-156; mkdir -p "$r/sub"; echo s > "$r/sub/s.txt"; printf 'a\n\nb\n' > "$r/z.txt"
( cd "$r" && git add sub/s.txt z.txt && git commit -qm "chore: base T-156" )
printf 'a\n\nc\n' > "$r/z.txt"; echo t >> "$r/sub/s.txt"
( cd "$r" && git config color.ui always && git config diff.relative true && git config diff.submodule log \
    && git config diff.suppressBlankEmpty true && git add sub/s.txt z.txt && git commit -qm "chore: clean T-156" )
b=$(cd "$r" && git rev-list --max-parents=0 HEAD); h=$(cd "$r" && git rev-parse HEAD)
( cd "$r" && git diff "$b" "$h" ) | grep -q '^Submodule' || bad "all-configs precondition: the range should hold a gitlink"
out=$( cd "$r/sub" && GIT_DIFF_OPTS=-u3 "$SH" "$r/scripts/ci-checks.sh" "$b" "$h" 2>&1 ); rc=$?
t24 "...and a clean change still passes under all of them, run from sub/" 0 "all procedure gates passed"; rm -rf "$r"

# 31c) Git's own warnings carry a PR's bytes (a .gitattributes attribute name, a
#      .gitmodules submodule name): a green run must print none of them.
gitlink_repo T-162
printf '[submodule "%s"]\n\tpath = -x\n\turl = ./x\n' "$vso" > "$r/.gitmodules"
printf 'file.txt %s\n* %s[2J\n' "$vso" "$ESC" > "$r/.gitattributes"; echo more >> "$r/file.txt"
( cd "$r" && git add .gitmodules .gitattributes file.txt 2>/dev/null && git commit -qm "chore: hostile git metadata T-162" 2>/dev/null )
b=$(cd "$r" && git rev-list --max-parents=0 HEAD); h=$(cd "$r" && git rev-parse HEAD)
gw=$(cd "$r" && git diff "$b" "$h" 2>&1 >/dev/null)
case "$gw" in *"##vso["*) ;; *) bad "git-warning precondition: a plain git diff should warn with ##vso[" ;; esac
ci_on "$r"
t24 "git's warnings about a PR's .gitattributes and .gitmodules never reach the log" 0 "all procedure gates passed"
absent "...no canary, ##vso[ or ESC in stdout or stderr" "T024-canary" "##vso[" "$ESC"; rm -rf "$r"

# 31b) The script runs from the top of the work tree, failing closed if it can't find
#      it, and a relative CI_PLACEHOLDER_ALLOW still names the caller's file.
r=$(make_repo); printf '%s\n' "$ph" > "$r/x.md"; mkdir -p "$r/sub"; echo s > "$r/sub/s.txt"
printf 'x.md\n' > "$r/sub/allow-x"; printf '# none\n' > "$r/sub/allow-none"; commit_on "$r" "chore: relative allow T-159"
out=$( cd "$r/sub" && CI_PLACEHOLDER_ALLOW=allow-x "$SH" ../scripts/ci-checks.sh "$b" "$h" 2>&1 ); rc=$?
t24 "a relative CI_PLACEHOLDER_ALLOW from a subdirectory still allowlists its entry" 0 "all procedure gates passed"
out=$( cd "$r/sub" && CI_PLACEHOLDER_ALLOW=allow-none "$SH" ../scripts/ci-checks.sh "$b" "$h" 2>&1 ); rc=$?
t24 "...and one without the entry still fails" 1 "placeholder in 'x.md'"
run_ci "$r" "$b" "$h" git 'rev-parse --show-toplevel'
expect_closed "Finding the top of the work tree failed" "a rev-parse --show-toplevel error fails closed" stub
rm -rf "$r"

# 32) The block on its own: the parser exits 2 on what it doesn't recognise, and se_safe
#     maps every byte. Sourced from the script under test, like the PR gate runs it.
blk="$tmp/safe-echo.sh"
sed -n '/^# BEGIN safe-echo/,/^# END safe-echo$/p' "$sut" > "$blk"
[ -s "$blk" ] || bad "the safe-echo block was extracted from ci-checks.sh"
# The single-quoted scripts below expand $1 and $2 in the child shell, not here.
# shellcheck disable=SC2016
parse2() {  # parse2 <description> <diff text>: se_added must exit 2 with empty stdout
  po=$("$SH" -c '. "$1"; printf "%s\n" "$2" | se_added' sh "$blk" "$2"); prc=$?
  if [ "$prc" -eq 2 ] && [ -z "$po" ]; then ok "$1"; else bad "$1 (rc=$prc)"; printf '%s' "$po" | od -c | sed -n '1,10p' >&2; fi
}
parse2 "parser: an unknown line in a hunk exits 2" "$(printf 'diff --git a/x b/x\n@@ -1 +1 @@\n?weird')"
parse2 "parser: a line before the first diff --git exits 2" "$(printf 'junk\ndiff --git a/x b/x')"
parse2 "parser: a malformed hunk header exits 2" "$(printf 'diff --git a/x b/x\n@@ -1 +x1 @@\n+a')"
parse2 "parser: a backslash line other than the no-newline marker exits 2" "$(printf 'diff --git a/x b/x\n@@ -1 +1 @@\n\\ something else')"
# shellcheck disable=SC2016
bytes=$("$SH" -c '
  . "$1"; LC_ALL=C; export LC_ALL; bad=""; i=1
  while [ "$i" -le 255 ]; do
    b=$(printf "\\$(printf %03o "$i")x"); b=${b%x}
    case "$b" in [A-Za-z0-9._/\ -]) want=$b ;; *) want="?" ;; esac
    got=$(se_safe "$b") || { bad="$bad $i(rc)"; i=$((i + 1)); continue; }
    [ "$got" = "$want" ] || bad="$bad $i"
    i=$((i + 1))
  done
  printf "%s" "$bad"' sh "$blk")
if [ -z "$bytes" ]; then ok "se_safe maps every byte 1-255 to itself or ?"; else bad "se_safe maps every byte 1-255 to itself or ? (wrong:$bytes)"; fi
# shellcheck disable=SC2016
sv=$("$SH" -c '. "$1"; se_safe "$(printf "a\nb\rc\033[2J%%0A  ::x:: ##vso[a]b")"' sh "$blk")
if [ "$sv" = "a?b?c??2J?0A  ??x?? ??vso?a?b" ]; then ok "se_safe: LF, CR, ESC, %0A, ::, ##vso[ all become ? on one line"
else bad "se_safe: LF, CR, ESC, %0A, ::, ##vso[ all become ? on one line (got: $(printf '%s' "$sv" | od -c | head -3))"; fi
# se_v <value> [VAR=value]: se_safe <value> from the extracted block, in $SH.
# shellcheck disable=SC2016
se_v() { env ${2:+"$2"} "$SH" -c '. "$1"; se_safe "$2"' sh "$blk" "$1"; }
# se_is <description> <got> <want>
se_is() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (got: $(printf '%s' "$2" | od -c | head -3))"; fi; }
se_is "se_safe: empty in, empty out" "$(se_v '')" ''
x200=$(printf 'y%.0s' $(seq 1 200))
se_is "se_safe: 200 bytes are not cut" "$(se_v "$x200")" "$x200"
se_is "se_safe: 201 bytes become 200 plus ..." "$(se_v "${x200}z")" "$x200..."
if [ "$(uname)" = Darwin ]; then
  se_is "se_safe under a UTF-8 locale still works byte by byte" "$(se_v "$(printf 'caf\303\251')" LC_ALL=C.UTF-8)" "caf??"
fi

# 33) Fail closed in the new code, and the location pass can't change a decision.
r=$(make_repo); n201=$(printf 'n%.0s' $(seq 1 197)).txt; printf '%s\n' "$ph" > "$r/$n201"; commit_on "$r" "chore: long name T-157"
run_ci "$r" "$b" "$h" cut '-c1-200'; expect_closed "Sanitizing a file name failed" "sanitizer (cut) error on a 201-byte name fails closed" stub
rm -rf "$r"
r=$(make_repo); printf '%s\n' "$ph" > "$r/p.txt"; commit_on "$r" "chore: ph T-158"
run_ci "$r" "$b" "$h" grep '*-E -- ^*'
if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -qF "placeholder in 'p.txt'" && [ -e "$tmp/hit" ]; then ok "a failing location pass still fails the placeholder gate"
else t24_fail "a failing location pass still fails the placeholder gate"; fi
rm -rf "$r"

echo
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
