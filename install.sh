#!/usr/bin/env bash
# claude-guardrails installer
# Idempotent: safe to run multiple times. Creates timestamped backups before modifying settings.json.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
TS="$(date +%s)"

mkdir -p "$CLAUDE_DIR" "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/skills/r-check"

# 1. Place critical-rules.md
cp "$REPO_DIR/critical-rules.md" "$CLAUDE_DIR/critical-rules.md"
echo "[ok] copied critical-rules.md -> $CLAUDE_DIR/critical-rules.md"

# 2. Place hook (executable)
cp "$REPO_DIR/hooks/inject-rules.sh" "$CLAUDE_DIR/hooks/inject-rules.sh"
chmod +x "$CLAUDE_DIR/hooks/inject-rules.sh"
echo "[ok] installed hook -> $CLAUDE_DIR/hooks/inject-rules.sh"

# 3. Place skill (file-by-file copy, idempotent on re-install)
cp "$REPO_DIR/skills/r-check/SKILL.md" "$CLAUDE_DIR/skills/r-check/SKILL.md"
cp "$REPO_DIR/skills/r-check/check.sh"  "$CLAUDE_DIR/skills/r-check/check.sh"
chmod +x "$CLAUDE_DIR/skills/r-check/check.sh"
echo "[ok] installed skill -> $CLAUDE_DIR/skills/r-check"

# 4. Register hook in settings.json (idempotent)
HOOK_CMD="$CLAUDE_DIR/hooks/inject-rules.sh"

if [ -f "$SETTINGS" ]; then
  cp -n "$SETTINGS" "$SETTINGS.bak.$TS" || true
  echo "[ok] backup -> $SETTINGS.bak.$TS"
fi

merge_settings() {
  if command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)"
    if [ -f "$SETTINGS" ]; then
      jq --arg cmd "$HOOK_CMD" '
        .hooks //= {} |
        .hooks.UserPromptSubmit //= [] |
        .hooks.UserPromptSubmit |= (
          (map(select(.hooks[]?.command? != $cmd))) +
          [{matcher: "", hooks: [{type: "command", command: $cmd}]}]
        )
      ' "$SETTINGS" > "$tmp"
    else
      jq -n --arg cmd "$HOOK_CMD" '{hooks: {UserPromptSubmit: [{matcher: "", hooks: [{type: "command", command: $cmd}]}]}}' > "$tmp"
    fi
    mv "$tmp" "$SETTINGS"
    echo "[ok] settings.json updated via jq"
    return 0
  fi
  return 1
}

merge_settings_py() {
  python3 - "$SETTINGS" "$HOOK_CMD" <<'PYEOF'
import json, sys, os
path, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except json.JSONDecodeError:
        data = {}
data.setdefault("hooks", {})
ups = data["hooks"].setdefault("UserPromptSubmit", [])
new_ups = []
for entry in ups:
    hooks = entry.get("hooks", []) if isinstance(entry, dict) else []
    if not any(isinstance(h, dict) and h.get("command") == cmd for h in hooks):
        new_ups.append(entry)
new_ups.append({"matcher": "", "hooks": [{"type": "command", "command": cmd}]})
data["hooks"]["UserPromptSubmit"] = new_ups
with open(path, "w") as f:
    json.dump(data, f, indent=2)
PYEOF
  echo "[ok] settings.json updated via python3"
}

if ! merge_settings; then
  if command -v python3 >/dev/null 2>&1; then
    merge_settings_py
  else
    echo "[err] neither jq nor python3 found. Please install one or edit $SETTINGS manually:" >&2
    echo "  Add to .hooks.UserPromptSubmit: {\"matcher\":\"\",\"hooks\":[{\"type\":\"command\",\"command\":\"$HOOK_CMD\"}]}" >&2
    exit 1
  fi
fi

echo ""
echo "Done. Restart Claude Code to activate the hook."
echo "Disable temporarily:  export CLAUDE_RULES_DISABLE=1"
echo "Use a custom path:    export CLAUDE_RULES_PATH=/path/to/rules.md"
echo "Uninstall:            see README.md"
