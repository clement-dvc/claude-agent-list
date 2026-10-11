#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|NotebookEdit) that limits which files a
# subagent may modify. Usage: restrict-paths.sh <tests|docs|plans>
# Exit 2 = block; stderr is shown to the agent.
set -u
source "$(dirname "$0")/_read-input.sh"

profile="${1:-}"
input=$(cat)
path=$(read_tool_field "$input" file_path)
[ -z "$path" ] && path=$(read_tool_field "$input" notebook_path)
[ -z "$path" ] && exit 0

# Compare paths relative to the project root.
root="${CLAUDE_PROJECT_DIR:-$PWD}"
rel="${path#"$root"/}"
case "$rel" in
  /*|../*|*/../*)
    echo "Blocked: '$path' is outside the project directory." >&2; exit 2 ;;
esac

case "$profile" in
  tests)
    re='(^|/)(tests?|__tests__|__mocks__|specs?|testdata|test-data|fixtures|e2e|integration-tests|testing)/|[._-](test|spec|tests|specs)\.[A-Za-z0-9]+$|_test\.(go|py|exs?|dart)$|(^|/)test_[^/]+\.py$|(^|/)conftest\.py$|Tests?\.(java|kt|cs|swift|scala|php)$|Spec\.(scala|groovy|kt)$'
    what="test files, test fixtures, and test helpers" ;;
  docs)
    re='\.(md|mdx|markdown|rst|adoc|asciidoc|txt)$|(^|/)(docs?|documentation|guides?|runbooks?|adr|adrs)/|(^|/)(README|CHANGELOG|CONTRIBUTING|SECURITY|UPGRADING|MIGRATION|NOTICE)[^/]*$|(^|/)(mkdocs\.ya?ml|docusaurus\.config\.[jt]s|sidebars\.[jt]s)$'
    what="documentation files" ;;
  plans)
    re='(^|/)(docs/)?(adr|adrs|decisions|design|designs|rfcs?|specs?|plans?)/[^/]+\.(md|mdx|rst|adoc)$|(^|/)(SPEC|PLAN|DESIGN)[^/]*\.md$'
    what="specs, plans, and architecture decision records" ;;
  *)
    echo "restrict-paths.sh: unknown profile '$profile'" >&2; exit 2 ;;
esac

if printf '%s' "$rel" | grep -Eq "$re"; then
  exit 0
fi
echo "Blocked: this agent may only modify $what. '$rel' is outside that scope. Report the needed change instead of making it." >&2
exit 2
