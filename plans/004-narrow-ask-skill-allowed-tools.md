# Plan 004: `x-ask-skill` pre-approves only the one command it runs

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report. Do not improvise. When done, update the status row for this plan
> in `plans/README.md`, unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat a98665a..HEAD -- skills/ask-skill/SKILL.md`
> If the file changed since this plan was written, compare the "Current state"
> excerpt against the live file before proceeding; on a mismatch, treat it as
> a STOP condition.

## Status

- **Priority**: P3
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: security
- **Planned at**: commit `a98665a`, 2026-11-11

## Why this matters

A skill's `allowed-tools` frontmatter tells Claude Code which tool calls run
without a permission prompt while the skill is active. `x-ask-skill` allows
`Bash(head *)`: `head` on any file on the machine, including key files and
`.env` files, with no prompt. The skill only needs one command:
`head -n 20 ~/.ai/skills/*/SKILL.md`. Narrowing the rule to that command keeps
the skill prompt-free and removes the wide grant. This repository is public,
so everyone who installs it gets the same grant.

## Current state

`skills/ask-skill/SKILL.md` (49 lines). The frontmatter:

```yaml
# skills/ask-skill/SKILL.md:1-8
---
name: x-ask-skill
description: "Not sure which skill fits? Read the current session, match it against the shared ~/.ai skills (and other installed skills if they fit better), and recommend one with the exact command to run it."
argument-hint: "[problem, optional]"
disable-model-invocation: true
allowed-tools: Bash(head *) Read(~/.ai/skills/**)
effort: low
---
```

The only shell command in the body:

```bash
# skills/ask-skill/SKILL.md:22-24
head -n 20 ~/.ai/skills/*/SKILL.md
```

The body also says "if a file's output has no second `---`, Read that file",
which is what `Read(~/.ai/skills/**)` covers. That part is already narrow.

Format convention: `allowed-tools` is a space-separated list of rules on one
line. Another example in this repository is `skills/playwright-cli/SKILL.md`:
`allowed-tools: Bash(playwright-cli:*) Bash(npx playwright:*)`.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Check the rule | `grep -n '^allowed-tools:' skills/ask-skill/SKILL.md` | one line, see step 1 |
| Smoke test (only if `scripts/test.sh` exists) | `scripts/test.sh` | exit 0 |

## Scope

**In scope** (the only file you should modify):

- `skills/ask-skill/SKILL.md` — line 6 only.

**Out of scope** (do NOT touch):

- The body of `skills/ask-skill/SKILL.md`, including the `head` command at
  line 23. The rule is written to match that command exactly.
- `allowed-tools` of other skills (`skills/playwright-cli/SKILL.md`): they are
  scoped to one CLI on purpose.
- `docs/skills.md` — it does not mention `allowed-tools`.

## Git workflow

- Branch: `advisor/004-narrow-ask-skill-allowed-tools`
- Conventional commits, for example
  `fix: narrow x-ask-skill allowed-tools to its one command`.
- Commit with an explicit path list:
  `git commit -m "..." -- skills/ask-skill/SKILL.md`
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Replace the rule

In `skills/ask-skill/SKILL.md` line 6, replace

```yaml
allowed-tools: Bash(head *) Read(~/.ai/skills/**)
```

with

```yaml
allowed-tools: Bash(head -n 20 ~/.ai/skills/*/SKILL.md) Read(~/.ai/skills/**)
```

**Verify**: `grep -c 'Bash(head \*)' skills/ask-skill/SKILL.md` → `0`

**Verify**: `grep -c 'Bash(head -n 20 ~/.ai/skills/\*/SKILL.md)' skills/ask-skill/SKILL.md` → `1`

**Verify**: `sed -n '23p' skills/ask-skill/SKILL.md` → exactly
`head -n 20 ~/.ai/skills/*/SKILL.md` (the body command still matches the rule
text character for character).

## Test plan

No automated test: this is a one-line configuration change and the repository
has no harness that loads skills. The three `grep`/`sed` checks in step 1 are
the verification. Manual check for the owner after merge (not for the
executor): run `/x-ask-skill` in Claude Code and confirm the `head` command
runs without a permission prompt.

## Done criteria

ALL must hold:

- [ ] `grep -c 'Bash(head \*)' skills/ask-skill/SKILL.md` → `0`
- [ ] `grep -c 'Bash(head -n 20 ~/.ai/skills/\*/SKILL.md)' skills/ask-skill/SKILL.md` → `1`
- [ ] `git diff --stat` shows exactly one changed file with 1 insertion and 1 deletion
- [ ] `plans/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- Line 6 does not match the excerpt in "Current state".
- The `head` command in the body (line 23) is different from
  `head -n 20 ~/.ai/skills/*/SKILL.md`. The rule must match the real command;
  report both lines instead of guessing a new rule.

## Maintenance notes

- If the `head` command in the skill body changes (other line count, other
  path), change the rule in the same commit. Otherwise the skill starts asking
  for permission, which is safe but annoying.
- The `*` in the rule is a wildcard for Claude Code, so the rule also matches
  `head -n 20` on other `SKILL.md` files below `~/.ai/skills/`. That is the
  intended reach.
- Other hosts (Codex, Antigravity) ignore `allowed-tools`. This change only
  affects Claude Code. This was not checked against each host's current docs.
- If the owner sees a permission prompt after this change, Claude Code matched
  the rule differently than assumed. The fallback is
  `Bash(head -n 20 ~/.ai/skills/*)`, still far narrower than `Bash(head *)`.
