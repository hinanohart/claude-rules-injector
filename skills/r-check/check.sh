#!/usr/bin/env bash
# r-check: print one rule section from critical-rules.md
# Usage: check.sh R11

set -u

ID="${1:-}"
if [ -z "$ID" ]; then
  echo "Usage: check.sh <rule-id>   e.g. check.sh R11" >&2
  exit 2
fi

# Normalize: accept r11 / R11 / 11
ID="$(printf '%s' "$ID" | tr '[:lower:]' '[:upper:]')"
case "$ID" in
  R*) ;;
  [0-9]*) ID="R$ID" ;;
  *) echo "[err] not a rule id: $1" >&2; exit 2 ;;
esac

# Path resolution (same as hook)
P="${CLAUDE_RULES_PATH:-}"
if [ -z "$P" ] && [ -r "$HOME/.claude/critical-rules.path" ]; then
  P="$(head -n 1 "$HOME/.claude/critical-rules.path" 2>/dev/null || true)"
fi
P="${P:-$HOME/.claude/critical-rules.md}"

if [ ! -r "$P" ]; then
  echo "[err] rules file not readable: $P" >&2
  exit 1
fi

# Extract from "## <ID> " to the next "## " heading.
awk -v id="$ID" '
  $0 ~ "^## "id"( |$)" { found=1; print; next }
  found && /^## R[0-9]+( |$)/ { exit }
  found { print }
  END { if (!found) exit 3 }
' "$P"

rc=$?
if [ $rc -eq 3 ]; then
  echo "[err] rule $ID not found in $P" >&2
  exit 3
fi
