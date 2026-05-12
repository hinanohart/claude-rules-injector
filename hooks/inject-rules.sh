#!/usr/bin/env bash
# claude-rules-injector: UserPromptSubmit hook
# Injects critical-rules.md as additionalContext on every user prompt.
# Always exits 0 (fail-open) — never blocks Claude Code on hook errors.

set -u

if [ "${CLAUDE_RULES_DISABLE:-0}" = "1" ]; then
  exit 0
fi

# Path resolution:
#   1. CLAUDE_RULES_PATH env var
#   2. ~/.claude/critical-rules.path file (first line)
#   3. ~/.claude/critical-rules.md (default install location)
# NOTE: keep in sync with skills/r-check/check.sh
P="${CLAUDE_RULES_PATH:-}"
if [ -z "$P" ] && [ -r "$HOME/.claude/critical-rules.path" ]; then
  # tr strips CR so a Windows-edited path file still works.
  P="$(head -n 1 "$HOME/.claude/critical-rules.path" 2>/dev/null | tr -d '\r' || true)"
fi
P="${P:-$HOME/.claude/critical-rules.md}"

[ -f "$P" ] && [ -r "$P" ] || exit 0

# 256 KiB cap: typical rule files are ~15 KiB. Bounds context-cost if
# CLAUDE_RULES_PATH is misconfigured (e.g. points at /etc/passwd or a log).
# awk forces numeric conversion so BSD wc's leading-space output is tolerated.
SZ="$(wc -c < "$P" 2>/dev/null | awk '{print $1+0}')"
[ "${SZ:-0}" -le 262144 ] || exit 0

# Strip YAML frontmatter (first `---`-delimited block) — it's memory-system
# metadata, not rule content, and re-injecting it wastes ~150 B per turn.
printf '<critical-rules>\n'
awk '
  NR==1 && $0=="---" { fm=1; next }
  fm && $0=="---"    { fm=0; next }
  !fm
' "$P"
printf '\n</critical-rules>\n'
exit 0
