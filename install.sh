#!/usr/bin/env bash
# claude-guardrails installer
# Idempotent: safe to run multiple times. Creates timestamped backups before modifying settings.json.
# Usage: bash install.sh             # install / update
#        bash install.sh --uninstall # remove everything this installer added

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Hardcoded — Claude Code reads $HOME/.claude/settings.json. Keeping this
# fixed prevents the half-wired-CLAUDE_DIR-override class of bug where
# install.sh writes somewhere the hook+skill can't read from.
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
# Epoch + PID — portable (BSD `date` lacks %N) and unique across rapid re-installs.
TS="$(date +%s)-$$"
HOOK_CMD="$CLAUDE_DIR/hooks/inject-rules.sh"

prune_old_backups() {
  # Retain the 3 most recent .bak.* files. Array-based to avoid GNU-only `xargs -r`.
  local old=()
  while IFS= read -r f; do old+=("$f"); done < <(ls -1t "$SETTINGS".bak.* 2>/dev/null | tail -n +4)
  [ "${#old[@]}" -gt 0 ] && rm -- "${old[@]}" || true
}

backup_settings() {
  [ -f "$SETTINGS" ] || return 0
  ( umask 077 && cp "$SETTINGS" "$SETTINGS.bak.$TS" )
  echo "[ok] backup -> $SETTINGS.bak.$TS (contains your previous settings.json; delete when no longer needed)"
  prune_old_backups
}

remove_hook_jq() {
  command -v jq >/dev/null 2>&1 || return 1
  [ -f "$SETTINGS" ] || return 0
  tmp="$(mktemp)"
  if ! jq --arg cmd "$HOOK_CMD" '
    if .hooks.UserPromptSubmit == null then . else
      .hooks.UserPromptSubmit |= (
        map(.hooks |= map(select(.command? != $cmd)))
        | map(select((.hooks // []) | length > 0))
      )
    end
  ' "$SETTINGS" > "$tmp"; then
    rm -f "$tmp"
    echo "[err] jq failed to parse $SETTINGS — refusing to overwrite. Fix the file and re-run." >&2
    return 2
  fi
  mv "$tmp" "$SETTINGS"
}

remove_hook_py() {
  command -v python3 >/dev/null 2>&1 || return 1
  [ -f "$SETTINGS" ] || return 0
  python3 - "$SETTINGS" "$HOOK_CMD" <<'PYEOF'
import json, sys
path, cmd = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        data = json.load(f)
except FileNotFoundError:
    sys.exit(0)
except json.JSONDecodeError as e:
    print(f"[err] {path} is not valid JSON ({e}); refusing to overwrite. Fix the file and re-run.", file=sys.stderr)
    sys.exit(1)
ups = data.get("hooks", {}).get("UserPromptSubmit")
if not isinstance(ups, list):
    sys.exit(0)
new_ups = []
for entry in ups:
    if not isinstance(entry, dict):
        new_ups.append(entry); continue
    hooks = [h for h in entry.get("hooks", []) if not (isinstance(h, dict) and h.get("command") == cmd)]
    if hooks:
        entry["hooks"] = hooks
        new_ups.append(entry)
data["hooks"]["UserPromptSubmit"] = new_ups
with open(path, "w") as f:
    json.dump(data, f, indent=2)
PYEOF
}

uninstall_critical_rules_md() {
  # Preserve user edits: if installed file differs from repo version, keep as .bak.
  local target="$CLAUDE_DIR/critical-rules.md"
  [ -f "$target" ] || return 0
  if cmp -s "$REPO_DIR/critical-rules.md" "$target"; then
    rm -f "$target"
  else
    mv "$target" "$target.bak.$TS"
    echo "[warn] $target differed from repo version; preserved as $target.bak.$TS" >&2
  fi
}

if [ "${1:-}" = "--uninstall" ]; then
  echo "Uninstalling claude-guardrails from $CLAUDE_DIR ..."
  backup_settings
  uninstall_critical_rules_md
  rm -f "$CLAUDE_DIR/hooks/inject-rules.sh"
  rm -f "$CLAUDE_DIR/skills/r-check/SKILL.md" "$CLAUDE_DIR/skills/r-check/check.sh"
  rmdir "$CLAUDE_DIR/skills/r-check" 2>/dev/null || true
  if remove_hook_jq; then
    echo "[ok] removed hook entry from $SETTINGS"
  elif remove_hook_py; then
    echo "[ok] removed hook entry from $SETTINGS"
  else
    echo "[warn] neither jq nor python3 found — please remove the inject-rules.sh entry from $SETTINGS manually." >&2
  fi
  echo "Done. Restart Claude Code to deactivate."
  exit 0
fi

mkdir -p "$CLAUDE_DIR" "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/skills/r-check"

cp "$REPO_DIR/critical-rules.md" "$CLAUDE_DIR/critical-rules.md"
echo "[ok] copied critical-rules.md -> $CLAUDE_DIR/critical-rules.md"

cp "$REPO_DIR/hooks/inject-rules.sh" "$CLAUDE_DIR/hooks/inject-rules.sh"
chmod +x "$CLAUDE_DIR/hooks/inject-rules.sh"
echo "[ok] installed hook -> $CLAUDE_DIR/hooks/inject-rules.sh"

cp "$REPO_DIR/skills/r-check/SKILL.md" "$CLAUDE_DIR/skills/r-check/SKILL.md"
cp "$REPO_DIR/skills/r-check/check.sh"  "$CLAUDE_DIR/skills/r-check/check.sh"
chmod +x "$CLAUDE_DIR/skills/r-check/check.sh"
echo "[ok] installed skill -> $CLAUDE_DIR/skills/r-check"

backup_settings

merge_settings_jq() {
  command -v jq >/dev/null 2>&1 || return 1
  tmp="$(mktemp)"
  if [ -f "$SETTINGS" ]; then
    # Dedup at the per-hook level so we never drop sibling hooks that share an entry.
    if ! jq --arg cmd "$HOOK_CMD" '
      .hooks //= {} |
      .hooks.UserPromptSubmit //= [] |
      .hooks.UserPromptSubmit |= (
        (map(.hooks |= map(select(.command? != $cmd))) | map(select((.hooks // []) | length > 0)))
        + [{matcher: "", hooks: [{type: "command", command: $cmd}]}]
      )
    ' "$SETTINGS" > "$tmp"; then
      rm -f "$tmp"
      echo "[err] jq failed to parse $SETTINGS — refusing to overwrite. Fix the file and re-run." >&2
      return 2
    fi
  else
    jq -n --arg cmd "$HOOK_CMD" '{hooks: {UserPromptSubmit: [{matcher: "", hooks: [{type: "command", command: $cmd}]}]}}' > "$tmp"
  fi
  mv "$tmp" "$SETTINGS"
  echo "[ok] settings.json updated via jq"
}

merge_settings_py() {
  command -v python3 >/dev/null 2>&1 || return 1
  python3 - "$SETTINGS" "$HOOK_CMD" <<'PYEOF'
import json, sys, os
path, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"[err] {path} is not valid JSON ({e}); refusing to overwrite. Fix the file and re-run.", file=sys.stderr)
        sys.exit(1)
data.setdefault("hooks", {})
ups = data["hooks"].setdefault("UserPromptSubmit", [])
new_ups = []
for entry in ups:
    if not isinstance(entry, dict): new_ups.append(entry); continue
    entry["hooks"] = [h for h in entry.get("hooks", []) if not (isinstance(h, dict) and h.get("command") == cmd)]
    if entry["hooks"]:
        new_ups.append(entry)
new_ups.append({"matcher": "", "hooks": [{"type": "command", "command": cmd}]})
data["hooks"]["UserPromptSubmit"] = new_ups
with open(path, "w") as f:
    json.dump(data, f, indent=2)
PYEOF
  echo "[ok] settings.json updated via python3"
}

# Try jq first; fall back to python3 if jq is missing OR jq parse-fails on bad JSON.
if ! merge_settings_jq; then
  if ! merge_settings_py; then
    echo "[err] neither jq nor python3 found (or both refused malformed JSON). Install one or edit $SETTINGS manually:" >&2
    echo "  add to .hooks.UserPromptSubmit: {\"matcher\":\"\",\"hooks\":[{\"type\":\"command\",\"command\":\"$HOOK_CMD\"}]}" >&2
    exit 1
  fi
fi

echo ""
echo "Done. Restart Claude Code to activate the hook."
echo "Disable temporarily:  export CLAUDE_RULES_DISABLE=1"
echo "Use a custom path:    export CLAUDE_RULES_PATH=/path/to/rules.md"
echo "Uninstall:            bash install.sh --uninstall"
