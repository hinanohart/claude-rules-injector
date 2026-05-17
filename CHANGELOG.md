# Changelog

All notable changes to this project are documented here. Format loosely follows [Keep a Changelog](https://keepachangelog.com/) and the project follows semver.

## [v0.2.2] — 2026-05-17

### Changed
- **R14 title**: `Pre-large-work discussion protocol` → `Pre-large-work possibility-exploration protocol`. Author confirmed (2026-05-17) that the width of possibility exploration outranks debate.
- **R14 4-step procedure**: `2–3 agent discussion` → **3 sub-agent parallel possibility-exploration** (axes: A=recent sources, B=robust-classic, C=implementation-evidence) + 1 independent `critic` round. Sources are no longer fixed to papers — chosen per-task across papers / GitHub / web / general search with no fixed priority.
- **R14 triggers**: added `large or long-running tasks in general` to extend beyond the OSS-publish-centric framing.
- **R14 author-original**: appended a 2026-05-17 quote block per the do-not-modify principle (additive only — existing quotes untouched).

### Rationale
The previous `2–3 agent discussion` framing acted as an internal mental rehearsal; in practice the agent did not spawn parallel sub-agents and merely thought-out-loud. The new wording forces three parallel `document-specialist`-class sub-agents that scan papers / GitHub / web / general search with task-fit-optimal source selection, followed by an independent `critic` agent for multi-angle verification. Width of exploration replaces depth of debate as the core value. OSS-publish-only star-tier + distribution-format simulation remains as an additive condition, not the primary trigger.

### Compatibility
- Rule ID `R14` unchanged.
- Triggers are additive (existing triggers preserved).
- Author-original lines are additive (existing lines untouched).
- No breaking changes to hook script or skill.

## [v0.2.1] — 2026-05-13

### Changed
- **R17 title**: `Write-target thorough check + root-fix discipline` → `Write-target thorough check + existing-fix-first`. The previous "-discipline" framing acted as a retrieval anchor and biased Claude toward full rewrites for minor issues.
- **R17 operational line**: prepended a default-existing-fix line above the other `→` lines, neutralizing pull from the title and the `REWRITE` verdict label.
- **R14 operational line**: prepended `Existing assets first. 0→1 / full new-build only when triggers fire. For existing OSS / existing systems, combine with R17 "existing-fix first".` Author-original "Linux-grade 0→1 ambition" was mutually reinforcing R17's runaway-rewrite tendency.

### Rationale
Three-agent verification confirmed the title token (Japanese 主義 / "-discipline" / "-ism") functioned as a strong retrieval anchor that overrode the 2026-05-13 supplement clarifying "existing-fix first, root-fix only when impossible." Author-original lines remain untouched per R16 do-not-modify rule. Operational-text drift fix only — no behavioral re-interpretation.

## [v0.2.0] — 2026-05-13

### Added
- **Claude Code plugin support.** The repo is now a self-hosted single-plugin marketplace. Install with `/plugin marketplace add hinanohart/claude-rules-injector` + `/plugin install claude-rules-injector@claude-rules-injector`.
  - `.claude-plugin/plugin.json` — plugin manifest (v0.2.0, MIT, author, homepage).
  - `.claude-plugin/marketplace.json` — marketplace catalog with one plugin entry.
  - `hooks/hooks.json` — plugin-format hook registration. Uses `${CLAUDE_PLUGIN_ROOT}` to locate the hook script and rules file, so the same script works in both plugin and manual install modes.
- Skill auto-namespaces to `/claude-rules-injector:r-check` under the plugin.

### Changed
- **Repo renamed:** `claude-guardrails` → `claude-rules-injector`. GitHub auto-redirects the old URL; existing clones continue to work.
- README documents both install paths (plugin and manual) and the legacy redirect notice.
- `install.sh` and `hooks/inject-rules.sh` self-identify as `claude-rules-injector` in comments and uninstall messages.

### Notes
- The Anthropic official marketplace (`claude-plugins-official`) requires manual submission via [claude.ai/settings/plugins/submit](https://claude.ai/settings/plugins/submit) — not automatable.
- Existing manual installations are unaffected; `install.sh` and `--uninstall` behavior unchanged.

## [v0.1.0] — 2026-05-13

Initial public release. Two post-publish audit cycles applied before tagging.

### Added
- `critical-rules.md` — 13-rule example set (R1, R2, R5, R7, R8, R11, R12, R13, R14, R15, R16, R17, R18) with verbatim Japanese author quotes + English paraphrase + operational line.
- `hooks/inject-rules.sh` — UserPromptSubmit hook. Fail-open (always exits 0). 256 KiB cap. Strips YAML frontmatter on injection.
- `skills/r-check/` — on-demand rule lookup skill (`SKILL.md` + `check.sh`). Strict `R<digits>` ID validation.
- `install.sh` — idempotent installer + `--uninstall`. jq with python3 fallback. Per-hook dedup so sibling hooks survive re-install. Preserves user-edited `critical-rules.md` on uninstall as `.bak.<ts>`.
- `README.md`, `LICENSE` (MIT), `.gitignore`.
- `.github/workflows/shellcheck.yml` — CI runs `shellcheck` against all `.sh` files on push/PR. Catches regressions in the hook and installer.

### Audit-fix history baked into v0.1.0
- **First pass** (commit `4708a83`): fixed placeholder URL in README, broken `--uninstall` xargs no-op, hook prompt-pollution debug line, jq sibling-hook loss, `cp -n` race, SKILL.md verb-driven description, hook size cap, python3 fallback malformed-JSON handling, backup hygiene (`umask 077` + retain-3), `$CLAUDE_DIR` reference in SKILL.md.
- **Second pass** (commit `d1d4c06`): dropped half-wired `CLAUDE_DIR` knob, fixed `check.sh R18` Appendix leak, README's inaccurate uninstall + "at the top" claims, silent `remove_hook_py` swallow on malformed JSON, BSD `date +%s%N` literal-N bug, awk regex injection in `check.sh`, remaining GNU-only `xargs -r` for backup pruning, YAML frontmatter waste in hook output, accidental wipe of user-edited `critical-rules.md` on uninstall, CRLF passthrough in `critical-rules.path`. Added Status disclaimer + Known limitations to README.

### Known limitations
- Not yet packaged as a Claude Code plugin. Migration is on the roadmap.
- Name "claude-guardrails" is industry-overloaded; this package shapes behavior, not permissions. See README §Non-goals. (Resolved in v0.2.0 by renaming to `claude-rules-injector`.)
