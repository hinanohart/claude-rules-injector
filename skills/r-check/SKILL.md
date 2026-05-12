---
name: r-check
description: Look up a single critical rule by its ID (R1, R2, R5, R7, R8, R11, R12, R13, R14, R15, R16, R17, R18). Use this when the user references a rule ID, when you suspect a rule violation, or when you need to recall the exact wording of a rule before acting.
---

# r-check — rule lookup

This skill returns the full text of one rule from `critical-rules.md`.

## When to invoke
- User mentions an R-rule by number (e.g. "check R11", "is this R17?").
- You're about to do something the rules might prohibit and want to verify the exact wording.
- Before writing operational text (`→` lines) for an R-rule per R16 (declare-understanding obligation).

## How to invoke
Run `check.sh <rule-id>`:

```bash
bash $CLAUDE_DIR/skills/r-check/check.sh R11
```

Argument: a rule ID like `R11`, `R14`, `R17`. Output: the full rule section from `critical-rules.md`.

## Rules in scope
R1, R2, R5, R7, R8, R11, R12, R13, R14, R15, R16, R17, R18.
(R0, R3, R4, R6, R9, R10 are intentional gaps — locale-/personal-specific or not OSS-relevant.)
