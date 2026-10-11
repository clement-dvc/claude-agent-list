#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash) for read-only subagents.
# Blocks shell commands that modify the working tree, git state, installed
# packages, or remote systems. Exit 2 = block; stderr is shown to the agent.
set -u
source "$(dirname "$0")/_read-input.sh"

cmd=$(read_tool_field "$(cat)" command)
[ -z "$cmd" ] && exit 0

block() {
  echo "Blocked by read-only policy: $1. This agent must not modify files, git state, dependencies, or remote systems. Report the change as a recommendation instead." >&2
  exit 2
}

# Normalise whitespace so patterns match across line continuations.
c=$(printf '%s' "$cmd" | tr '\n\t' '  ')

# File system mutation.
printf '%s' "$c" | grep -Eq '(^|[;&|(` ]|\$\()(rm|rmdir|mv|cp|ln|mkdir|touch|truncate|shred|dd|chmod|chown|chgrp|install|unlink|patch|tee)( |$)' \
  && block "file-system mutation command"
printf '%s' "$c" | grep -Eq '(sed|perl|ruby) [^|;&]*-i' && block "in-place edit"

# Output redirection to anything except /dev/null or the standard streams.
targets=$(printf '%s' "$c" | grep -oE '(^|[^=<-])[0-9&]?>>?[[:space:]]*[^&[:space:]][^[:space:];|&)]*' \
  | sed -E 's/^.?[0-9&]?>>?[[:space:]]*//')
while IFS= read -r t; do
  [ -z "$t" ] && continue
  case "$t" in
    /dev/null|/dev/stdout|/dev/stderr|\&*) ;;
    *) block "output redirection to '$t'" ;;
  esac
done <<< "$targets"

# Git state changes (reads such as status/diff/log/show/blame/grep stay allowed).
printf '%s' "$c" | grep -Eq '(^|[;&|( ])git( -C [^ ]+)? (add|commit|push|pull|fetch|merge|rebase|reset|revert|restore|checkout|switch|stash|clean|cherry-pick|am|apply|tag|branch -[dDmM]|worktree|submodule|rm|mv|config|gc|prune|update-ref|filter-branch|replace)( |$)' \
  && block "git state change"

# Dependency installation and publishing.
printf '%s' "$c" | grep -Eq '(npm|pnpm|yarn|bun) (i|install|add|remove|uninstall|publish|update|upgrade|link)( |$)|pip3? install|poetry (add|remove|install|update|publish)|uv (add|remove|pip install|sync)|cargo (install|add|remove|publish)|go (get|install)|gem install|bundle (install|update)|composer (require|install|update)|brew install|apt(-get)? install|dnf install|yum install' \
  && block "dependency install or publish"

# Remote side effects.
printf '%s' "$c" | grep -Eiq 'curl [^|;&]*(-X ?(POST|PUT|PATCH|DELETE)|--data|-d |--upload-file|-T )|wget [^|;&]*--post' \
  && block "HTTP request with side effects"
printf '%s' "$c" | grep -Eq '(^|[;&|( ])(gh|glab) (pr|issue|release|repo|api) [^|;&]*(create|merge|close|edit|comment|delete|review|-X|--method)' \
  && block "hosting-platform write"
printf '%s' "$c" | grep -Eq '(^|[;&|( ])(kubectl (apply|delete|create|patch|edit|scale|rollout)|terraform (apply|destroy|import)|docker (rm|rmi|push|system prune)|helm (install|upgrade|uninstall))( |$)' \
  && block "infrastructure change"

exit 0
