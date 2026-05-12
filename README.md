# claude-guardrails

> Auto-inject a "critical rules" prompt at the top of every turn in Claude Code, plus a `r-check` skill for on-demand rule lookup.

`claude-guardrails` is a tiny, auditable layer on top of Claude Code that solves one problem: **rules you write in `CLAUDE.md` are advisory — Claude may not re-read them mid-session.** This package wires the same rules into a `UserPromptSubmit` hook, so they are re-injected verbatim on every prompt. Violations short-circuit the task instead of leaking through.

It is opinionated: 13 rules, English summaries with Japanese author-original quotes preserved verbatim per R16. Fork it, edit `critical-rules.md`, and reinstall — the wiring is the value, the rules are an example.

## Install

```bash
git clone https://github.com/hinanohart/claude-guardrails.git
cd claude-guardrails
bash install.sh
```

The installer:
- copies `critical-rules.md` to `~/.claude/critical-rules.md`
- installs the hook at `~/.claude/hooks/inject-rules.sh`
- installs the `r-check` skill at `~/.claude/skills/r-check/`
- registers the hook in `~/.claude/settings.json` (idempotent; creates `.bak.<epoch>` backup before any edit)

Restart Claude Code to activate. To confirm it works, send any prompt — you should see the rules injected at the top.

## Disable / customize

| Goal | How |
|---|---|
| Temporarily disable injection | `export CLAUDE_RULES_DISABLE=1` |
| Use your own rules file | `export CLAUDE_RULES_PATH=/path/to/rules.md` |
| Pin a path persistently | `echo /path/to/rules.md > ~/.claude/critical-rules.path` |
| Look up one rule | invoke the `r-check` skill or run `~/.claude/skills/r-check/check.sh R11` |

## Uninstall

```bash
bash install.sh --uninstall
```

This removes `critical-rules.md`, the hook, and the skill, and restores the most recent `settings.json` backup if one exists. If no backup exists, it edits `settings.json` in place to remove only the `claude-guardrails` hook entry.

## What's in the rules

13 rules across three priority tiers. Lines prefixed with `🔥` reproduce the original Japanese wording verbatim and should not be reworded (see R16); each is followed by an English paraphrase and an operational line.

| Tier | Rules | What they cover |
|---|---|---|
| **1 (immediate stop)** | R11, R13, R15 | Secret handling, security isolation, cross-session contamination |
| **1.5 (special protocol)** | R14, R16, R17 | Pre-large-work discussion, 100% intent comprehension, write-target audit |
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

`CLAUDE.md` is loaded once and may be paged out of attention as the conversation grows. The hook re-injects the rules at the *top* of every user prompt, where they get the strongest attention. For rules where drift is unacceptable (security, secret handling, cross-session privacy), this is the difference between "usually followed" and "consistently followed."

If you don't need that guarantee, just use `CLAUDE.md` and skip this package.

## Layout

```
claude-guardrails/
├── critical-rules.md          # the rules (edit this to customize)
├── README.md
├── install.sh                 # idempotent installer
├── hooks/inject-rules.sh      # UserPromptSubmit hook (fail-open, exit 0)
├── skills/r-check/
│   ├── SKILL.md               # skill definition for Claude Code
│   └── check.sh               # rule-id → section extractor
└── LICENSE                    # MIT
```

## License

MIT. See [`LICENSE`](./LICENSE) for full text and a note on the 🔥 verbatim quotes.
