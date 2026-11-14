#!/usr/bin/env sh
# Fixture test for .githooks/pre-commit (secret scan + protected branch).
#
# Stack-neutral: POSIX sh + git only. Builds throwaway git repos in a temp dir,
# stages content that should pass/fail each gate, runs the hook, and asserts its
# exit code and the gate it names. Deterministic (no network, no wall-clock, no
# random; global/system git config ignored).
#
# Run:  sh scripts/test/test-pre-commit.sh
#       PRE_COMMIT_HOOK=<path> sh scripts/test/test-pre-commit.sh  (test another hook)
#       SH=dash sh scripts/test/test-pre-commit.sh                 (run it under dash)
# Exit: 0 all pass, 1 any failure.

set -u

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
playbook_src=$(CDPATH='' cd -- "$test_dir/../.." && pwd)
sut="${PRE_COMMIT_HOOK:-$playbook_src/.githooks/pre-commit}"
case "$sut" in /*) ;; *) sut="$PWD/$sut" ;; esac
SH="${SH:-sh}"

# Stubs and scratch files live outside the fixture repos.
tmp=$(mktemp -d 2>/dev/null || mktemp -d -t pc)
trap 'rm -rf "$tmp"' EXIT

# Ignore the runner's own git config (hooksPath, default branch, signing),
# attributes, and any inherited repo pointers.
mkdir -p "$tmp/home" "$tmp/xdg"
HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/xdg"
GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ATTR_NOSYSTEM=1
export HOME XDG_CONFIG_HOME GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM GIT_ATTR_NOSYSTEM
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE GIT_EXTERNAL_DIFF

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf "  PASS: %s\n" "$1"; }
bad() { fail=$((fail + 1)); printf "  FAIL: %s\n" "$1" >&2; }

# Build a repo with a baseline commit on main, then switch to a feature branch
# (so the protected-branch gate isn't what blocks). Echo its path.
make_repo() {
  root=$(mktemp -d 2>/dev/null || mktemp -d -t pc)
  (
    cd "$root" && git init -q && git symbolic-ref HEAD refs/heads/main \
      && git config user.email t@t && git config user.name t \
      && git config commit.gpgsign false
    echo "baseline" > file.txt
    git add file.txt && git commit -qm "baseline T-000"
    git checkout -q -b feat/x
  )
  echo "$root"
}

# run_hook <root> <content>: append content to file.txt, stage only that file,
# run the hook. Sets $rc and $err (hook stderr).
run_hook() {
  printf '%s\n' "$2" >> "$1/file.txt"
  ( cd "$1" && git add file.txt )
  err=$( cd "$1" && "$SH" "$sut" 2>&1 >/dev/null ); rc=$?
}

# expect_block <root> <content> <label> <description>: hook exits 1 naming <label>.
expect_block() {
  run_hook "$1" "$2"
  if [ "$rc" -eq 1 ] && printf '%s' "$err" | grep -qF -- "$3"; then ok "$4"
  else bad "$4 (rc=$rc, stderr: $err)"; fi
}

# rep <char> <n>: print <char> n times.
rep() {
  s='' i=0
  while [ "$i" -lt "$2" ]; do s="$s$1"; i=$((i + 1)); done
  printf '%s' "$s"
}

# Secret literals are assembled at runtime so this file never contains a string
# the secret scanner (hook or CI) would flag. One secret per case: the hook stops
# at the first match, so each case asserts exactly one label.
d=-----
rsa_key=$(printf '%sBEGIN RSA PRIVATE KEY%s\nMIIEow\n%sEND RSA PRIVATE KEY%s' "$d" "$d" "$d" "$d")
ssh_key=$(printf '%sBEGIN OPENSSH PRIVATE KEY%s' "$d" "$d")
aws_key="AKIA$(printf 'IOSFODNN7EXAMPLE')"
gh_token="ghp_$(rep a 36)"
slack_token="xoxb-$(printf '123-abc')"
openai_key="sk-$(rep A 24)"
anthropic_key="sk-ant-api03-$(rep b 24)"
placeholder=$(printf 'use [%s thing here]' insert)   # same reason: the hook blocks the literal

echo "test-pre-commit.sh"

# 1) Clean change passes, and no gate errors out (a grep option-parse error here
#    means some pattern was never actually scanned).
r=$(make_repo)
run_hook "$r" "clean line"
if [ "$rc" -eq 0 ] && [ -z "$err" ]; then ok "clean change passes with no scanner errors"
else bad "clean change passes with no scanner errors (rc=$rc, stderr: $err)"; fi
rm -rf "$r"

# 2) Private-key blocks — the regression: the pattern starts with '-' and was
#    parsed as a grep option, so this gate silently never ran.
r=$(make_repo); expect_block "$r" "$rsa_key" "Private key block" "RSA private key block blocks"; rm -rf "$r"
r=$(make_repo); expect_block "$r" "$ssh_key" "Private key block" "OPENSSH private key block blocks"; rm -rf "$r"

# 3) Every other secret pattern still blocks with its own label.
r=$(make_repo); expect_block "$r" "key=$aws_key"       "AWS access key ID"    "AWS key blocks"; rm -rf "$r"
r=$(make_repo); expect_block "$r" "tok=$gh_token"      "GitHub token"         "GitHub token blocks"; rm -rf "$r"
r=$(make_repo); expect_block "$r" "tok=$slack_token"   "Slack token"          "Slack token blocks"; rm -rf "$r"
r=$(make_repo); expect_block "$r" "key=$openai_key"    "OpenAI-style API key" "OpenAI-style key blocks"; rm -rf "$r"
r=$(make_repo); expect_block "$r" "key=$anthropic_key" "Anthropic API key"    "Anthropic key blocks"; rm -rf "$r"

# 4) Scanner error fails closed: a grep that errors (exit 2) on the private-key
#    pattern must block the commit, not read as "no match".
r=$(make_repo)
real_grep=$(command -v grep)
mkdir -p "$r/.stub"
cat > "$r/.stub/grep" <<EOF
#!/bin/sh
for a in "\$@"; do case "\$a" in *PRIVATE*) echo "grep: stub error" >&2; exit 2 ;; esac; done
exec "$real_grep" "\$@"
EOF
chmod +x "$r/.stub/grep"
printf '%s\n' "clean line" >> "$r/file.txt"
( cd "$r" && git add file.txt )
err=$( cd "$r" && PATH="$r/.stub:$PATH" "$SH" "$sut" 2>&1 >/dev/null ); rc=$?
if [ "$rc" -eq 1 ] && printf '%s' "$err" | grep -qF "Secret scanner error"; then ok "grep error fails closed"
else bad "grep error fails closed (rc=$rc, stderr: $err)"; fi
rm -rf "$r"

# 5) Commit on a protected branch blocks.
r=$(make_repo)
( cd "$r" && git checkout -q main )
expect_block "$r" "clean line" "Direct commit to 'main'" "commit on main blocks"
rm -rf "$r"

# --- Fail closed on git errors (starter T-013) ----------------------------------------

# make_stub <cmd> <exit>: a dir holding a <cmd> that prints an error, touches
# $STUB_HIT and exits <exit> when its argument string matches the glob $STUB_FAIL;
# otherwise it runs the real <cmd>. Put it on PATH only for the hook.
make_stub() {
  real=$(command -v "$1")
  mkdir -p "$tmp/stub-$1"
  cat > "$tmp/stub-$1/$1" <<EOF
#!/bin/sh
# shellcheck disable=SC2254
case "\$*" in \$STUB_FAIL) : > "\$STUB_HIT"; echo "stub: injected $1 failure" >&2; exit $2 ;; esac
exec "$real" "\$@"
EOF
  chmod +x "$tmp/stub-$1/$1"
}
make_stub git 128
make_stub sed 2
make_stub grep 2
make_stub awk 2
make_stub cut 1
make_stub tr 1

# expect_stub_block <root> <content> <cmd> <glob> <needle> <description>: stage
# <content>, run the hook with <cmd> failing on <glob>; expect exit 1 naming
# <needle>, and proof the targeted call ran.
expect_stub_block() {
  printf '%s\n' "$2" >> "$1/file.txt"
  ( cd "$1" && git add file.txt )
  rm -f "$tmp/hit"
  err=$( cd "$1" && PATH="$tmp/stub-$3:$PATH" STUB_FAIL="$4" STUB_HIT="$tmp/hit" \
    "$SH" "$sut" 2>&1 >/dev/null ); rc=$?
  if [ "$rc" -eq 1 ] && printf '%s' "$err" | grep -qF -- "$5" && [ -e "$tmp/hit" ]; then ok "$6"
  else bad "$6 (rc=$rc, stderr: $err)"; fi
}

# 6) A git error on any staged-content read blocks instead of reading as empty.
r=$(make_repo); expect_stub_block "$r" "key=$aws_key" git '*--name-only*' \
  "git diff --cached --name-only failed" "staged file list error fails closed"; rm -rf "$r"
r=$(make_repo); expect_stub_block "$r" "key=$aws_key" git '*diff --cached *-U0' \
  "git diff --cached failed" "staged diff error fails closed (secret not missed)"; rm -rf "$r"
r=$(make_repo); expect_stub_block "$r" "$placeholder" git '*diff --cached *-U0 -- *' \
  "git diff --cached -- 'file.txt' failed" "per-file diff error fails closed (placeholder not missed)"; rm -rf "$r"
r=$(make_repo); expect_stub_block "$r" "key=$aws_key" awk '*diff --git*' \
  "Parsing the staged diff failed" "diff parser error fails closed"; rm -rf "$r"
r=$(make_repo); expect_stub_block "$r" "key=$aws_key" cut '-f2-' \
  "Filtering the staged diff failed" "diff filter error fails closed"; rm -rf "$r"
r=$(make_repo); expect_stub_block "$r" "$placeholder" grep '*insert*' \
  "Placeholder scanner error" "placeholder grep error fails closed"; rm -rf "$r"

# 7) First commit in a new repo (no HEAD yet) still works: clean passes, a secret blocks.
new_repo() {
  r=$(mktemp -d 2>/dev/null || mktemp -d -t pc)
  ( cd "$r" && git init -q && git symbolic-ref HEAD refs/heads/feat/x )
}
new_repo; run_hook "$r" "clean line"
if [ "$rc" -eq 0 ] && [ -z "$err" ]; then ok "initial commit (no HEAD) clean change passes"
else bad "initial commit (no HEAD) clean change passes (rc=$rc, stderr: $err)"; fi
rm -rf "$r"
new_repo; expect_block "$r" "key=$aws_key" "AWS access key ID" "initial commit (no HEAD) secret blocks"; rm -rf "$r"

# 8) Nothing can hide staged content from the scans (starter T-014): .gitattributes -diff /
#    binary / textconv, an external diff, a NUL byte. Each case first proves a plain
#    `git diff --cached` really hides the secret, so it can't pass vacuously.
# hidden_block <root> <description> [VAR=value]: stage everything, expect the hook
# (with the optional env assignment) to block the AWS key.
hidden_block() {
  ( cd "$1" && git add -A )
  plain=$( cd "$1" && env ${3:+"$3"} git diff --cached -U0 2>&1 ); prc=$?
  if [ "$prc" -ne 0 ] || printf '%s' "$plain" | grep -aq AKIA; then bad "$2: precondition (plain git diff must succeed and hide the secret; rc=$prc)"; fi
  err=$( cd "$1" && env ${3:+"$3"} "$SH" "$sut" 2>&1 >/dev/null ); rc=$?
  if [ "$rc" -eq 1 ] && printf '%s' "$err" | grep -aqF "AWS access key ID"; then ok "$2 can't hide a staged secret"
  else bad "$2 can't hide a staged secret (rc=$rc, stderr: $err)"; fi
  rm -rf "$1"
}
r=$(make_repo); printf 's.cfg -diff\n' > "$r/.gitattributes"; printf 'key=%s\n' "$aws_key" > "$r/s.cfg"
hidden_block "$r" ".gitattributes -diff"
r=$(make_repo); printf 's.cfg binary\n' > "$r/.gitattributes"; printf 'key=%s\n' "$aws_key" > "$r/s.cfg"
hidden_block "$r" ".gitattributes binary"
r=$(make_repo); printf 's.cfg diff=hide\n' > "$r/.gitattributes"; printf 'key=%s\n' "$aws_key" > "$r/s.cfg"
( cd "$r" && git config diff.hide.textconv true ); hidden_block "$r" "a textconv driver"
r=$(make_repo); printf 'key=%s\n' "$aws_key" > "$r/s.cfg"
hidden_block "$r" "an external diff (GIT_EXTERNAL_DIFF)" GIT_EXTERNAL_DIFF=true
r=$(make_repo); printf 'x\000y\nkey=%s\n' "$aws_key" > "$r/s.dat"
hidden_block "$r" "a NUL byte"

# 9) A binary file under a UTF-8 locale still commits (BSD sed/grep reject invalid
#    UTF-8 unless the hook runs with LC_ALL=C). Only meaningful on macOS/BSD: GNU
#    sed never fails on these bytes, so on Linux CI this passes regardless.
r=$(make_repo); printf 'img\377\376\001\n' > "$r/logo.png"; ( cd "$r" && git add logo.png )
err=$( cd "$r" && LC_ALL=C.UTF-8 "$SH" "$sut" 2>&1 >/dev/null ); rc=$?
if [ "$rc" -eq 0 ] && [ -z "$err" ]; then ok "binary file under a UTF-8 locale commits"
else bad "binary file under a UTF-8 locale commits (rc=$rc, stderr: $err)"; fi
rm -rf "$r"

# 10) Placeholders: a -diff file, a rename out of an allowlisted path, and odd
#     filenames (glob, pathspec magic, non-ASCII, space) are all still checked.
# stage_block <root> <needle> <description>: stage everything; hook exits 1 naming <needle>.
stage_block() {
  ( cd "$1" && git add -A )
  err=$( cd "$1" && "$SH" "$sut" 2>&1 >/dev/null ); rc=$?
  if [ "$rc" -eq 1 ] && printf '%s' "$err" | grep -aqF -- "$2"; then ok "$3"
  else bad "$3 (rc=$rc, stderr: $err)"; fi
  [ ! -e "$1/PWNED" ] || : > "$tmp/PWNED"   # surface a payload that ran in the repo
  rm -rf "$1"
}
# allow_repo: make_repo plus an allowlisted, committed README.md. Sets $r.
allow_repo() {
  r=$(make_repo); printf 'README.md\n' > "$r/.placeholder-allow"; echo readme > "$r/README.md"
  ( cd "$r" && git add -A && git commit -qm "chore: allowlist T-910" )
}
r=$(make_repo); printf 'x.cfg -diff\n' > "$r/.gitattributes"; printf '%s\n' "$placeholder" > "$r/x.cfg"
stage_block "$r" "  x.cfg: line 1" "placeholder in a -diff file blocks"
allow_repo; printf '%s\n' "$placeholder" > "$r/README.md"; ( cd "$r" && git commit -qam "docs: ph T-911" && git mv README.md notes.md )
stage_block "$r" "  notes.md: line 1" "rename out of an allowlisted path blocks"
allow_repo; printf '%s\n' "$placeholder" > "$r/READM[E].md"; stage_block "$r" "  READM?E?.md: line 1" "glob-like filename isn't expanded to an allowlisted file"
allow_repo; printf '%s\n' "$placeholder" > "$r/:(top)x.md";  stage_block "$r" "  ??top?x.md: line 1" "pathspec-magic filename is read literally"
allow_repo; printf '%s\n' "$placeholder" > "$r/$(printf 'caf\303\251.md')"; stage_block "$r" "Unreplaced" "non-ASCII filename is checked"
allow_repo; printf '%s\n' "$placeholder" > "$r/a b.md";      stage_block "$r" "  a b.md: line 1" "filename with a space is checked whole"
allow_repo; printf '%s\n' "$placeholder" > "$r/$(printf 'a\tb.md')"; stage_block "$r" "Unusual filename" "filename git must quote blocks"
# A filename is never code: under GNU sed, `#;e cmd;#` in an interpolated sed script
# runs cmd. Expect the sanitized name and line, and no PWNED file.
allow_repo; printf '%s\n' "$placeholder" > "$r/x#;e touch PWNED;#.md"
stage_block "$r" "  x??e touch PWNED??.md: line 1" "filename with sed syntax is reported, not run"
if [ ! -e "$tmp/PWNED" ] && [ ! -e PWNED ]; then ok "filename with sed syntax runs nothing"
else bad "filename with sed syntax ran a command (PWNED exists)"; fi

# 11) Hand-editing a ledger's INDEX.md warns (exit 0, names the path); other paths
#     don't. Any <dir>/tasks/INDEX.md counts, so the starter's own history ledger
#     is covered without the hook naming it (starter T-015).
# index_warn <path> <yes|no> <description>
index_warn() {
  r=$(make_repo); mkdir -p "$r/$(dirname -- "$1")"; echo row >> "$r/$1"
  ( cd "$r" && git add -- "$1" )
  err=$( cd "$r" && "$SH" "$sut" 2>&1 >/dev/null ); rc=$?
  hit=no; printf '%s' "$err" | grep -qF -- "$1 is regenerated from per-task frontmatter" && hit=yes
  if [ "$rc" -eq 0 ] && [ "$hit" = "$2" ]; then ok "$3"; else bad "$3 (rc=$rc, stderr: $err)"; fi
  rm -rf "$r"
}
index_warn tasks/INDEX.md          yes "hand-edit of tasks/INDEX.md warns"
index_warn .starter/tasks/INDEX.md yes "hand-edit of the starter ledger's INDEX.md warns"
index_warn tasks/T-001.md          no  "a task file doesn't warn"
index_warn tasks/INDEX.md.orig     no  "INDEX.md.orig doesn't warn"
index_warn mytasks/INDEX.md        no  "mytasks/INDEX.md doesn't warn"

# --- Staged text never reaches the terminal unsanitized; every added line is scanned (starter T-024)
# Canaries stay harmless if a failing case prints them in CI (a warning annotation,
# a notice), and failing output is shown through od -c so it can't drive the log.
vso='##vso[task.logissue type=warning]T024-canary'
ghc='::notice::T024-canary'
t24_fail() { bad "$1 (rc=$rc)"; printf '%s' "$err" | od -c | sed -n '1,30p' >&2; }
# has <needle>: a needle starting with two spaces is a location line and must match a
# whole line of $err; any other needle matches anywhere.
has() { case "$1" in '  '*) printf '%s\n' "$err" | grep -qxF -- "$1" ;; *) printf '%s' "$err" | grep -qF -- "$1" ;; esac; }
# t24 <description> <rc> <needle>...: exact rc, every needle in $err.
t24() {
  t24d=$1 t24rc=$2; shift 2; t24ok=1
  [ "$rc" -eq "$t24rc" ] || t24ok=0
  for t24n in "$@"; do has "$t24n" || t24ok=0; done
  if [ "$t24ok" = 1 ]; then ok "$t24d"; else t24_fail "$t24d"; fi
}
# absent <description> <needle>...: no needle in $err.
absent() {
  t24d=$1; shift; t24ok=1
  for t24n in "$@"; do ! printf '%s' "$err" | grep -qF -- "$t24n" || t24ok=0; done
  if [ "$t24ok" = 1 ]; then ok "$t24d"; else t24_fail "$t24d"; fi
}
# hook_in <root> [cwd] [VAR=value]: stage everything in <root>, run the hook from <cwd>
# (default <root>); sets $rc, $err.
hook_in() {
  ( cd "$1" && git add -A )
  err=$( cd "${2:-$1}" && env ${3:+"$3"} "$SH" "$sut" 2>&1 >/dev/null ); rc=$?
}
# hook_stub <root> <cmd> <glob>: stage everything, run the hook with <cmd> failing on <glob>.
hook_stub() {
  ( cd "$1" && git add -A ); rm -f "$tmp/hit"
  err=$( cd "$1" && PATH="$tmp/stub-$2:$PATH" STUB_FAIL="$3" STUB_HIT="$tmp/hit" "$SH" "$sut" 2>&1 >/dev/null ); rc=$?
}
ph=$placeholder
php="Unreplaced [insert ... ""here] placeholder in staged content"   # split, so this file holds no placeholder

# 12) A line whose content starts with "++" is scanned (the old /^+++/d filter dropped it).
r=$(make_repo); printf 'ok\n++ %s\n' "$ph" > "$r/p.txt"; hook_in "$r"
t24 "a ++-prefixed placeholder blocks, with its line" 1 "$php" "  p.txt: line 2"; rm -rf "$r"
r=$(make_repo); printf '++ key=%s\n' "$aws_key" > "$r/s.txt"; hook_in "$r"
t24 "a ++-prefixed secret blocks, with its line" 1 "AWS access key ID" "  s.txt: line 1"
absent "...and never echoes it" "AKIA"; rm -rf "$r"
# Content that looks like diff syntax is only content: a line "diff --git a b" doesn't
# restart the parser and "@@ -1 +1 @@" isn't a hunk header, so the hit is on line 3.
r=$(make_repo); printf 'diff --git a b\n@@ -1 +1 @@\n%s\n' "$ph" > "$r/d.txt"; hook_in "$r"
t24 "content lines that look like diff --git and @@ are counted as lines" 1 "$php" "  d.txt: line 3"; rm -rf "$r"

# 13) Line numbers are new-file line numbers: two replaced hunks, a '\ No newline'
#     before the hit, a final line with no newline, CRLF, and two files.
r=$(make_repo); printf 'l1\nl2\nl3\nl4\nl5\nl6\nl7\nl8\nl9\n' > "$r/m.txt"; ( cd "$r" && git add -A && git commit -qm "chore: base T-920" )
printf 'l1\n%s\nl3\nl4\nl5\nl6\nl7\n%s\nl9\n' "$ph" "$ph" > "$r/m.txt"; hook_in "$r"
t24 "hits in two replaced hunks report lines 2 and 8" 1 "  m.txt: line 2" "  m.txt: line 8"
absent "...and no other line" "m.txt: line 1" "m.txt: line 3" "m.txt: line 9"; rm -rf "$r"
r=$(make_repo); printf 'a' > "$r/n.txt"; ( cd "$r" && git add -A && git commit -qm "chore: base T-921" )
printf 'a\n%s\n' "$ph" > "$r/n.txt"; hook_in "$r"
t24 "a '\\ No newline' line before the hit isn't counted" 1 "  n.txt: line 2"; rm -rf "$r"
r=$(make_repo); printf 'x\n%s' "$ph" > "$r/e.txt"; hook_in "$r"
t24 "a final line with no newline gets its line number" 1 "  e.txt: line 2"; rm -rf "$r"
r=$(make_repo); printf 'a\r\n%s\r\n' "$ph" > "$r/w.txt"; hook_in "$r"
t24 "a CRLF placeholder gets its line number" 1 "  w.txt: line 2"; rm -rf "$r"
r=$(make_repo); printf '%s\n' "$ph" > "$r/p1.txt"; printf 'a\n%s\n' "$ph" > "$r/p2.txt"; hook_in "$r"
t24 "two files each report their own line" 1 "  p1.txt: line 1" "  p2.txt: line 2"
absent "...and neither borrows the other's" "p1.txt: line 2" "p2.txt: line 1"; rm -rf "$r"

# 14) Content is never echoed: canaries in a placeholder line, a secret line and a file
#     name come out as locations or sanitized, never raw.
r=$(make_repo); printf '%s %s %s\n' "$ph" "$vso" "$ghc" > "$r/c.txt"; hook_in "$r"
t24 "a placeholder line with log commands reports only its location" 1 "$php" "  c.txt: line 1"
absent "...and never its content" "T024-canary" "##vso[" "::notice::" "use ["; rm -rf "$r"
r=$(make_repo); printf 'x\nkey=%s %s %s\n' "$aws_key" "$vso" "$ghc" > "$r/s.txt"; hook_in "$r"
t24 "a secret line reports its label and location" 1 "AWS access key ID" "  s.txt: line 2"
absent "...and never the secret or its line" "AKIA" "T024-canary" "##vso[" "::notice::"; rm -rf "$r"
r=$(make_repo); printf '%s\n' "$ph" > "$r/##vso[x]::y.md"; hook_in "$r"
t24 "a file name with log commands is sanitized" 1 "$php" "  ??vso?x???y.md: line 1"
absent "...and never printed raw" "##vso[" "]::y"; rm -rf "$r"
r=$(make_repo); printf 'key=%s\n' "$aws_key" > "$r/##vso[x]::y.md"; hook_in "$r"
t24 "a secret in a file whose name has log commands reports the sanitized name" 1 "AWS access key ID" "  ??vso?x???y.md: line 1"
absent "...and never the raw name or the secret" "##vso[" "]::y" "AKIA"; rm -rf "$r"

# 15) The BLOCK line comes first, then at most 20 locations and a count of the rest.
r=$(make_repo); i=0; : > "$r/k.txt"; while [ "$i" -lt 25 ]; do printf '%s\n' "$ph" >> "$r/k.txt"; i=$((i + 1)); done
hook_in "$r"
n=$(printf '%s\n' "$err" | grep -c '^  k\.txt: line ')
fl=$(printf '%s\n' "$err" | grep -n 'Unreplaced' | cut -d: -f1); ll=$(printf '%s\n' "$err" | grep -n '^  k\.txt: line 1$' | cut -d: -f1)
if [ "$rc" -eq 1 ] && [ "$n" -eq 20 ] && printf '%s\n' "$err" | grep -qx '  ...and 5 more' \
   && printf '%s\n' "$err" | grep -qx '  k.txt: line 20' && [ -n "$fl" ] && [ -n "$ll" ] && [ "$fl" -lt "$ll" ]
then ok "25 hits print the BLOCK line, then exactly 20 locations and '...and 5 more'"
else t24_fail "25 hits print the BLOCK line, then exactly 20 locations and '...and 5 more' (n=$n)"; fi
rm -rf "$r"
r=$(make_repo); printf 'key=%s\n' "$aws_key" > "$r/s.txt"; hook_in "$r"
fl=$(printf '%s\n' "$err" | grep -n 'AWS access key ID' | cut -d: -f1); ll=$(printf '%s\n' "$err" | grep -n '^  s\.txt: line 1$' | cut -d: -f1)
if [ "$rc" -eq 1 ] && [ -n "$fl" ] && [ -n "$ll" ] && [ "$fl" -lt "$ll" ]; then ok "a secret's BLOCK line comes before its location"
else t24_fail "a secret's BLOCK line comes before its location"; fi
rm -rf "$r"

# 16) Type changes are scanned: a file turned into a symlink whose target holds a
#     placeholder or a secret. A gitlink carries no content and passes.
r=$(make_repo); rm "$r/file.txt"; ln -s "$ph" "$r/file.txt"; ( cd "$r" && git add -A )
st=$(cd "$r" && git diff --cached --name-status)
case "$st" in T*) ;; *) bad "symlink precondition: name-status should be T (got: $st)" ;; esac
hook_in "$r"; t24 "a placeholder in a symlink type change blocks" 1 "$php" "  file.txt: line 1"; rm -rf "$r"
r=$(make_repo); rm "$r/file.txt"; ln -s "key=$aws_key" "$r/file.txt"; hook_in "$r"
t24 "a secret in a symlink type change blocks" 1 "AWS access key ID" "  file.txt: line 1"; rm -rf "$r"
# gitlink_repo: make_repo, then stage file.txt as a gitlink with update-index (git add -A
# would stage its removal). Sets $r.
gl=1111111111111111111111111111111111111111
gitlink_repo() {
  r=$(make_repo)
  ( cd "$r" && git rm -q --cached file.txt && rm file.txt && git update-index --add --cacheinfo "160000,$gl,file.txt" )
}
gitlink_repo
( cd "$r" && git diff --cached ) | grep -q '^+Subproject commit' || bad "gitlink precondition: staged diff should show Subproject commit"
err=$( cd "$r" && "$SH" "$sut" 2>&1 >/dev/null ); rc=$?
if [ "$rc" -eq 0 ] && [ -z "$err" ]; then ok "a staged gitlink passes with empty stderr"; else t24_fail "a staged gitlink passes with empty stderr"; fi
rm -rf "$r"

# 17) Git config can't change what's scanned. Each case first proves the setting really
#     changes a plain diff, so it can't pass vacuously.
ESC=$(printf '\033')
r=$(make_repo); printf '%s\n' "$ph" > "$r/p.txt"; ( cd "$r" && git config color.ui always && git add -A )
( cd "$r" && git diff --cached ) | grep -q "$ESC" || bad "color.ui precondition: plain git diff should emit ESC"
hook_in "$r"; t24 "color.ui=always doesn't hide a placeholder" 1 "$php" "  p.txt: line 1"; rm -rf "$r"
r=$(make_repo); printf 'key=%s\n' "$aws_key" > "$r/s.txt"; ( cd "$r" && git config color.ui always && git add -A )
( cd "$r" && git diff --cached ) | grep -q "$ESC" || bad "color.ui precondition (secret): plain git diff should emit ESC"
hook_in "$r"; t24 "color.ui=always doesn't hide a secret" 1 "AWS access key ID" "  s.txt: line 1"; rm -rf "$r"
gitlink_repo; printf '%s\n' "$ph" > "$r/p.txt"; ( cd "$r" && git config diff.submodule log && git add p.txt )
( cd "$r" && git diff --cached ) | grep -q '^Submodule' || bad "diff.submodule precondition: plain git diff should print Submodule"
err=$( cd "$r" && "$SH" "$sut" 2>&1 >/dev/null ); rc=$?
t24 "diff.submodule=log neither breaks the parser nor hides a placeholder" 1 "$php" "  p.txt: line 1"; rm -rf "$r"
r=$(make_repo); mkdir -p "$r/sub"; echo s > "$r/sub/s.txt"; printf '%s\n' "$ph" > "$r/p.txt"; ( cd "$r" && git config diff.relative true && git add -A )
rel=$(cd "$r/sub" && git diff --cached --name-only) || rel='(git failed)'
[ "$rel" = "s.txt" ] || bad "diff.relative precondition: a plain diff from sub/ should list only s.txt (got: $rel)"
hook_in "$r" "$r/sub"; t24 "diff.relative=true run from a subdirectory still scans the whole index" 1 "$php" "  p.txt: line 1"; rm -rf "$r"
r=$(make_repo); printf 'a\n\nb\n' > "$r/z.txt"; ( cd "$r" && git add -A && git commit -qm "chore: base T-922" && git config diff.suppressBlankEmpty true )
printf 'a\n\n%s\n' "$ph" > "$r/z.txt"; ( cd "$r" && git add -A )
( cd "$r" && GIT_DIFF_OPTS=-u3 git diff --cached -U0 ) | grep -q '^ a$' || bad "GIT_DIFF_OPTS precondition: -u3 should override -U0"
( cd "$r" && git diff --cached -U1 ) | grep -qx '' || bad "diff.suppressBlankEmpty precondition: a context diff should print a bare empty line"
hook_in "$r" "" GIT_DIFF_OPTS=-u3
t24 "GIT_DIFF_OPTS and diff.suppressBlankEmpty can't change the diff" 1 "$php" "  z.txt: line 3"; rm -rf "$r"
# All of them at once, on a staged gitlink, a blank context line and a file in sub/,
# run from sub/: a clean change still passes. (No add -A: it would stage the gitlink's removal.)
r=$(make_repo); mkdir -p "$r/sub"; echo s > "$r/sub/s.txt"; printf 'a\n\nb\n' > "$r/z.txt"
( cd "$r" && git add -A && git commit -qm "chore: base T-923" \
    && git rm -q --cached file.txt && rm file.txt && git update-index --add --cacheinfo "160000,$gl,file.txt" )
printf 'a\n\nc\n' > "$r/z.txt"; echo t >> "$r/sub/s.txt"
( cd "$r" && git add sub/s.txt z.txt && git config color.ui always && git config diff.relative true \
    && git config diff.submodule log && git config diff.suppressBlankEmpty true )
( cd "$r" && git diff --cached ) | grep -q '^Submodule' || bad "all-configs precondition: the index should hold a gitlink"
err=$( cd "$r/sub" && GIT_DIFF_OPTS=-u3 "$SH" "$sut" 2>&1 >/dev/null ); rc=$?
if [ "$rc" -eq 0 ] && [ -z "$err" ]; then ok "...and a clean change still passes under all of them, run from sub/"; else t24_fail "...and a clean change still passes under all of them, run from sub/"; fi
rm -rf "$r"

# 17b) Git's own warnings carry the repo's bytes (a .gitattributes attribute name, a
#      .gitmodules submodule name): a passing run must print none of them.
gitlink_repo
printf '[submodule "%s"]\n\tpath = -x\n\turl = ./x\n' "$vso" > "$r/.gitmodules"
printf 'x.txt %s\n* %s[2J\n' "$vso" "$ESC" > "$r/.gitattributes"
( cd "$r" && git add .gitmodules .gitattributes 2>/dev/null )
gw=$(cd "$r" && git diff --cached 2>&1 >/dev/null)
case "$gw" in *"##vso["*) ;; *) bad "git-warning precondition: a plain git diff should warn with ##vso[" ;; esac
err=$( cd "$r" && "$SH" "$sut" 2>&1 >/dev/null ); rc=$?
t24 "git's warnings about .gitattributes and .gitmodules never reach the terminal" 0
absent "...no canary, ##vso[ or ESC" "T024-canary" "##vso[" "$ESC"; rm -rf "$r"

# 18) Fail closed in the new code; the location pass can't change a decision.
r=$(make_repo); printf '%s\n' "$ph" > "$r/p.txt"; hook_stub "$r" tr '-c*'
t24 "a sanitizer (tr) error fails closed" 1 "Sanitizing a file name failed"; [ -e "$tmp/hit" ] || bad "tr stub was reached"; rm -rf "$r"
r=$(make_repo); n201=$(rep n 197).txt; printf 'x\n' > "$r/$n201"; hook_stub "$r" cut '-c1-200'
t24 "a sanitizer (cut) error on a 201-byte name fails closed" 1 "Sanitizing a file name failed"; [ -e "$tmp/hit" ] || bad "cut stub was reached"; rm -rf "$r"
r=$(make_repo); printf '%s\n' "$ph" > "$r/p.txt"; hook_stub "$r" grep '*-E -- ^*'
if [ "$rc" -eq 1 ] && printf '%s' "$err" | grep -qF "$php" && [ -e "$tmp/hit" ]; then ok "a failing location pass still blocks the placeholder"
else t24_fail "a failing location pass still blocks the placeholder"; fi
rm -rf "$r"
r=$(make_repo); printf 'key=%s\n' "$aws_key" > "$r/s.txt"; hook_stub "$r" grep '*-E -- ^*'
if [ "$rc" -eq 1 ] && printf '%s' "$err" | grep -qF "Possible secret in staged content: AWS access key ID" && [ -e "$tmp/hit" ]
then ok "a failing secret location pass still blocks, with its label"; else t24_fail "a failing secret location pass still blocks, with its label"; fi
absent "...and still never prints the secret" "AKIA"; rm -rf "$r"
r=$(make_repo); printf '%s\n' "$ph" > "$r/p.txt"; hook_stub "$r" git 'rev-parse --show-toplevel'
t24 "a rev-parse --show-toplevel error fails closed" 1 "Finding the top of the work tree failed"; [ -e "$tmp/hit" ] || bad "git stub was reached"; rm -rf "$r"

# 19) The INDEX warning names every INDEX path, sanitized and comma-joined.
r=$(make_repo); mkdir -p "$r/##vso[x]/tasks" "$r/tasks"; echo row > "$r/##vso[x]/tasks/INDEX.md"; echo row > "$r/tasks/INDEX.md"
hook_in "$r"
t24 "the INDEX warning sanitizes and joins its paths" 0 "??vso?x?/tasks/INDEX.md, tasks/INDEX.md is regenerated from per-task frontmatter"
absent "...and never prints a raw name" "##vso["; rm -rf "$r"

echo
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
