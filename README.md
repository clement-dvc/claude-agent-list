# claude-agent-list

A team of 13 Claude Code subagents, each defined in `.claude/agents/`. Every
definition sets its model and effort, its tool permissions, what it may modify
(enforced by hooks), a role-specific workflow, quality and safety rules, an
escalation trigger, a structured output contract, and a turn limit. Each
description is written to trigger automatic delegation.

The agents are stack-agnostic. They discover build, test, and lint commands from
the repository they run in: `CLAUDE.md`, package manifests, and CI config.

## Agents

| Agent | Model / effort | Edits | Max turns | Escalate to |
| --- | --- | --- | --- | --- |
| `lead-orchestrator` | opus / medium | anything (main session) | 200 | opus high/xhigh; fable after failure or eval gap |
| `coder` | opus / medium | code + tests | 100 | opus high; `debugger` |
| `fast-coder` | sonnet / high | named files + tests | 40 | `coder` / opus high |
| `code-reviewer` | sonnet / high | none (read-only) | 30 | opus high; `security-reviewer` |
| `security-reviewer` | opus / high | none (read-only) | 50 | fable high |
| `architect` | opus / high | specs, plans, ADRs only | 40 | fable high |
| `explorer` | sonnet / medium | none (read-only) | 30 | opus medium |
| `test-engineer` | sonnet / high | test files only | 50 | opus high |
| `test-runner-log-analyst` | haiku / medium | none (read-only) | 15 | sonnet high; `debugger` |
| `debugger` | opus / high | minimal fix + regression test | 75 | fable high |
| `documentation-writer` | sonnet / medium | documentation files only | 30 | opus medium/high |
| `router-triage` | haiku / low | none (no shell) | 10 | sonnet medium |
| `merge-integrator` | opus / high | conflict resolution + integration glue | 80 | fable high |

The six agents in the original subagent table were merged with their matching
roles: code-reviewer with Code reviewer, test-engineer with Test author,
explorer with Explorer/researcher, security-reviewer with Security reviewer,
documentation-writer with Documentation agent, and test-runner-log-analyst with
Test runner/log analyst. Where the two tables differed, the subagent table's
name and effort were kept.

Models use aliases (`opus`, `sonnet`, `haiku`), so they track the latest version
of each model.

## Escalation

A subagent file can name only one model. When a subagent hits its escalation
trigger, it stops and returns `status: escalate` with
`escalation.recommended: <model>/<effort>` and its partial findings. The lead
then re-dispatches the same agent with the Agent tool's `model` and `effort`
parameters, which override the frontmatter.

## Modification restrictions (hooks)

Prompt rules are advisory, so the restrictions are enforced with `PreToolUse`
hooks in `.claude/hooks/`:

| Hook | Used by | Blocks |
| --- | --- | --- |
| `readonly-bash.sh` | code-reviewer, security-reviewer, explorer, test-runner-log-analyst, documentation-writer, architect | file mutation, redirects to files, git state changes, package installs, HTTP writes, `gh`/`glab` writes, infrastructure changes |
| `guard-git.sh` | coder, fast-coder, test-engineer, debugger, merge-integrator | push, `reset --hard`, `clean -f`, rebase or history rewrite, `--amend`, ref deletion, discarding the working tree, publishing |
| `restrict-paths.sh tests` | test-engineer | Edit/Write outside test files, fixtures, and helpers |
| `restrict-paths.sh docs` | documentation-writer | Edit/Write outside documentation files |
| `restrict-paths.sh plans` | architect | Edit/Write outside specs, plans, and ADRs |

These hooks are needed because `disallowedTools: Bash(git push *)` would remove
the **whole** Bash tool, not just that command.

Notes:

- Project hooks run only after you trust the folder.
- The hooks need `bash`, plus `jq` or `python3`. Without either, they match
  against the raw JSON input.
- The scripts must stay executable (`chmod +x .claude/hooks/*.sh`).
- The hooks are pattern-based guardrails, not a sandbox. For stronger
  isolation, combine them with `/sandbox` or permission rules.

## Usage

- Specialists are delegated to automatically based on their descriptions. You
  can also name one directly: "use the security-reviewer agent on this diff".
- Run the orchestrator as the main session with
  `claude --agent lead-orchestrator`, or set `"agent": "lead-orchestrator"` in
  `.claude/settings.json`. Its `Agent(...)` allowlist only takes effect when it
  runs as the main thread.
- Non-lead agents have `Agent` disallowed, so delegation stays one level deep
  and the lead controls cost.

## Research basis

- [Create custom subagents](https://code.claude.com/docs/en/sub-agents): the
  frontmatter fields, the "use proactively" phrasing for descriptions, and the
  facts that hooks are scoped per agent, `--agent` sets the main thread, and a
  `disallowedTools` entry with a specifier removes the whole tool.
- [Model configuration](https://code.claude.com/docs/en/model-config): model
  aliases and which effort levels each model supports.
- [Best practices](https://code.claude.com/docs/en/best-practices):
  explore, then plan, then code; give agents a way to verify their work; use
  an adversarial review in a fresh context; ask reviewers to flag only gaps
  that affect correctness, to avoid over-engineering.
- [Code Review](https://code.claude.com/docs/en/code-review): parallel
  specialist finders, a verification pass to filter false positives,
  severity ranking, and separating pre-existing issues.
