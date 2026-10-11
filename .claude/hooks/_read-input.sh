#!/usr/bin/env bash
# Shared helper for subagent PreToolUse hooks.
# Usage: field=$(read_tool_field "$INPUT" command|file_path|notebook_path)
# Prefers jq, falls back to python3, then to the raw JSON so a hook never
# silently passes because a parser is missing.

read_tool_field() {
  local input="$1" field="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r --arg f "$field" '.tool_input[$f] // empty'
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$input" | python3 -I -c 'import json,sys
d=json.load(sys.stdin).get("tool_input",{})
print(d.get(sys.argv[1]) or "")' "$field"
  else
    printf '%s' "$input"
  fi
}
