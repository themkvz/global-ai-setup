# Agents

Canonical agent definitions live in `agents/*.md`.

## Debugger

Investigates failures and traces symptoms to root cause before recommending smallest fix.

## Frontend Validator

Validates changed UI behavior in browser, preferably using Playwright CLI.

## Security Reviewer

Reviews changed attack surface for concrete security vulnerabilities and trust-boundary problems.

## Builder

Implements a decided change (approved spec, known-cause fix, mechanical multi-file edit) on Haiku at high effort, then stops. Spawned proactively; limited to Read, Edit, Write, Bash, and Skill.

## Verifier

Runs the feature, adds edge-case tests at medium effort, reports problems without changing code.

Claude and Antigravity consume shared Markdown agent definitions directly.

Codex requires TOML definitions, generated from every `agents/*.md` (description and `codex-*` keys come from the frontmatter) with:

```bash
~/.ai/scripts/sync-codex-agents.sh
```


The generated TOML uses `codex-sandbox` from the frontmatter and defaults to `sandbox_mode = "read-only"` when it is absent.

## Model settings

Taken from each file's frontmatter (`model`/`effort` for Claude, `codex-*` for Codex):

* `builder`: Claude `haiku`/high; Codex `gpt-6.1-terra`/high, `workspace-write`; tools limited to Read, Edit, Write, Bash, Skill.
* `debugger`: Claude `opus`/medium; Codex `gpt-6.1-sol`/high, read-only; Edit, Write and NotebookEdit disallowed.
* `frontend-validator`: Claude `haiku`/high; Codex `gpt-6.1-terra`/high, `workspace-write`.
* `security-reviewer`: Claude `opus`/medium; Codex `gpt-6.1-sol`/high, read-only; Edit, Write and NotebookEdit disallowed.
* `verifier`: Claude `opus`/medium; Codex `gpt-6.1-sol`/high, `workspace-write`.
