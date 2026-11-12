# Plan 001: A one-command smoke test and CI check the scripts on every push

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report. Do not improvise. When done, update the status row for this plan
> in `plans/README.md`, unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat a98665a..HEAD -- bootstrap.sh scripts/ README.md .github/`
> If any of these files changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: tests
- **Planned at**: commit `a98665a`, 2026-11-11

## Approved execution adjustments

Reviewed against `80bc716` on 2026-11-12: production scripts and README have not drifted.
These adjustments override the original instructions below:

- Work in the current workspace, without a git worktree, branch change, or commit, as requested by the owner.
- Copy `GLOBAL.md`, `bootstrap.sh`, `agents/`, `skills/`, and `scripts/` into `$TEST_HOME/.ai` instead of symlinking the repository. Bootstrap runs `chmod` on scripts; the test must affect only the copy.
- Keep the test shell's `HOME` unchanged. Use `$TEST_HOME` for assertions and pass the temporary home only to child processes with `env HOME="$TEST_HOME"`.
- Check that dry run creates none of the six tool folders. After the second bootstrap run, confirm the original backup is intact.
- Use `actions/checkout@v7`, based on the current [official release](https://github.com/actions/checkout/releases/tag/v7.0.1).
- Describe CI triggers precisely: pushes to `main` and pull requests. ShellCheck runs on Linux; syntax and smoke tests run on both operating systems.
- Check the script's executable bit without staging it. The reviewer updates the plan index after local verification.

## Execution result

Completed in the current workspace on 2026-11-12, without a worktree or commit.

- `scripts/test.sh`: all 7 checks passed on macOS Bash 3.2.
- Per-file `bash -n`, Ruby YAML parsing, executable-bit check, and `git diff --check`: passed.
- `bootstrap.sh`, `scripts/doctor.sh`, and `scripts/sync-codex-agents.sh`: unchanged from the planned baseline.
- ShellCheck was not installed, so its CI step was not verified locally. Hosted Linux and macOS jobs have not run.

## Why this matters

This repository is public and its scripts write into the user's home folder
(`~/.claude`, `~/.codex`, `~/.gemini`, `~/.copilot`, `~/.agents`, `~/.agent`).
Today nothing checks them automatically: `README.md` says "There is no
automated test suite or CI". A broken `bootstrap.sh` can be pushed unnoticed.
The manual syntax command in the README is also wrong: `bash -n a.sh b.sh`
only checks the first file. After this plan, `scripts/test.sh` runs the real
scripts against a throwaway home folder, and GitHub Actions runs it on Linux
and macOS. Plans 002 and 003 add their tests to this file.

## Current state

- `bootstrap.sh` — creates symlinks from tool folders in `$HOME` to `$HOME/.ai`.
  The repository location is fixed:

  ```bash
  # bootstrap.sh:5-6
  AI_HOME="$HOME/.ai"
  DRY_RUN="${DRY_RUN:-0}"
  ```

  It links `GLOBAL.md` to four files (`bootstrap.sh:67-70`), each skill folder
  as `x-<name>` into three folders (`bootstrap.sh:80-82`), each agent into two
  folders (`bootstrap.sh:93-94`), then runs `scripts/sync-codex-agents.sh`.
  An existing regular file is moved to `<file>.backup` first (`bootstrap.sh:31-40`).
- `scripts/sync-codex-agents.sh` — writes `~/.codex/agents/<name>.toml` for
  every `~/.ai/agents/<name>.md`.
- `scripts/doctor.sh` — read-only health check. Prints `Failures: N` and
  `Warnings: N` at the end and exits 1 when `Failures` is above 0. It also runs
  `claude plugin list`, `rtk init --show` and `rtk gain` when those CLIs are on
  `PATH` (`doctor.sh:268-306`). The test must not start them.
- `README.md:128-148` — the "Testing" section:

  ```markdown
  ## Testing

  There is no automated test suite or CI. Before committing, run:

  ```bash
  bash -n ~/.ai/bootstrap.sh ~/.ai/scripts/*.sh
  ```
  ```

  followed by separate code blocks for `shellcheck ~/.ai/bootstrap.sh ~/.ai/scripts/*.sh`,
  `DRY_RUN=1 ~/.ai/bootstrap.sh` and `~/.ai/scripts/doctor.sh`.
- `README.md:116-126` — the "Repository layout" tree lists `scripts/doctor.sh`
  and `scripts/sync-codex-agents.sh`.
- There is no `.github/` folder.

Conventions to match (see `scripts/doctor.sh` as the exemplar):

- `#!/usr/bin/env bash`, then a blank line, then `set -euo pipefail`.
- 2-space indent, `[[ ... ]]` tests, `local` variables in functions, quoted expansions.
- Output markers: `✓` for success, `✗` for failure, `==> Title` for sections.
- Must run on macOS system Bash 3.2: no associative arrays, no `mapfile`,
  no `${var,,}`.
- Scripts are committed with the executable bit (mode `100755`).

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Syntax | `for f in bootstrap.sh scripts/*.sh; do bash -n "$f" \|\| echo "FAIL $f"; done` | no output |
| Smoke test | `scripts/test.sh` | last line `All 7 checks passed.`, exit 0 |
| Lint (optional) | `shellcheck bootstrap.sh scripts/*.sh` | exit 0. Only if `shellcheck` is installed. |

Run all commands from the repository root.

## Scope

**In scope** (the only files you should modify):

- `scripts/test.sh` (create)
- `.github/workflows/check.yml` (create)
- `README.md` (sections "Key features", "Repository layout", "Testing" only)

**Out of scope** (do NOT touch):

- `bootstrap.sh`, `scripts/doctor.sh`, `scripts/sync-codex-agents.sh` — this
  plan only tests them. Fixing them is plans 002 and 003.
- `GLOBAL.md`, `skills/`, `agents/`, `docs/`.
- `MONOREPO-GUIDE.md`, `TELEGRAM-BOT-GUIDE.md`, `.agents/`, `.claude/`,
  `skills-lock.json` — the owner's uncommitted work.

## Git workflow

- Branch: `advisor/001-smoke-test-and-ci`
- Commit style is conventional commits. Examples from `git log`:
  `chore: Tune agent model and effort settings`, `docs: restructure README for public release`.
- The owner may have files staged that are not yours (`MONOREPO-GUIDE.md`).
  Commit with an explicit path list so you do not include them:
  `git add scripts/test.sh .github/workflows/check.yml README.md && git commit -m "test: add smoke test and CI" -- scripts/test.sh .github/workflows/check.yml README.md`
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Create `scripts/test.sh`

Create the file with exactly this content. It was run against commit `a98665a`
on macOS Bash 3.2 and passed.

```bash
#!/usr/bin/env bash

# Smoke test: runs bootstrap, sync and doctor against a throwaway HOME.
# Never touches the real home folder.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

# The scripts expect the repository at ~/.ai.
ln -s "$REPO" "$TEST_HOME/.ai"
export HOME="$TEST_HOME"

CHECKS=0

pass() {
  CHECKS=$((CHECKS + 1))
  printf '✓ %s\n' "$1"
}

die() {
  printf '✗ %s\n' "$1" >&2
  exit 1
}

assert_link() {
  local target="$1" expected="$2"

  [[ -L "$target" ]] || die "Not a symlink: $target"
  [[ "$(readlink "$target")" == "$expected" ]] || die "$target does not point to $expected"
}

echo "==> Dry run changes nothing"

DRY_RUN=1 "$HOME/.ai/bootstrap.sh" >/dev/null
[[ ! -e "$HOME/.claude" && ! -e "$HOME/.codex" ]] || die "Dry run created files"
pass "dry run wrote nothing"

echo "==> Bootstrap creates links and keeps a backup"

mkdir -p "$HOME/.codex"
echo "old instructions" > "$HOME/.codex/AGENTS.md"

"$HOME/.ai/bootstrap.sh" >/dev/null

assert_link "$HOME/.claude/CLAUDE.md" "$HOME/.ai/GLOBAL.md"
assert_link "$HOME/.codex/AGENTS.md" "$HOME/.ai/GLOBAL.md"
assert_link "$HOME/.gemini/GEMINI.md" "$HOME/.ai/GLOBAL.md"
assert_link "$HOME/.copilot/copilot-instructions.md" "$HOME/.ai/GLOBAL.md"
pass "global context links"

[[ "$(cat "$HOME/.codex/AGENTS.md.backup")" == "old instructions" ]] || die "Backup missing"
pass "existing file backed up"

for skill in "$HOME"/.ai/skills/*/; do
  name="$(basename "$skill")"

  for dir in .claude/skills .agents/skills .agent/skills; do
    assert_link "$HOME/$dir/x-$name" "$HOME/.ai/skills/$name"
  done
done
pass "skill links"

for agent in "$HOME"/.ai/agents/*.md; do
  name="$(basename "$agent")"

  assert_link "$HOME/.claude/agents/$name" "$agent"
  assert_link "$HOME/.gemini/config/agents/$name" "$agent"
  [[ -s "$HOME/.codex/agents/${name%.md}.toml" ]] || die "Missing Codex agent: ${name%.md}.toml"
done
pass "agent links and Codex agents"

echo "==> Bootstrap is safe to run twice"

"$HOME/.ai/bootstrap.sh" >/dev/null
assert_link "$HOME/.claude/CLAUDE.md" "$HOME/.ai/GLOBAL.md"
pass "second run"

echo "==> Doctor reports no failures"

# Minimal PATH: doctor must not start the real claude, codex or rtk CLIs.
PATH="/usr/bin:/bin" "$HOME/.ai/scripts/doctor.sh" > "$TEST_HOME/doctor.log" ||
  { cat "$TEST_HOME/doctor.log"; die "doctor.sh failed"; }
grep -q '^Failures: 0$' "$TEST_HOME/doctor.log" || die "doctor.sh reported failures"
pass "doctor"

printf '\nAll %d checks passed.\n' "$CHECKS"
```

Then make it executable: `chmod +x scripts/test.sh`.

**Verify**: `scripts/test.sh; echo "exit=$?"` → seven `✓` lines, then
`All 7 checks passed.` and `exit=0`.

**Verify (real home untouched)**: `git status --short` shows only
`scripts/test.sh` as new from you, and `ls ~/.codex/AGENTS.md.backup` does not
show a file created just now.

### Step 2: Create `.github/workflows/check.yml`

First find the current major version of the checkout action:

```bash
gh api repos/actions/checkout/releases/latest --jq .tag_name
```

Use its major version (for example `v5.x.y` → `v5`). If `gh` is not available
or the command fails, use `v4`.

Create the file (replace `<major>`):

```yaml
name: check

on:
  push:
    branches: [main]
  pull_request:

jobs:
  check:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@<major>

      - name: Syntax
        run: |
          for f in bootstrap.sh scripts/*.sh; do
            bash -n "$f"
          done

      - name: ShellCheck
        if: runner.os == 'Linux'
        run: shellcheck bootstrap.sh scripts/*.sh

      - name: Smoke test
        run: scripts/test.sh
```

ShellCheck is preinstalled on `ubuntu-latest`, so no install step is needed.

**Verify**: `python3 -c 'import sys,yaml; yaml.safe_load(open(".github/workflows/check.yml"))' 2>&1 || ruby -ryaml -e 'YAML.load_file(".github/workflows/check.yml")'`
→ no error from at least one of the two (either parser is enough).

**Verify (ShellCheck, only if installed)**: `command -v shellcheck && shellcheck bootstrap.sh scripts/*.sh; echo "exit=$?"`
→ `exit=0`. If ShellCheck is not installed, write in your final report:
"ShellCheck step not verified locally". If it reports findings, see STOP conditions.

### Step 3: Update `README.md`

Three edits.

1. In "Key features", after the `**Health check.**` bullet (`README.md:16`), add:

   ```markdown
   * **Smoke test and CI.** `scripts/test.sh` runs bootstrap, sync, and doctor against a throwaway home folder. GitHub Actions runs it on Linux and macOS.
   ```

2. In the "Repository layout" tree, add a line after the `doctor.sh` line,
   keeping the column alignment of the comments:

   ```text
   │   ├── test.sh                   smoke test in a throwaway home folder
   ```

3. Replace the start of the "Testing" section. Old text:

   ````markdown
   There is no automated test suite or CI. Before committing, run:

   ```bash
   bash -n ~/.ai/bootstrap.sh ~/.ai/scripts/*.sh
   ```
   ````

   New text:

   ````markdown
   CI runs a syntax check, ShellCheck, and the smoke test on every push and pull request. Before committing, run the smoke test. It uses a temporary home folder and never touches your real one:

   ```bash
   ~/.ai/scripts/test.sh
   ```
   ````

   Keep the `shellcheck`, `DRY_RUN=1` and `doctor.sh` blocks and the last
   paragraph of the section as they are.

**Verify**: `grep -c "bash -n ~/.ai/bootstrap.sh" README.md` → `0`, and
`grep -c "scripts/test.sh" README.md` → `2` or more.

## Test plan

- The deliverable is the test: `scripts/test.sh`, covering dry run, link
  creation, backup of an existing file, a second run, and `doctor.sh`.
- Verification: `scripts/test.sh` → `All 7 checks passed.`

## Done criteria

ALL must hold:

- [ ] `scripts/test.sh` exits 0 and prints `All 7 checks passed.`
- [ ] `git ls-files -s scripts/test.sh` (after `git add`) starts with `100755`
- [ ] `.github/workflows/check.yml` exists and parses as YAML
- [ ] `grep -c "no automated test suite" README.md` → `0`
- [ ] `git diff --stat a98665a -- bootstrap.sh scripts/doctor.sh scripts/sync-codex-agents.sh` is empty
- [ ] `plans/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- `scripts/test.sh` fails at any check with the content given above. That
  means a real bug in `bootstrap.sh`, `doctor.sh` or `sync-codex-agents.sh`.
  Report which check failed and the output. Do not edit those scripts and do
  not remove the check.
- ShellCheck is installed and reports findings. Report the full output. Do not
  fix the scripts (out of scope) and do not add `continue-on-error` or
  `# shellcheck disable` to make it pass.
- `mktemp -d` or `readlink` behave differently on your system than the test
  expects.

## Maintenance notes

- Plans 002 and 003 add sections to `scripts/test.sh` before the
  "Doctor reports no failures" section and change the final count.
- The doctor step runs with `PATH="/usr/bin:/bin"` on purpose. If `doctor.sh`
  later needs a tool from another folder to avoid a failure, extend that
  `PATH` in the test, not the real one.
- The ShellCheck step was not run when this plan was written (ShellCheck was
  not installed). The first CI run may show findings; fix them in the scripts,
  not by weakening the step.
- A reviewer should check that nothing in `scripts/test.sh` reads or writes a
  path that is not under `$TEST_HOME`.
