# CLAUDE.md

Base working principles for every project and every agent. Add project-specific
rules (commands, conventions, architecture) below them.

These principles favour caution over speed. For trivial changes, such as a typo
or an obvious one-liner, use judgment.

## 1. Think before coding

Don't assume. Don't hide confusion. Surface tradeoffs.

- State your assumptions before you act. If you are unsure, ask.
- If a request can be read more than one way, lay out the readings. Don't pick
  one silently.
- If a simpler approach exists, say so, and push back when it's warranted.
- If something is unclear, stop, name exactly what is unclear, and ask.

> *"Add a feature to export user data."* Wrong: export every user, as CSV, with
> all fields, to a file. Right: first ask which users, which format, which
> fields (some may be sensitive), and where the export goes.

## 2. Simplicity first

Write the minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for code used only once.
- No flexibility or configurability that nobody requested.
- No error handling for scenarios that cannot happen.
- If 200 lines could be 50, rewrite them.

The test: would a senior engineer call this overcomplicated? If yes, simplify.

> *"Add a function to calculate a discount."* Wrong: a strategy interface,
> discount classes, and a config object. Right: one function that takes an
> amount and a percentage. Add discount types when a second type is actually
> needed.

## 3. Surgical changes

Touch only what you must. Clean up only your own mess.

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor what isn't broken.
- Match the existing style, even if you would do it differently.
- Mention unrelated dead code or bugs. Don't delete or fix them.
- Remove the imports, variables, and functions that *your* change made unused.
  Leave pre-existing dead code alone unless asked.

The test: every changed line traces directly to the request.

> *"Fix the crash on empty emails."* Wrong: the fix, plus new username
> validation, reworded comments, added docstrings, and requoted strings. Right:
> only the lines that handle the empty email.

## 4. Goal-driven execution

Define success criteria. Loop until they are verified.

Turn tasks into verifiable goals:

| Instead of | Do |
| --- | --- |
| "Add validation" | Write tests for invalid inputs, then make them pass. |
| "Fix the bug" | Write a test that reproduces it, then make it pass. |
| "Refactor X" | Make sure the tests pass before and after. |

For multi-step work, state a brief plan:

```
1. [step] -> verify: [check]
2. [step] -> verify: [check]
```

> *"Sorting breaks with duplicate scores."* Wrong: change the sort right away.
> Right: write a test with duplicate scores and watch it fail, switch to a
> stable sort with a tiebreaker, then run the test repeatedly and confirm it
> passes every time.

Strong criteria let you work independently. Weak criteria ("make it work") need
constant clarification.

---

These principles are working when diffs contain no unrelated changes, code
rarely needs rewriting for being overcomplicated, and clarifying questions come
before implementation rather than after mistakes.
