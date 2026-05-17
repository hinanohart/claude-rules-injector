# claude-rules-injector

> Auto-inject a "critical rules" prompt at the start of every turn in Claude Code, plus a `r-check` skill for on-demand rule lookup.

> _Previously named `claude-guardrails`. Old URLs redirect; clone URLs still work via GitHub's auto-redirect._

`claude-rules-injector` is a tiny, auditable layer on top of Claude Code that solves one problem: **rules you write in `CLAUDE.md` are advisory — they may lose salience as the session grows.** This package wires the same rules into a `UserPromptSubmit` hook, so they are re-attached as additionalContext on every prompt. Violations short-circuit the task instead of leaking through.

It is opinionated: 13 rules, English summaries with Japanese author-original quotes preserved verbatim per R16. Fork it, edit `critical-rules.md`, and reinstall — the wiring is the value, the rules are an example.

> **Status:** Personal config dump, MIT-licensed for forking. The author uses this for their own workflow; no SLA, support guarantee, or roadmap. Issues and PRs are welcome but may be answered slowly or not at all. The bundled `critical-rules.md` is an example — replace with your own rules before relying on it.

## Install

### Option A — Plugin (recommended, Claude Code v2.x+)

Inside Claude Code:

```text
/plugin marketplace add hinanohart/claude-rules-injector
/plugin install claude-rules-injector@claude-rules-injector
/reload-plugins
```

The plugin bundles `critical-rules.md`, the hook, and the `r-check` skill (namespaced as `/claude-rules-injector:r-check`). Updates flow via the marketplace; no manual `settings.json` edits.

### Option B — Manual install (legacy / for older Claude Code)

```bash
git clone https://github.com/hinanohart/claude-rules-injector.git
cd claude-rules-injector
bash install.sh
```

The installer:
- copies `critical-rules.md` to `~/.claude/critical-rules.md`
- installs the hook at `~/.claude/hooks/inject-rules.sh`
- installs the `r-check` skill at `~/.claude/skills/r-check/`
- registers the hook in `~/.claude/settings.json` (idempotent; creates `.bak.<epoch>-<pid>` backup before any edit)

Restart Claude Code after install. To confirm it works, send any prompt — the rules are re-attached as additionalContext on every turn.

## Disable / customize

| Goal | How |
|---|---|
| Temporarily disable injection | `export CLAUDE_RULES_DISABLE=1` |
| Use your own rules file | `export CLAUDE_RULES_PATH=/path/to/rules.md` |
| Pin a path persistently | `echo /path/to/rules.md > ~/.claude/critical-rules.path` |
| Look up one rule | invoke the `r-check` skill or run `~/.claude/skills/r-check/check.sh R11` |

## Uninstall

### Plugin install:
```text
/plugin uninstall claude-rules-injector@claude-rules-injector
```

### Manual install:
```bash
bash install.sh --uninstall
```

The manual uninstaller writes a fresh `settings.json.bak.<epoch>-<pid>`, then edits `settings.json` in place to remove only the `claude-rules-injector` hook entry (sibling hooks are preserved). It removes the hook script and the skill. If `$HOME/.claude/critical-rules.md` was modified after install, it is preserved as `critical-rules.md.bak.<epoch>-<pid>` instead of being deleted.

## What's in the rules

13 rules across three priority tiers. Lines prefixed with `🔥` reproduce the original Japanese wording verbatim and should not be reworded (see R16); each is followed by an English paraphrase and an operational line.

| Tier | Rules | What they cover |
|---|---|---|
| **1 (immediate stop)** | R11, R13, R15 | Secret handling, security isolation, cross-session contamination |
| **1.5 (special protocol)** | R14, R16, R17 | Pre-large-work possibility-exploration, 100% intent comprehension, write-target audit |
| **2 (auto-progress)** | R1, R2, R5, R7, R8, R12, R18 | Response style, code quality, evidence, auto-progress, failure museum, agent-bash, web-search reality-check |

The numbering has intentional gaps (R0/R3/R4/R6/R9/R10 are omitted) because some rules are locale- or person-specific and shouldn't be redistributed as defaults. Gaps are preserved so downstream tooling that addresses rules by ID stays stable across forks.

See [`critical-rules.md`](./critical-rules.md) for the full text.

## Non-goals

- **Not a sandbox.** This package shapes Claude's *behavior*, not its *permissions*. Use Claude Code's built-in permission system for hard limits.
- **Not a replacement for `CLAUDE.md`.** `CLAUDE.md` is great for stable, project-scoped context. This package handles rules you want re-asserted *every turn* regardless of context window pressure.
- **Not a policy enforcer for other tools.** The hook only runs inside Claude Code.
- **Not framework-agnostic.** Targets Claude Code specifically (uses its `UserPromptSubmit` hook and `skills/` layout).
- **No telemetry, no network calls.** The hook only `cat`s a local file.

## Why a hook and not just `CLAUDE.md`?

`CLAUDE.md` is loaded once into the session prefix. As the conversation grows, earlier instructions can lose salience against more recent context. The hook re-attaches the rules as additionalContext on every prompt — the repetition keeps them fresh and the system-reminder framing increases instruction-following adherence. For rules where drift is unacceptable (security, secret handling, cross-session privacy), this is the difference between "usually followed" and "consistently followed."

If you don't need that guarantee, just use `CLAUDE.md` and skip this package.

## Known limitations

- **Not yet listed in the official Anthropic plugin marketplace.** Self-hosted as a single-plugin marketplace at this repo; users must `/plugin marketplace add` it explicitly. Submitting to `claude-plugins-official` is a manual form: [claude.ai/settings/plugins/submit](https://claude.ai/settings/plugins/submit).
- **Behavior-shaping, not permission-enforcement.** Use Claude Code's permission system for hard limits — see Non-goals above.

## Layout

```
claude-rules-injector/
├── .claude-plugin/
│   ├── plugin.json            # plugin manifest (for /plugin install)
│   └── marketplace.json       # single-plugin marketplace catalog
├── critical-rules.md          # the rules (edit this to customize)
├── hooks/
│   ├── hooks.json             # plugin-format hook registration
│   └── inject-rules.sh        # UserPromptSubmit hook (fail-open, exit 0)
├── skills/r-check/
│   ├── SKILL.md               # skill definition for Claude Code
│   └── check.sh               # rule-id → section extractor
├── install.sh                 # idempotent legacy installer
├── README.md
├── CHANGELOG.md
└── LICENSE                    # MIT
```

## License

MIT. See [`LICENSE`](./LICENSE) for full text and a note on the 🔥 verbatim quotes.
