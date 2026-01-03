# Ralph Loop Runbook

Status: draft
Last verified: YYYY-MM-DD

## Purpose
Run a simple Ralph loop that repeatedly feeds a prompt to an agent command.

## Files
- `PROMPT.md` (prompt content for the loop)
- `scripts/ralph.sh` (start/stop script)

## Start
Choose a command and start the loop:

```bash
# Use stdin (prompt piped to the command)
RALPH_CMD='codex' scripts/ralph.sh start

# Example with another tool
RALPH_CMD='npx --yes @sourcegraph/amp' scripts/ralph.sh start

# Custom prompt and delay
scripts/ralph.sh start --cmd 'codex' --prompt PROMPT.md --sleep 5
```

## Start (aliases)
If you use aliases in `~/.zsh_aliases`, you can run them directly:

```bash
scripts/ralph.sh start --alias oc1
scripts/ralph.sh start --alias oc2
scripts/ralph.sh start --alias oc3
scripts/ralph.sh start --alias codex1
scripts/ralph.sh start --alias codex2
scripts/ralph.sh start --alias cc1
scripts/ralph.sh start --alias cc2
scripts/ralph.sh start --alias cc3
```

Notes:
- Override the alias file path with `RALPH_ALIAS_FILE`.
- Override the shell used to resolve aliases with `RALPH_ALIAS_SHELL`.
- Alias names `oc1/oc2/oc3`, `codex1/codex2`, and `cc1/cc2/cc3` auto-run in headless mode.
- OpenCode headless uses `opencode run` with model `anthropic/claude-opus-4-5` by default.
  - Override with `RALPH_OPENCODE_MODEL=anthropic/claude-opus-4-5-20251101` (or any valid model).

Prompt path:
- If your command needs the prompt path, use `{prompt}` in the command:

```bash
RALPH_CMD='some-tool --prompt-file {prompt}' scripts/ralph.sh start
```

## Stop

```bash
scripts/ralph.sh stop
```

## Status / Logs

```bash
scripts/ralph.sh status
scripts/ralph.sh tail
```

## Behavior
- State is stored under `$TMPDIR/ralph-<hash>/` so the repo stays clean.
- The loop appends logs to `$TMPDIR/ralph-<hash>/ralph.log`.
