---
name: r-check
description: Use when the user references an R-rule by ID (R1, R2, R5, R7, R8, R11, R12, R13, R14, R15, R16, R17, R18), when you suspect a rule violation, or when you need the exact wording of a rule before writing operational text. Returns the full text of one rule from critical-rules.md.
---

# r-check — rule lookup

This skill returns the full text of one rule from `critical-rules.md`.

## When to invoke
- User mentions an R-rule by number (e.g. "check R11", "is this R17?").
- You're about to do something the rules might prohibit and want to verify the exact wording.
- Before writing operational text (`→` lines) for an R-rule per R16 (declare-understanding obligation).

## How to invoke
Run `check.sh <rule-id>`. The path depends on install mode:

```bash
# Plugin install (via /plugin install):
"${CLAUDE_PLUGIN_ROOT}/skills/r-check/check.sh" R11

# Manual install (via install.sh):
~/.claude/skills/r-check/check.sh R11
```

Argument: a rule ID like `R11`, `R14`, `R17`. Output: the full rule section from `critical-rules.md`.

## Exit codes
| Code | Meaning |
|---|---|
| 0 | rule found, printed to stdout |
| 1 | rules file not readable (path resolution failed) |
| 2 | invalid rule ID argument |
| 3 | rule ID valid but section not found |

## Rules in scope
R1, R2, R5, R7, R8, R11, R12, R13, R14, R15, R16, R17, R18.
(R0, R3, R4, R6, R9, R10 are intentional gaps — locale-/personal-specific or not OSS-relevant.)
