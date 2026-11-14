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
#   <base-sha>  merge-base / target-branch tip (range start, exclusive), or the
#               empty-tree SHA (`git hash-object -t tree /dev/null`) for a root
#               commit: then everything reachable from <head-sha> is checked.
#               scripts/ci-base.sh picks this for push builds.
#   <head-sha>  tip being validated (range end)
# Exit:    0 all checks pass, 1 any failure. Prints findings to stderr.
#
# Mirrors: .githooks/pre-commit (placeholders, secrets) + .githooks/commit-msg
#          (task ID, /docs consensus). Keep the three in sync.
#
# Keep this ONE self-contained file (no sourcing siblings): PR builds extract just
# this file from the target branch and run it (scripts/ci-pr-checks.sh, starter T-014).
# CI_PLACEHOLDER_ALLOW=<file> replaces ./.placeholder-allow (ci-pr-checks.sh passes
# the target branch's copy, so a PR can't allowlist itself); set but empty or
# missing means nothing is allowlisted.

set -u
# Bytes, not characters: BSD sed/grep stop on invalid UTF-8, which binary content
# in a --text diff is (starter T-014).
LC_ALL=C; export LC_ALL
# A scan's input must not depend on the caller's environment or git config
# (starter T-024): GIT_DIFF_OPTS overrides -U0, diff.relative narrows a diff to the
# current directory, diff.suppressBlankEmpty and diff.submodule=log change line
# shapes, and color.ui=always prefixes every line with ESC. Every diff pins these.
unset GIT_DIFF_OPTS

base="${1:?usage: ci-checks.sh <base-sha> <head-sha>}"
head="${2:?usage: ci-checks.sh <base-sha> <head-sha>}"

fail=0
err() { printf 'CI-CHECK FAIL: %s\n' "$*" >&2; fail=1; }
# die: an input every gate reads is unknown, so no gate's result can be trusted.
# Call it from the top-level shell only, never inside $( ) or a pipeline: those are
# subshells, and exit there would not stop this script.
die() { printf 'CI-CHECK FAIL: %s Failing closed: the gates could not all run.\n' "$*" >&2; exit 1; }

# Run from the top of the work tree (starter T-024): file names come out top-relative,
# so a per-file pathspec read from a subdirectory would match nothing and pass. A
# relative CI_PLACEHOLDER_ALLOW is made absolute first, so it still names the same file.
case "${CI_PLACEHOLDER_ALLOW-}" in
  ''|/*) ;;
  *) CI_PLACEHOLDER_ALLOW="$PWD/$CI_PLACEHOLDER_ALLOW" ;;
esac
top=$(git rev-parse --show-toplevel 2>/dev/null) || die "Finding the top of the work tree failed."
cd "$top" || die "Changing to the top of the work tree failed."

# Fail closed on git errors (starter T-013). Each git call is captured on its own and its
# status checked: in `git diff | grep ... || true` the status is grep's, so a git
# error used to read as an empty diff and pass every gate. Filters use sed or awk,
# which exit 0 on no match, so no `|| true` is needed to hide grep's exit 1.
# A path git still quotes ("docs/a\tb.md") counts too, so quoting can't dodge the gate.
authored_docs() { sed -n '/^"\{0,1\}docs\/repos\//d;/^"\{0,1\}docs\//p'; }

# BEGIN safe-echo (starter T-024). Byte-identical in scripts/ci-checks.sh and
# .githooks/pre-commit; scripts/test/test-ci-wiring.sh compares the two copies.
# Logs must never carry bytes a PR controls: Azure DevOps runs `##vso[...]` found
# anywhere in a line, GitHub Actions runs `::cmd::` at the start of one, and a
# terminal runs escape sequences. So file names and commit subjects are printed only
# through se_safe, and scan hits only as "path: line N", never their content.
# Every name here starts with se_ so the block can't clobber its caller's variables.
# Git's own stderr is discarded on every git call (2>/dev/null): a PR's .gitattributes
# or .gitmodules makes git warn with the PR's bytes in the message. Each failure
# prints fixed text of its own instead.

# se_added: read `git diff -U0` output on stdin; print "<new line number><TAB><content>"
# for every added line. Unlike a `/^+++/d` filter it can't drop an added line whose
# content starts with "++". Exits 2 on any line it doesn't recognise (fail closed).
se_added() {
  LC_ALL=C awk '
    /^diff --git / { st = 1; next }
    st == 0 { if ($0 != "") exit 2; next }
    st == 1 && substr($0, 1, 3) != "@@ " { next }
    substr($0, 1, 3) == "@@ " {
      if ($3 !~ /^[+][0-9]+(,[0-9]+)?$/) exit 2
      split($3, p, ","); n = substr(p[1], 2) + 0; st = 2; next
    }
    {
      c = substr($0, 1, 1)
      if (c == "+") { print n "\t" substr($0, 2); n++ }
      else if (c == " ") n++
      else if (c == "\\") { if ($0 != "\\ No newline at end of file") exit 2 }
      else if (c != "-") exit 2
    }'
}

# se_safe <text>: print <text> on one line with every byte outside [A-Za-z0-9._/ -]
# replaced by "?", cut to 200 bytes plus "..." if longer. Non-zero if a step failed.
se_safe() {
  se_s=$(printf '%s' "$1" | LC_ALL=C tr -c 'A-Za-z0-9._/ -' '?') || return 1
  if [ "${#se_s}" -gt 200 ]; then
    se_s=$(printf '%s' "$se_s" | LC_ALL=C cut -c1-200) || return 1
    se_s="$se_s..."
  fi
  printf '%s\n' "$se_s"
}

# se_lines <ERE>: read se_added output on stdin; print the line number of each added
# line whose content matches <ERE>. Returns grep's status (0 hit, 1 none, >1 error).
# <ERE> is matched after "N<TAB>.*", so it must not be anchored with ^ and must not
# use back-references: such a pattern would still block, but print no location.
se_lines() {
  se_tab=$(printf '\t')
  se_m=$(LC_ALL=C grep -E -- "^[0-9]+${se_tab}.*($1)") || return $?
  printf '%s\n' "$se_m" | cut -f1
}

# se_where <safe path>: read line numbers on stdin; print "  <path>: line N" for up
# to 20 of them, then "  ...and N more". <safe path> must come from se_safe.
se_where() {
  LC_ALL=C awk -v p="$1" 'NR <= 20 { print "  " p ": line " $0 } END { if (NR > 20) print "  ...and " NR - 20 " more" }'
}
# END safe-echo

# BEGIN task-ready (starter T-023). Byte-identical in scripts/ci-checks.sh and
# .githooks/pre-commit; scripts/test/test-ci-wiring.sh compares the two copies.
# The definition of ready (tasks/README.md#definition-of-ready), checked on one task
# file at a time. The block reads only its arguments and stdin, defines only tr_ names,
# never calls the caller's die/err/fail, and checks every status itself: callers run
# it inside || where set -e does nothing. Its output carries only fixed text, line
# numbers and the path through se_safe (from the safe-echo block above), never the
# file's content. One POSIX awk pass reads the file; the path never reaches awk.
#
# tr_name <path>: 0 a task file, 1 a bad name that looks like one, 3 not a task file.
# tr_need <status> <path> <root:0|1>: print 1 if a new file must carry the marker.
# tr_marker: read a task file on stdin; 0 it has spec_format:, 1 it hasn't, 2 error.
# tr_check <path> <marker_required:0|1> <base_marker:0|1|-> <mode>: read the task
#   file on stdin; print findings and return 1, return 0 when ready, 2 on an error.
tr_codes='SPEC_FRONTMATTER SPEC_UNCLOSED SPEC_BAD_NAME SPEC_NOT_A_FILE SPEC_OPEN_QUESTION SPEC_UNANSWERED SPEC_MISSING_SECTION SPEC_EMPTY_SECTION SPEC_PLACEHOLDER_AC SPEC_DUPLICATE_SECTION SPEC_VERSION_UNKNOWN SPEC_HEADING SPEC_MARKER_MISSING SPEC_MARKER_REMOVED'

tr_name() {
  tr_pa=$1
  case "$tr_pa" in
    .starter/tasks/T-*.md) tr_nm=${tr_pa#.starter/tasks/T-} ;;
    tasks/T-*.md) tr_nm=${tr_pa#tasks/T-} ;;
    *) tr_nm=/ ;;
  esac
  tr_nm=${tr_nm%.md}
  case "$tr_nm" in
    ''|.*|*.|*..*|*[!0-9.]*) ;;
    *) return 0 ;;
  esac
  tr_nm=${tr_pa#\"}
  case "$tr_nm" in [.][Ss][Tt][Aa][Rr][Tt][Ee][Rr]/*) tr_nm=${tr_nm#?????????} ;; esac
  case "$tr_nm" in [Tt][Aa][Ss][Kk][Ss]/[Tt]-*) return 1 ;; esac
  # A changed entry that IS a ledger folder (a symlink or file in its place) would hide
  # every task file behind it, so it is a bad name too.
  case "$tr_pa" in [Tt][Aa][Ss][Kk][Ss]|[.][Ss][Tt][Aa][Rr][Tt][Ee][Rr]|[.][Ss][Tt][Aa][Rr][Tt][Ee][Rr]/[Tt][Aa][Ss][Kk][Ss]) return 1 ;; esac
  return 3
}

tr_need() {
  case "$1:$2:$3" in
    A:tasks/*:0) echo 1 ;;
    *) echo 0 ;;
  esac
}

# tr_awk: the one pass. Prints CODE<TAB>line<TAB>section lines (line 0: no line;
# section 0: none, else 1-6 in the order of tr_sec), then one MARKER<TAB>0|1 line.
tr_awk() {
  LC_ALL=C awk '
    function out(c, l, s) { print c "\t" l "\t" s }
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    function val(s) { sub(/[ \t]+#.*$/, "", s); return trim(s) }
    function answered(s,   r, p, q, h, t, w, src, who) {
      if (s ~ /Deferred to T-[0-9]+([.][0-9]+)*: [ \t]*[^ \t]/) return 1
      r = s
      while ((p = index(r, "Answer (")) > 0) {
        r = substr(r, p + 8); q = index(r, ")")
        if (!q) return 0
        h = substr(r, 1, q - 1); t = substr(r, q + 1)
        if (t ~ /^: .*[A-Za-z0-9\200-\377]/ && substr(h, 1, 10) ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ && substr(h, 11, 2) == ", ") {
          w = substr(h, 13); src = ""
          for (q = length(w) - 1; q >= 1; q--) if (substr(w, q, 2) == ", ") { src = substr(w, q + 2); who = trim(substr(w, 1, q - 1)); break }
          if (src != "" && who != "" && index(who, "(") == 0 && (src == "in session" || src ~ /^https?:\/\/[^ ,)]+$/)) return 1
        }
      }
      return 0
    }
    function closes(s,   n) {
      sub(/^[ \t]+/, "", s); n = 0
      while (substr(s, n + 1, 1) == fch) n++
      return n >= flen && trim(substr(s, n + 1)) == ""
    }
    function body(line,   t, c, n, vis, rest, p, i, j, lvl, k, nm, low) {
      if (fence) { if (closes(line)) fence = 0; return }
      if (!cmt) {
        t = line; sub(/^[ \t]+/, "", t); c = substr(t, 1, 1)
        if ((c == "`" || c == "~") && substr(t, 1, 3) == c c c) {
          n = 0; while (substr(t, n + 1, 1) == c) n++
          fence = 1; fch = c; flen = n; fline = NR; return
        }
      }
      vis = ""; rest = line
      while (1) {
        if (cmt) { p = index(rest, "-->"); if (!p) { rest = ""; break }; rest = substr(rest, p + 3); cmt = 0 }
        p = index(rest, "<!--"); if (!p) { vis = vis rest; break }
        vis = vis substr(rest, 1, p - 1); rest = substr(rest, p + 4); cmt = 1; cline = NR
      }
      i = 1; while (substr(vis, i, 1) == " ") i++
      j = i; while (substr(vis, j, 1) == "#") j++
      lvl = j - i; c = substr(vis, j, 1)
      if (i <= 4 && lvl >= 1 && lvl <= 6 && (c == "" || c == " " || c == "\t")) {
        nm = trim(substr(vis, j)); sub(/(^|[ \t]+)#+$/, "", nm)
        low = tolower(nm); gsub(/[ \t]+/, " ", low); low = trim(low); k = 0
        for (i = 1; i <= 6; i++) {
          t = substr(low, length(LOW[i]) + 1)
          if (substr(low, 1, length(LOW[i])) == LOW[i] && (t == "" || t ~ /^ ?[(:]/)) { k = i; break }
        }
        if (k) {
          cnt[k]++; if (cnt[k] == 2) dup[k] = NR
          if (line != "## " NAME[k] && ((k == 5 && r2) || r3)) out("SPEC_HEADING", NR, k)
          sec = k; return
        }
        if (lvl <= 2) { sec = 0; return }
      }
      if (!sec) return
      t = trim(vis)
      if (t != "" && t != "\342\200\246" && t != "- \342\200\246") has[sec] = 1
      if (vis !~ /^[ \t]*([-*+]|[0-9]+[.)])[ \t]+\[[^]]*\]/) return
      t = vis; sub(/^[ \t]*([-*+]|[0-9]+[.)])[ \t]+/, "", t)
      p = index(t, "]"); c = substr(t, 1, p); t = substr(t, p + 1)
      if (sec == 2) {
        acn++; sub(/^[ \t]+/, "", t)
        if (substr(t, 1, 7) == "<given>" && !acg) acg = NR
      } else if (sec == 5 && r2) {
        if (c == "[x]" || c == "[X]") { if (!answered(t)) out("SPEC_UNANSWERED", NR, 0) }
        else out("SPEC_OPEN_QUESTION", NR, 0)
      }
    }
    BEGIN {
      split("users and stakeholders|acceptance criteria|non-functional requirements|assumptions|open questions|out of scope", LOW, "|")
      split("Users and stakeholders|Acceptance criteria|Non-functional requirements|Assumptions|Open questions|Out of scope", NAME, "|")
      fm = 0; nst = 0; nsf = 0; cr = 0; marker = 0; ver = ""; vline = 0
      fence = 0; cmt = 0; sec = 0; r2 = 0; r3 = 0; acn = 0; acg = 0
    }
    {
      line = $0
      if (substr(line, length(line), 1) == "\r") {
        if (!cr) out("SPEC_FRONTMATTER", NR, 0)
        cr = 1; line = substr(line, 1, length(line) - 1)
      }
      if (NR == 1) {
        if (line == "---") { fm = 1; next }
        out("SPEC_FRONTMATTER", 1, 0); fm = 3
      } else if (fm == 1) {
        if (line == "---") {
          fm = 2
          if (!nst) out("SPEC_FRONTMATTER", NR, 0)
          r2 = (st == "in-review" || st == "in-progress" || st == "completed")
          r3 = r2 && marker && ver == "1"
          next
        }
        t = line; sub(/^[ \t]+/, "", t); k = tolower(t)
        if (substr(k, 1, 6) == "state:") {
          nst++; v = val(substr(t, 7))
          if (nst > 1 || v !~ /^(proposed|in-review|in-progress|completed|blocked|cancelled)$/) out("SPEC_FRONTMATTER", NR, 0)
          else st = v
        } else if (substr(k, 1, 12) == "spec_format:") {
          nsf++; marker = 1
          if (nsf > 1) out("SPEC_FRONTMATTER", NR, 0)
          else { ver = val(substr(t, 13)); vline = NR }
        }
        next
      }
      body(line)
    }
    END {
      if (fm == 0 || fm == 1) out("SPEC_FRONTMATTER", 1, 0)
      if (marker && ver != "1") out("SPEC_VERSION_UNKNOWN", vline, 0)
      if (fence) out("SPEC_UNCLOSED", fline, 0)
      if (cmt) out("SPEC_UNCLOSED", cline, 0)
      if (r3) {
        for (k = 1; k <= 6; k++) {
          if (!cnt[k]) { out("SPEC_MISSING_SECTION", 0, k); continue }
          if (!has[k]) out("SPEC_EMPTY_SECTION", 0, k)
          if (cnt[k] > 1) out("SPEC_DUPLICATE_SECTION", dup[k], k)
        }
        if (cnt[2] && !acn) out("SPEC_PLACEHOLDER_AC", 0, 2)
        else if (acg) out("SPEC_PLACEHOLDER_AC", acg, 2)
      }
      print "MARKER\t" marker
    }'
}

tr_sec() {
  case "$1" in
    1) echo 'Users and stakeholders' ;; 2) echo 'Acceptance criteria' ;;
    3) echo 'Non-functional requirements' ;; 4) echo 'Assumptions' ;;
    5) echo 'Open questions' ;; 6) echo 'Out of scope' ;; *) echo '' ;;
  esac
}

# tr_why <code> <section name>: the reason, then the Fix line. Fixed text only.
tr_why() {
  case "$1" in
    SPEC_FRONTMATTER) echo 'the frontmatter cannot be read'
      echo 'Fix: make line 1 exactly ---, close the frontmatter with ---, and give exactly one state: line (proposed, in-review, in-progress, completed, blocked or cancelled, in lowercase) and at most one spec_format: line. Save the file as UTF-8 with LF line endings and no BOM.' ;;
    SPEC_UNCLOSED) echo 'a comment or fence opens here and never closes, so it would hide the rest of the file'
      echo 'Fix: close the comment with --> or the fence with a line of the same backticks or tildes, at least as many.' ;;
    SPEC_BAD_NAME) echo 'this looks like a task file but is not named like one'
      echo 'Fix: name it tasks/T-<n>.md or tasks/T-<n>.<n>.md (digits, a lowercase .md, nothing below tasks/T-<n>/). Move notes out of tasks/.' ;;
    SPEC_NOT_A_FILE) echo 'a task file must be a regular file'
      echo 'Fix: commit it as a plain file, not a symlink, submodule or conflicted entry.' ;;
    SPEC_OPEN_QUESTION) echo 'an open question: a task is not ready while one is open'
      echo 'Fix: ask the requester, then write their answer on the line: - [x] <question> - Answer (YYYY-MM-DD, <who>, in session or <comment link>): <answer>. Already answered? Change [ ] to [x] and add the Answer part. Deferring it? Write - [x] <question> - Deferred to T-<n>: <why>. While you wait, keep state: proposed before plan review, or set state: blocked once review has started.' ;;
    SPEC_UNANSWERED) echo 'a checked question with no answer and no deferral'
      echo 'Fix: on the same line after the box, write Answer (YYYY-MM-DD, <who>, <source>): <answer>, where <source> is in session or an https:// link, or write Deferred to T-<n>: <why>. Common slips: the Answer header on the next line, a missing source, a date not in YYYY-MM-DD form, parentheses in the name (write Jane, PM, not Jane (PM)), or no answer text after ): on the same line.' ;;
    SPEC_MISSING_SECTION) echo 'a required section is missing'
      echo "Fix: add the heading ## $2 with at least one line under it. None. or n/a - <reason> is fine." ;;
    SPEC_EMPTY_SECTION) echo 'a required section has nothing in it'
      echo "Fix: write at least one line under ## $2. None. or n/a - <reason> is fine; the template's placeholder line is not." ;;
    SPEC_PLACEHOLDER_AC) echo 'no acceptance criterion is written yet'
      echo 'Fix: write each criterion as a checkbox item, - [ ] <testable outcome>, and delete the template line that starts with <given>.' ;;
    SPEC_DUPLICATE_SECTION) echo 'a required section appears twice'
      echo "Fix: merge the two ## $2 sections into one." ;;
    SPEC_VERSION_UNKNOWN) echo 'this check knows no such spec_format version'
      echo 'Fix: set spec_format: 1.' ;;
    SPEC_HEADING) echo 'this heading nearly matches a required section'
      echo "Fix: write the heading exactly as: ## $2 (no trailing spaces or comment on the line)" ;;
    SPEC_MARKER_MISSING) echo 'a new task file without spec_format: 1'
      echo 'Fix: add the line spec_format: 1 to the frontmatter (copy tasks/_TEMPLATE.md). A moved or renamed task counts as new.' ;;
    SPEC_MARKER_REMOVED) echo 'the spec_format: line was removed'
      echo 'Fix: put the spec_format: 1 line back. A task that has opted in stays in.' ;;
    *) return 1 ;;
  esac
}

# tr_add <code> <line> <section>: append one finding to tr_out_f; count it in tr_k.
# A code's full Fix prints once per file; repeats say "same as above" (tr_done).
tr_add() {
  tr_sn=$(tr_sec "$3") || return 1
  tr_w=$(tr_why "$1" "$tr_sn") || return 1
  if [ "$2" != 0 ]; then tr_loc=": line $2"; elif [ -n "$tr_sn" ]; then tr_loc=": $tr_sn"; else tr_loc=''; fi
  tr_fx=${tr_w#*
}
  case " $tr_done " in
    *" $1 "*) case "$1" in SPEC_MISSING_SECTION|SPEC_EMPTY_SECTION|SPEC_DUPLICATE_SECTION|SPEC_HEADING) ;; *) tr_fx='Fix: same as above.' ;; esac ;;
    *) tr_done="$tr_done $1" ;;
  esac
  tr_out_f="$tr_out_f  $1 $tr_sp$tr_loc (${tr_w%%
*})
    $tr_fx
"
  tr_k=$((tr_k + 1))
}

# tr_parse <collect:0|1>: validate tr_ao (the awk output); set tr_m to its marker and,
# with collect=1, add each finding. Non-zero on output the block doesn't expect.
tr_parse() {
  tr_tab=$(printf '\t') tr_seen=0 tr_m=''
  while IFS= read -r tr_l; do
    case "$tr_l" in
      "MARKER${tr_tab}0"|"MARKER${tr_tab}1") tr_seen=$((tr_seen + 1)); tr_m=${tr_l#MARKER"$tr_tab"}; continue ;;
    esac
    [ "$tr_seen" -eq 0 ] || return 1
    tr_c=${tr_l%%"$tr_tab"*} tr_r=${tr_l#*"$tr_tab"}
    tr_ln=${tr_r%%"$tr_tab"*} tr_s=${tr_r#*"$tr_tab"}
    case " $tr_codes " in *" $tr_c "*) ;; *) return 1 ;; esac
    case "$tr_c" in SPEC_BAD_NAME|SPEC_NOT_A_FILE|SPEC_MARKER_MISSING|SPEC_MARKER_REMOVED) return 1 ;; esac
    case "$tr_ln" in ''|*[!0-9]*) return 1 ;; esac
    case "$tr_s" in [0-6]) ;; *) return 1 ;; esac
    if [ "$1" = 1 ]; then tr_add "$tr_c" "$tr_ln" "$tr_s" || return 1; fi
  done <<EOF
$tr_ao
EOF
  [ "$tr_seen" -eq 1 ]
}

tr_marker() {
  tr_ao=$(tr_awk) || return 2
  tr_parse 0 || return 2
  [ "$tr_m" = 1 ] && return 0
  return 1
}

# tr_emit: print the summary line, the findings and the pointer to the definition.
tr_emit() {
  if [ "$tr_k" -eq 1 ]; then tr_pl='1 problem'; else tr_pl="$tr_k problems"; fi
  printf 'Task %s is not ready (%s):\n%sSee tasks/README.md#definition-of-ready\n' "$tr_sp" "$tr_pl" "$tr_out_f"
}

tr_check() {
  tr_out_f='' tr_k=0 tr_done=
  tr_sp=$(se_safe "$1") || return 2
  tr_nr=0; tr_name "$1" || tr_nr=$?
  case "$tr_nr" in
    0) ;;
    1) tr_add SPEC_BAD_NAME 0 0 || return 2; tr_emit; return 1 ;;
    *) return 2 ;;
  esac
  case "$4" in
    100644|100755) ;;
    *) tr_add SPEC_NOT_A_FILE 0 0 || return 2; tr_emit; return 1 ;;
  esac
  tr_ao=$(tr_awk) || return 2
  tr_parse 1 || return 2
  if [ "$2" = 1 ] && [ "$tr_m" = 0 ]; then tr_add SPEC_MARKER_MISSING 0 0 || return 2; fi
  if [ "$3" = 1 ] && [ "$tr_m" = 0 ]; then tr_add SPEC_MARKER_REMOVED 0 0 || return 2; fi
  [ "$tr_k" -eq 0 ] && return 0
  tr_emit
  return 1
}
# END task-ready

# Resolve both ends to full SHAs; later calls use only these, so an argument can't
# reach git as an option (one starting with '-' is refused outright).
hint="Shallow checkout (needs fetchDepth: 0 / fetch-depth: 0), or a force-pushed base?"
base_arg=$base head_arg=$head
case "$base_arg" in -*) die "Base '$base_arg' does not resolve to a commit (looks like an option)." ;; esac
case "$head_arg" in -*) die "Head '$head_arg' does not resolve to a commit (looks like an option)." ;; esac
head=$(git rev-parse --verify --quiet "$head_arg^{commit}" 2>/dev/null) \
  || die "Head '$head_arg' does not resolve to a commit. $hint"
empty_tree=$(git hash-object -t tree /dev/null 2>/dev/null) || die "git hash-object failed."
if [ "$base_arg" = "$empty_tree" ]; then
  # Root mode: head has no parent to diff against. Check its whole tree and every
  # commit it reaches, not an empty head...head range that passes unscanned.
  from=$empty_tree
  commit_range=$head
else
  base=$(git rev-parse --verify --quiet "$base_arg^{commit}" 2>/dev/null) \
    || die "Base '$base_arg' does not resolve to a commit. $hint"
  # `git diff A...B` means "diff merge-base(A,B) to B"; resolve it explicitly so a
  # missing merge base is an error, not an empty diff.
  from=$(git merge-base "$base" "$head" 2>/dev/null) \
    || die "No merge base between base $base and head $head. $hint"
  commit_range="$base..$head"
fi

rng="$from..$head"
# --text --no-textconv --no-ext-diff: a .gitattributes entry (-diff, binary, a
# textconv driver), an external diff, or a NUL byte must not turn content into
# "Binary files differ" or anything else the scans can't see (starter T-014).
# --no-renames: a rename shows as delete + add, so the moved content is scanned
# (a rename out of an allowlisted path would otherwise carry its placeholders along).
full_diff=$(git -c diff.relative=false -c diff.suppressBlankEmpty=false diff --no-color --submodule=short --text --no-textconv --no-ext-diff --no-renames "$from" "$head" -U0 2>/dev/null) || die "git diff $rng failed."
# Two captures, so neither status hides the other's. The decisions read content only.
added_n=$(printf '%s\n' "$full_diff" | se_added) || die "Parsing the diff of $rng failed."
added=$(printf '%s\n' "$added_n" | cut -f2-) || die "Filtering the diff of $rng failed."

# --- 1) Unreplaced [insert ... here] placeholders (allowlist-aware) ----------
allow_file="${CI_PLACEHOLDER_ALLOW-.placeholder-allow}"
allowed() {
  [ -f "$allow_file" ] || return 1
  while IFS= read -r pat; do
    case "$pat" in ''|\#*) continue ;; esac
    # shellcheck disable=SC2254  # glob match intended
    case "$1" in $pat) return 0 ;; esac
  done < "$allow_file"
  return 1
}
# Filenames come from the PR. List them unquoted (core.quotePath=false), split on
# newlines only, never glob-expand them (set -f), and read each back as a literal
# path (--literal-pathspecs): otherwise `a b.md`, `AGENT[S].md`, `:(top)x` or
# `café.md` is checked as some other path, or none (starter T-014). Names git still quotes
# (tab, newline, quote, backslash) can't be read back reliably, so they fail.
changed_files=$(git -c core.quotePath=false -c diff.relative=false -c diff.suppressBlankEmpty=false diff --no-color --submodule=short --no-renames --name-only --diff-filter=ACMRT "$from" "$head" 2>/dev/null) \
  || die "git diff --name-only $rng failed."
old_ifs=$IFS
IFS='
'
set -f
for f in $changed_files; do
  # The PR names its files: print them only through se_safe (starter T-024).
  sf=$(se_safe "$f") || die "Sanitizing a file name failed."
  case "$f" in \"*) err "Unusual filename $sf: git quotes it, so its placeholders can't be checked. Rename it."; continue ;; esac
  allowed "$f" && continue
  f_diff=$(git --literal-pathspecs -c diff.relative=false -c diff.suppressBlankEmpty=false diff --no-color --submodule=short --text --no-textconv --no-ext-diff --no-renames "$from" "$head" -U0 -- "$f" 2>/dev/null) \
    || die "git diff $rng -- '$sf' failed."
  f_n=$(printf '%s\n' "$f_diff" | se_added) || die "Parsing the diff of '$sf' failed."
  f_added=$(printf '%s\n' "$f_n" | cut -f2-) || die "Filtering the diff of '$sf' failed."
  ph_rc=0
  printf '%s\n' "$f_added" | grep -qE '\[insert [^]]+ here\]' || ph_rc=$?
  case "$ph_rc" in
    0)
      err "Unreplaced [insert ... here] placeholder in '$sf' (not allowlisted; see .placeholder-allow).${CI_PLACEHOLDER_ALLOW+ The allowlist is read from the target branch, so a new entry must land in an earlier PR.}"
      # Where, never what: the line itself is PR-controlled text. The decision above
      # doesn't depend on this; a failure here only loses the line numbers.
      ph_at=$(printf '%s\n' "$f_n" | se_lines '\[insert [^]]+ here\]') || ph_at=''
      if [ -n "$ph_at" ]; then printf '%s\n' "$ph_at" | se_where "$sf" >&2; fi
      ;;
    1) ;;
    *) err "Placeholder scanner error (grep exit $ph_rc) on '$sf'. Failing closed: file was not scanned." ;;
  esac
done
set +f
IFS=$old_ifs

# --- 2) Basic secret scan ----------------------------------------------------
secret_patterns='AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[ps]_[A-Za-z0-9]{36,}|xox[abprs]-[A-Za-z0-9-]+|sk-[A-Za-z0-9]{20,}|sk-ant-[A-Za-z0-9_-]{20,}'
# `--` guards against a pattern parsed as a grep option; grep exit >=2 is a
# scanner error, not "no match" — fail closed (mirrors scan() in pre-commit).
secret_rc=0
printf '%s\n' "$added" | grep -qE -- "$secret_patterns" || secret_rc=$?
case "$secret_rc" in
  0) err "Possible secret detected in diff. Sanitize before merge." ;;
  1) ;;
  *) err "Secret scanner error (grep exit $secret_rc). Failing closed: diff was not scanned." ;;
esac

# --- 3) Every non-merge commit references a Task ID --------------------------
commits=$(git log --format=%H "$commit_range" 2>/dev/null) || die "git log $commit_range failed."
for sha in $commits; do
  msg=$(git log -1 --format=%B "$sha" 2>/dev/null) || die "git log -1 $sha failed."
  first=$(printf '%s' "$msg" | head -n1)
  case "$first" in
    Merge*|Revert*|fixup!*|squash!*|amend!*) continue ;;
  esac
  if ! printf '%s' "$msg" | grep -qE '\bT-[0-9]+(\.[0-9]+)?\b'; then
    sfirst=$(se_safe "$first") || die "Sanitizing a commit subject failed."
    err "Commit $sha is missing a Task ID (T-NNN). First line: $sfirst"
  fi
done

# --- 4) /docs/* changes require unanimous-consensus assertion ---------------
# Exception: docs/repos/** is a GENERATED mirror (scripts/aggregate-docs.sh) whose
# content was already gated by consensus in its SOURCE repo — re-gating the mirror
# would demand an assertion on every routine rollup refresh. So a commit needs the
# assertion only if it touches authored /docs files OUTSIDE docs/repos/.
all_changed=$(git -c core.quotePath=false -c diff.relative=false -c diff.suppressBlankEmpty=false diff --no-color --submodule=short --no-renames --name-only "$from" "$head" 2>/dev/null) || die "git diff --name-only $rng failed."
docs_changed=$(printf '%s\n' "$all_changed" | authored_docs) || die "Filtering the changed-file list failed."
if [ -n "$docs_changed" ]; then
  for sha in $commits; do
    sha_files=$(git -c core.quotePath=false -c diff.relative=false -c diff.suppressBlankEmpty=false show --no-color --submodule=short --no-renames --name-only --pretty="" "$sha" 2>/dev/null) || die "git show $sha failed."
    files=$(printf '%s\n' "$sha_files" | authored_docs) || die "Filtering the files of $sha failed."
    [ -z "$files" ] && continue
    msg=$(git log -1 --format=%B "$sha" 2>/dev/null) || die "git log -1 $sha failed."
    if ! printf '%s' "$msg" | grep -qiE 'unanimous-consensus:[[:space:]]*T-[0-9]+(\.[0-9]+)?'; then
      err "Commit $sha touches authored /docs/* but is missing 'unanimous-consensus: T-NNN' in the message."
    fi
  done
fi

# --- 5) Task files are ready (starter T-023) ----------------------------------
# Each added or changed task file passes the task-ready block above: frontmatter that
# parses, no open question once in review, the spec sections once marked spec_format: 1.
# Names are gated before any git call; content is read as a literal blob into a
# variable, never through a pipe from git, so a git error fails closed. Runs after
# checks 1-4, so a die here can't hide their findings.
ts_list=$(git -c core.quotePath=false -c diff.relative=false -c diff.suppressBlankEmpty=false diff --no-color --submodule=short --no-renames --name-status --diff-filter=ACMRT "$from" "$head" 2>/dev/null) \
  || die "git diff --name-status $rng failed."
ts_root=0
[ "$from" = "$empty_tree" ] && ts_root=1
ts_tab=$(printf '\t')
ts_n=0 ts_bad=0
old_ifs=$IFS
IFS='
'
set -f
for ts_e in $ts_list; do
  ts_st=${ts_e%%"$ts_tab"*} ts_p=${ts_e#*"$ts_tab"}
  ts_nr=0; tr_name "$ts_p" || ts_nr=$?
  case "$ts_nr" in 0|1) ;; 3) continue ;; *) die "Checking a task file name failed." ;; esac
  ts_sp=$(se_safe "$ts_p") || die "Sanitizing a file name failed."
  ts_mode='' ts_blob='' ts_base=-
  if [ "$ts_nr" -eq 0 ]; then
    ts_ls=$(git --literal-pathspecs ls-tree --full-tree "$head" -- "$ts_p" 2>/dev/null) || die "git ls-tree $head -- '$ts_sp' failed."
    case "$ts_ls" in
      *"
"*) ts_mode=many ;;
      *) ts_mode=${ts_ls%% *} ;;
    esac
    case "$ts_mode" in
      100644|100755)
        ts_blob=$(git cat-file blob "$head:$ts_p" 2>/dev/null) || die "Reading '$ts_sp' at $head failed."
        # The base copy's marker; a base that wasn't a file (a type change from a
        # gitlink) had none.
        ts_bm=''
        case "$ts_st" in M|T) ts_bm=$(git --literal-pathspecs ls-tree --full-tree "$from" -- "$ts_p" 2>/dev/null) || die "git ls-tree $from -- '$ts_sp' failed." ;; esac
        case "$ts_st:$ts_bm" in [MT]:100644\ *|[MT]:100755\ *|[MT]:120000\ *) ;; [MT]:*) ts_st=X ;; esac
        case "$ts_st" in
          M|T)
            ts_old=$(git cat-file blob "$from:$ts_p" 2>/dev/null) || die "Reading '$ts_sp' at $from failed."
            ts_mr=0; printf '%s\n' "$ts_old" | tr_marker || ts_mr=$?
            case "$ts_mr" in 0) ts_base=1 ;; 1) ts_base=0 ;; *) die "Checking the base copy of '$ts_sp' failed." ;; esac
            ;;
        esac
        ;;
    esac
  fi
  ts_need=$(tr_need "$ts_st" "$ts_p" "$ts_root") || die "Checking a task file name failed."
  tr_rc=0; tr_out=$(printf '%s\n' "$ts_blob" | tr_check "$ts_p" "$ts_need" "$ts_base" "$ts_mode") || tr_rc=$?
  case "$tr_rc" in
    0) ts_n=$((ts_n + 1)) ;;
    1) ts_n=$((ts_n + 1)); ts_bad=1; err "$tr_out" ;;
    *) die "Checking task file '$ts_sp' failed." ;;
  esac
done
set +f
IFS=$old_ifs
[ "$ts_bad" -eq 0 ] && echo "task-ready: $ts_n task file(s) checked"

if [ "$fail" -eq 0 ]; then
  echo "ci-checks: all procedure gates passed ($rng)"
fi
exit "$fail"
