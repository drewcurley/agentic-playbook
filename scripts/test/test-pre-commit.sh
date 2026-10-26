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
# Exit: 0 all pass, 1 any failure.

set -u

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
playbook_src=$(CDPATH='' cd -- "$test_dir/../.." && pwd)
sut="${PRE_COMMIT_HOOK:-$playbook_src/.githooks/pre-commit}"
case "$sut" in /*) ;; *) sut="$PWD/$sut" ;; esac

# Ignore the runner's own git config (hooksPath, default branch, signing).
GIT_CONFIG_GLOBAL=/dev/null
GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM

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
  err=$( cd "$1" && sh "$sut" 2>&1 >/dev/null ); rc=$?
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
err=$( cd "$r" && PATH="$r/.stub:$PATH" sh "$sut" 2>&1 >/dev/null ); rc=$?
if [ "$rc" -eq 1 ] && printf '%s' "$err" | grep -qF "Secret scanner error"; then ok "grep error fails closed"
else bad "grep error fails closed (rc=$rc, stderr: $err)"; fi
rm -rf "$r"

# 5) Commit on a protected branch blocks.
r=$(make_repo)
( cd "$r" && git checkout -q main )
expect_block "$r" "clean line" "Direct commit to 'main'" "commit on main blocks"
rm -rf "$r"

echo
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
