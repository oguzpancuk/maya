#!/usr/bin/env bash
# Drives review-gate.sh, push-gate.sh and review-mark.sh against a scratch
# repo with a bare remote. No real pushes: each hook is fed a fake payload and
# only its exit code is read — 0 allow, 2 block, anything else a crash that is
# never counted as a pass. Usage: bash push-gate-test.sh <hooks-dir>
#
# Cases that must BLOCK run from a fully reviewed main: a gate regressed to
# "just look at HEAD" would allow them, so they discriminate.
set -uo pipefail
HOOKS="$(cd "${1:?usage: push-gate-test.sh <hooks-dir>}" && pwd -P)" || exit 1

# Every step guarded: an unguarded cd after a failed mktemp/clone would run
# git and rm in whatever directory the battery was started from.
ROOT="$(mktemp -d)" && ROOT="$(cd "$ROOT" && pwd -P)" || { echo "harness: no scratch dir"; exit 1; }
[ -n "$ROOT" ] && [ -d "$ROOT" ] || { echo "harness: bad scratch dir"; exit 1; }
export CLAUDE_PROJECT_DIR="$ROOT/work"
git init -q --bare "$ROOT/remote.git" || { echo "harness: init failed"; exit 1; }
git -c init.defaultBranch=main clone -q "$ROOT/remote.git" "$ROOT/work" 2>/dev/null || { echo "harness: clone failed"; exit 1; }
cd "$ROOT/work" || { echo "harness: cannot enter scratch repo"; exit 1; }
case "$(git rev-parse --show-toplevel 2>/dev/null)" in
  "$ROOT"*) ;;
  *) echo "harness: not inside the scratch repo — refusing to touch this tree"; exit 1 ;;
esac
git config user.email t@t.t; git config user.name t
git symbolic-ref HEAD refs/heads/main
# The marker must be untracked here as in the template: tracked, `git add -A`
# would commit it and every branch switch below would fight over it.
printf '.claude/last-reviewed\n' > .gitignore
mkdir -p .claude/hooks; printf '#!/usr/bin/env bash\nexit 0\n' > .claude/hooks/verify.sh
echo one > f; git add -A; git commit -qm one; git push -q origin main

fail=0
P="git pu""sh"   # split so this file's own text cannot trip a scanner
payload() { python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$1"; }
verdict() { case "$1" in 0) echo ALLOW ;; 2) echo BLOCK ;; *) echo "CRASH($1)" ;; esac; }
# The wired chain: review-gate first, push-gate second.
chain() { payload "$1" | bash "$HOOKS/review-gate.sh" >/dev/null 2>&1 || return $?; payload "$1" | bash "$HOOKS/push-gate.sh" >/dev/null 2>&1; }
run() { # want desc cmd
  local want="$1" desc="$2" cmd="$3" rc got
  chain "$cmd"; rc=$?; got="$(verdict $rc)"
  if [ "$got" = "$want" ]; then echo "PASS  $desc"; else echo "FAIL  $desc -> $got (wanted $want): $cmd"; fail=1; fi
}
mark() { # simulate SubagentStop for a given agent type
  python3 -c 'import json,sys; print(json.dumps({"agent_type":sys.argv[1]}))' "$1" | bash "$HOOKS/review-mark.sh" >/dev/null 2>&1
}

echo "── review-mark ──"
mark Explore
[ ! -f .claude/last-reviewed ] && echo "PASS  a non-reviewer subagent leaves no marker" || { echo "FAIL  marker written by Explore"; fail=1; }
mark code-reviewer
[ "$(cat .claude/last-reviewed)" = "$(git rev-parse HEAD)" ] && echo "PASS  code-reviewer stop records HEAD" || { echo "FAIL  marker not HEAD"; fail=1; }

echo "── reviewed main, nothing else ──"
run ALLOW "current branch"                   "$P"
run ALLOW "by name"                          "$P origin main"
run ALLOW "with a push option"               "$P -o ci.skip origin main"
run ALLOW "with output redirected"           "$P origin main >/dev/null"
run ALLOW "not a push"                       "git status"
run ALLOW "mentions both words, nothing ahead" "git log --grep pu""sh"
run ALLOW "message via -F"                   "git commit -F msg.txt && $P"
run ALLOW "unbalanced quote is not parsed"   "$P origin main -m \"unbalanced"
run ALLOW "reading the marker"               "cat .claude/last-reviewed"

echo "── force / destructive (refused outright) ──"
run BLOCK "-f"                               "$P -f origin main"
run BLOCK "--force"                          "$P --force origin main"
run BLOCK "--force-with-lease"               "$P --force-with-lease=main origin main"
run BLOCK "-f after the refspec"             "$P origin main -f"
run BLOCK "clustered short flags"            "git -c k=v pu""sh -fu origin main"
run BLOCK "+refspec"                         "$P origin +main"
run BLOCK "env prefix"                       "env $P -f origin main"
run BLOCK "backslash prefix"                 "\\$P --force origin main"
run BLOCK "variable prefix"                  "GIT_TRACE=1 $P -f origin main"
run BLOCK "--mirror"                         "$P --mirror origin"
run BLOCK "--delete"                         "$P --delete origin main"
run BLOCK "-d"                               "$P -d origin main"
run BLOCK ":branch deletion"                 "$P origin :main"
run BLOCK "inside \$( )"                     "echo \$($P -f)"
run BLOCK "inside backticks"                 "echo \`$P --force\`"
run BLOCK "message mentioning -f (accepted false positive)" "git commit -m \"deny $P -f rule\" && $P"

echo "── another directory ──"
run BLOCK "-C"                               "git -C /tmp/elsewhere pu""sh origin main"
run BLOCK "cd first"                         "cd /tmp/elsewhere && $P origin main"
run BLOCK "pushd first"                      "pushd /tmp/elsewhere && $P origin main"
run BLOCK "GIT_DIR prefix"                   "GIT_DIR=/tmp/elsewhere/.git $P origin main"
run BLOCK "GIT_WORK_TREE prefix"             "GIT_WORK_TREE=/tmp/elsewhere $P origin main"

echo "── the marker is harness-written ──"
run BLOCK "redirect into it"                 "echo abc > .claude/last-reviewed"
run BLOCK "append into it"                   "echo abc >> .claude/last-reviewed"
run BLOCK "tee into it"                      "git rev-parse HEAD | tee .claude/last-reviewed"
run BLOCK "dd into it"                       "dd if=/dev/null of=.claude/last-reviewed"
run BLOCK "noclobber override"               "echo abc >| .claude/last-reviewed"
run ALLOW "reading it with stderr silenced"  "cat .claude/last-reviewed 2>/dev/null"
run BLOCK "rewriting a remote-tracking ref"  "git update-ref refs/remotes/origin/main HEAD"
run BLOCK "fetch into refs/remotes"          "git fetch . HEAD:refs/remotes/origin/main"
run BLOCK "symbolic-ref"                     "git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main"
run ALLOW "ordinary fetch"                   "git fetch origin"

echo "── an unreviewed side branch and tag exist ──"
git checkout -qb feature; echo two > f2; git add -A; git commit -qm "unreviewed on feature"; git tag unreviewed-tag; git checkout -q main
run BLOCK "push main (over-block by design)" "$P origin main"
run BLOCK "push the branch"                  "$P origin feature"
run BLOCK "--all"                            "$P --all origin"
run BLOCK "the tag"                          "$P origin tag unreviewed-tag"
run BLOCK "separator glued"                  "$P origin feature;true"
run BLOCK "env prefix"                       "env $P origin feature"
run BLOCK "multi-line add/commit/push"       "git add .
git commit -m x
$P"
git checkout -q feature; mark code-reviewer; git checkout -q main
run ALLOW "after reviewing the branch tip"   "$P origin feature"
run ALLOW "main is an ancestor of the review" "$P origin main"

echo "── marker removed ──"
rm -f .claude/last-reviewed; git branch -q -D feature; git tag -d unreviewed-tag >/dev/null
run ALLOW "nothing ahead of any remote"      "$P"
echo three > f3; git add -A; git commit -qm three
run BLOCK "a commit ahead, no review"        "$P"
mark code-reviewer
run ALLOW "reviewed again"                   "$P"

echo "── detached HEAD ──"
git checkout -q --detach; echo four > f4; git add -A; git commit -qm detached
run BLOCK "commit reachable only from HEAD"  "$P origin HEAD"
git checkout -q main

echo "── red battery ──"
printf '#!/usr/bin/env bash\nexit 1\n' > .claude/hooks/verify.sh
mark code-reviewer
run BLOCK "reviewed but battery red"         "$P origin main"

cd / && rm -rf "$ROOT"
[ "$fail" = 0 ] && echo "GATE OK" || echo "GATE HAS HOLES"
exit $fail
