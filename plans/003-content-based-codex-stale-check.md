# Plan 003: `doctor.sh` compares Codex agents by content, not by file time

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report. Do not improvise. When done, update the status row for this plan
> in `plans/README.md`, unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat a98665a..HEAD -- scripts/doctor.sh scripts/sync-codex-agents.sh`
> Changes from plan 002 are expected (see "Current state"). If the two
> excerpts below are not in the files, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: plans/001-smoke-test-and-ci.md; land after plans/002-prune-stale-links-and-codex-agents.md (same files)
- **Category**: bug
- **Planned at**: commit `a98665a`, 2026-11-11

## Why this matters

Codex cannot read the Markdown agents in `agents/*.md`, so
`scripts/sync-codex-agents.sh` generates `~/.codex/agents/<name>.toml` from
them. `doctor.sh` decides whether a generated file is outdated by comparing
file modification times. That is wrong in both directions: `git pull` or
`git checkout` gives the Markdown file a new time without changing its content
(false warning), and a change to the sync script itself changes the output
without touching any Markdown file (missed warning). After this plan, doctor
generates the expected TOML into a temp folder and compares content.

## Current state

`scripts/sync-codex-agents.sh` — the output folder is fixed:

```bash
# sync-codex-agents.sh:5-8
SRC="$HOME/.ai/agents"
DST="$HOME/.codex/agents"

mkdir -p "$DST"
```

Every later use goes through `$DST`. The script prints one `Synced: <path>`
line per agent and `Codex agents synced.` at the end. It takes no arguments
today.

`scripts/doctor.sh` — the agent loop:

```bash
# doctor.sh:116-136
section "Shared agents"

for agent in "$AI_HOME"/agents/*.md; do
  [[ -f "$agent" ]] || continue

  name="$(basename "$agent")"
  codex_agent="$HOME/.codex/agents/${name%.md}.toml"

  ok "$name"

  check_link "$HOME/.claude/agents/$name" "$agent"
  check_link "$HOME/.gemini/config/agents/$name" "$agent"

  if [[ ! -f "$codex_agent" ]]; then
    warn "Codex agent not synced: $codex_agent"
  elif [[ "$agent" -nt "$codex_agent" ]]; then
    warn "Codex agent may be stale: $codex_agent"
  else
    ok "$codex_agent"
  fi
done
```

`doctor.sh` uses `set -uo pipefail` WITHOUT `-e` (line 3), and helpers `ok`,
`warn`, `fail`, `section` (lines 10-26). `AI_HOME="$HOME/.ai"` (line 5).

If plan 002 has landed, expect these extra pieces. They are fine and must stay:

- `sync-codex-agents.sh`: a `MARKER=` line after `DST=`, `echo "$MARKER"` as the
  first output line, guards in `sync_agent`, and a prune loop after the main loop.
- `doctor.sh`: a `check_dangling` function and calls after the skill and agent
  loops, plus an "Orphan Codex agent" loop. Line numbers above shift down.

`README.md:148`:

```markdown
`doctor.sh` writes no files. It reads your config and runs `--version`, `claude plugin list`, `rtk init --show`, and `rtk gain` for the CLIs that are installed.
```

`scripts/test.sh` — created by plan 001. It runs everything with `HOME` set to
a temp folder (`$TEST_HOME`). Helpers: `pass "<label>"`, `die "<message>"`.
Near the end it has:

```bash
echo "==> Doctor reports no failures"

# Minimal PATH: doctor must not start the real claude, codex or rtk CLIs.
PATH="/usr/bin:/bin" "$HOME/.ai/scripts/doctor.sh" > "$TEST_HOME/doctor.log" ||
  { cat "$TEST_HOME/doctor.log"; die "doctor.sh failed"; }
grep -q '^Failures: 0$' "$TEST_HOME/doctor.log" || die "doctor.sh reported failures"
pass "doctor"

printf '\nAll %d checks passed.\n' "$CHECKS"
```

Conventions to match: 2-space indent, `[[ ... ]]`, quoted expansions, macOS
Bash 3.2 compatibility.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Syntax | `for f in bootstrap.sh scripts/*.sh; do bash -n "$f" \|\| echo "FAIL $f"; done` | no output |
| Smoke test | `scripts/test.sh` | `All N checks passed.`, exit 0. N is 9 before this plan if plan 002 landed (7 if not), and N+2 after. |
| Lint (optional) | `shellcheck bootstrap.sh scripts/*.sh` | exit 0. Only if installed. |

Run from the repository root. Do not run `sync-codex-agents.sh` without an
argument while executing this plan: it writes to the real `~/.codex/agents`.

## Scope

**In scope** (the only files you should modify):

- `scripts/sync-codex-agents.sh` (one line)
- `scripts/doctor.sh` (the agent loop and a few lines before it)
- `scripts/test.sh`
- `README.md` (line 148 only)

**Out of scope** (do NOT touch):

- `bootstrap.sh` — it calls the sync script without arguments, which keeps
  working.
- Everything plan 002 added (marker, prune loops, guards, `check_dangling`).
- `agents/*.md`, `docs/`.
- `MONOREPO-GUIDE.md`, `TELEGRAM-BOT-GUIDE.md`, `.agents/`, `.claude/`,
  `skills-lock.json` — the owner's uncommitted work.

## Git workflow

- Branch: `advisor/003-content-based-codex-stale-check`
- Conventional commits, for example
  `fix: detect outdated Codex agents by content`.
- Commit with an explicit path list (`git commit -m "..." -- <files>`).
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Let the sync script take an output folder

In `scripts/sync-codex-agents.sh`, replace

```bash
DST="$HOME/.codex/agents"
```

with

```bash
# Optional first argument: output folder (doctor.sh uses a temp folder).
DST="${1:-$HOME/.codex/agents}"
```

**Verify**:

```bash
out="$(mktemp -d)" && scripts/sync-codex-agents.sh "$out" >/dev/null && ls "$out" | wc -l && rm -rf "$out"
```

→ prints `5` (one TOML per file in `agents/`). This reads the real
`~/.ai/agents` and writes only to the temp folder.

### Step 2: Compare content in `doctor.sh`

Directly after `section "Shared agents"` and before the `for agent` loop, add:

```bash
# Generate what sync would write now and compare it with what is installed.
codex_expected="$(mktemp -d)"
trap 'rm -rf "$codex_expected"' EXIT

if ! "$AI_HOME/scripts/sync-codex-agents.sh" "$codex_expected" >/dev/null 2>&1; then
  fail "sync-codex-agents.sh failed; Codex agents cannot be compared"
fi
```

In the loop, replace

```bash
  elif [[ "$agent" -nt "$codex_agent" ]]; then
    warn "Codex agent may be stale: $codex_agent"
```

with

```bash
  elif ! cmp -s "$codex_expected/${name%.md}.toml" "$codex_agent"; then
    warn "Codex agent out of date: $codex_agent (run sync-codex-agents.sh)"
```

**Verify**: `bash -n scripts/doctor.sh && grep -c -- '-nt ' scripts/doctor.sh` → `0`,
then `scripts/test.sh` → still passes with the same count as before this plan.

### Step 3: Add tests to `scripts/test.sh`

Insert this section directly AFTER the line `pass "doctor"` and before the
final `printf`:

```bash
echo "==> Doctor compares Codex agents by content"

# Old file time, same content: not out of date.
touch -t 200001010000 "$HOME/.codex/agents/builder.toml"
PATH="/usr/bin:/bin" "$HOME/.ai/scripts/doctor.sh" > "$TEST_HOME/doctor.log" || true
if grep -q '^! .*builder.toml' "$TEST_HOME/doctor.log"; then
  die "doctor.sh used file time to judge builder.toml"
fi
pass "old file time is not out of date"

# Changed content: out of date.
echo "# edited" >> "$HOME/.codex/agents/builder.toml"
PATH="/usr/bin:/bin" "$HOME/.ai/scripts/doctor.sh" > "$TEST_HOME/doctor.log" || true
grep -q 'Codex agent out of date: .*builder.toml' "$TEST_HOME/doctor.log" ||
  die "doctor.sh missed a changed Codex agent"
pass "changed content is out of date"
```

**Verify**: `scripts/test.sh; echo "exit=$?"` → two more `✓` lines than before,
`All N checks passed.` with N two higher than before this plan, and `exit=0`.

**Verify (regression test really tests)**: before you commit, run
`git stash push scripts/doctor.sh && scripts/test.sh; git stash pop` → the run
with the old `doctor.sh` must fail with
`doctor.sh used file time to judge builder.toml`. After `git stash pop`, run
`scripts/test.sh` again → passes. If `git stash` is not possible in your
environment, skip this check and say so in your report.

### Step 4: Update `README.md`

Replace the sentence start at `README.md:148`

```markdown
`doctor.sh` writes no files. It reads your config
```

with

```markdown
`doctor.sh` writes nothing outside a temporary folder that it removes. It reads your config
```

Keep the rest of the line.

**Verify**: `grep -c "doctor.sh\` writes no files" README.md` → `0`.

## Test plan

- New section in `scripts/test.sh` with two cases:
  - regression: a generated file with an old modification time and correct
    content is NOT reported (the old `-nt` check reported it);
  - a generated file with changed content IS reported as out of date.
- The existing "Doctor reports no failures" section still passes: right after
  bootstrap, installed and expected content are equal.
- Verification: `scripts/test.sh` → all pass, two more checks than before.

## Done criteria

ALL must hold:

- [ ] `scripts/test.sh` exits 0
- [ ] `grep -c -- '-nt ' scripts/doctor.sh` → `0`
- [ ] `grep -c 'DST="${1:-' scripts/sync-codex-agents.sh` → `1`
- [ ] `for f in bootstrap.sh scripts/*.sh; do bash -n "$f" || echo FAIL; done` prints nothing
- [ ] `git diff --stat -- bootstrap.sh` is empty
- [ ] `plans/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- `scripts/test.sh` does not exist (plan 001 has not landed).
- `doctor.sh` already has a `trap ... EXIT`. A second `trap` would replace it;
  report instead of merging them yourself.
- The sync output is not the same on two runs with the same input (for example
  a timestamp was added to the generated file). Content comparison would then
  always warn.
- A verification fails twice after a reasonable fix attempt.

## Maintenance notes

- The generated TOML must stay deterministic: no dates, no host names. If that
  changes, this check breaks.
- `doctor.sh` now runs the sync script. If sync gets side effects beyond its
  output folder, doctor is no longer read-only.
- If plan 002 landed, sync also runs its prune loop on the temp folder. That
  is harmless: the folder holds only fresh files.
- A reviewer should confirm doctor never calls the sync script without the
  temp-folder argument.
