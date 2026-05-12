#!/usr/bin/env bash
# claude-guardrails: UserPromptSubmit hook
# Injects critical-rules.md at the top of every user prompt.
# Always exits 0 (fail-open) — never blocks Claude Code on hook errors.

set -u

# Disable switch — set CLAUDE_RULES_DISABLE=1 to suppress injection.
if [ "${CLAUDE_RULES_DISABLE:-0}" = "1" ]; then
  exit 0
fi

# Resolution order:
#   1. CLAUDE_RULES_PATH env var
#   2. ~/.claude/critical-rules.path file (contains a path)
#   3. ~/.claude/critical-rules.md (default install location)
P="${CLAUDE_RULES_PATH:-}"
if [ -z "$P" ] && [ -r "$HOME/.claude/critical-rules.path" ]; then
  P="$(head -n 1 "$HOME/.claude/critical-rules.path" 2>/dev/null || true)"
fi
P="${P:-$HOME/.claude/critical-rules.md}"

[ -r "$P" ] || exit 0

printf 'UserPromptSubmit hook: claude-guardrails injecting critical-rules\n\n<critical-rules>\n'
cat "$P"
printf '\n</critical-rules>\n'
exit 0
