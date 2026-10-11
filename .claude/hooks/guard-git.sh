#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash) for subagents that may edit code.
# Allows normal local work but blocks publishing and history-destroying
# operations; those decisions belong to the lead or the user.
# Exit 2 = block; stderr is shown to the agent.
set -u
source "$(dirname "$0")/_read-input.sh"

cmd=$(read_tool_field "$(cat)" command)
[ -z "$cmd" ] && exit 0
c=$(printf '%s' "$cmd" | tr '\n\t' '  ')

block() {
  echo "Blocked by subagent git policy: $1. Leave this to the lead agent or the user and note it in your report." >&2
  exit 2
}

printf '%s' "$c" | grep -Eq 'git( -C [^ ]+)? push' && block "git push"
printf '%s' "$c" | grep -Eq 'git( -C [^ ]+)? reset [^;&|]*--hard' && block "git reset --hard"
printf '%s' "$c" | grep -Eq 'git( -C [^ ]+)? clean [^;&|]*-[a-zA-Z]*f' && block "git clean -f"
printf '%s' "$c" | grep -Eq 'git( -C [^ ]+)? (rebase|filter-branch|filter-repo|replace|update-ref)( |$)' && block "history rewrite"
printf '%s' "$c" | grep -Eq 'git( -C [^ ]+)? commit [^;&|]*--amend' && block "commit --amend"
printf '%s' "$c" | grep -Eq 'git( -C [^ ]+)? (branch -D|tag -d|push --delete)' && block "ref deletion"
printf '%s' "$c" | grep -Eq 'git( -C [^ ]+)? (checkout|restore) [^;&|]*(-- \.|--force|-f( |$))' && block "discarding working-tree changes"
printf '%s' "$c" | grep -Eq '(^|[;&|( ])rm -[a-zA-Z]*r[a-zA-Z]*f? +(/|~|\.|\*)( |$)' && block "recursive delete of a root, home, or working directory"
printf '%s' "$c" | grep -Eq '(npm|pnpm|yarn|cargo|poetry|twine|gem) publish|(gh|glab) (pr|release) (create|merge)' && block "publishing"

exit 0
