---
name: limitbar
description: "LimitBar read. Provider usage, limits, credits, config health. JSON. No writes."
---

# LimitBar

Read LimitBar. Never mutate config/auth.

## Run

```bash
skill="${CODEX_HOME:-$HOME/.codex}/skills/limitbar"
"$skill/scripts/limitbar" doctor
"$skill/scripts/limitbar" providers
"$skill/scripts/limitbar" usage
"$skill/scripts/limitbar" usage --provider codex
"$skill/scripts/limitbar" usage --all
```

All stdout: JSON. Upstream LimitBar shape kept. Less drift, fewer tokens.

## Rules

- Start `doctor` when install/config unknown.
- `usage` reads enabled providers. Prefer this.
- `usage --provider ID` reads one provider.
- `usage --all` expensive; use only when needed.
- Identities hidden by default. `--include-identities` only when user explicitly needs them.
- Secrets always hidden.
- Helper read-only: fixed allowlist only. No config writes, auth repair, enable/disable, key storage.
- Timeout means upstream stuck. Narrow provider or raise `LIMITBAR_TIMEOUT` (default 120 seconds).

## Binary

Auto-find: `LIMITBAR_BIN`, PATH, app bundle, Homebrew cask. If missing: open LimitBar, Preferences > Advanced > Install CLI; or set `LIMITBAR_BIN`.

Each stdout/stderr stream capped at 1 MiB while fully drained. Timeout kills process group.
