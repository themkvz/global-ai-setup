# Plan 002: Renamed or deleted skills and agents leave nothing behind

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report. Do not improvise. When done, update the status row for this plan
> in `plans/README.md`, unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat a98665a..HEAD -- bootstrap.sh scripts/doctor.sh scripts/sync-codex-agents.sh`
> If any of these files changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition. (`scripts/test.sh` is expected to be
> new: plan 001 created it.)

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: MED (the change deletes files in the user's home folder)
- **Depends on**: plans/001-smoke-test-and-ci.md
- **Category**: bug
- **Planned at**: commit `a98665a`, 2026-11-11

## Why this matters

`bootstrap.sh` links each skill and agent into tool folders in `$HOME`, and
`sync-codex-agents.sh` generates one TOML file per agent. Both loop only over
sources that exist now. When a skill or agent is renamed or deleted in the
repository, its old symlinks stay as dangling links, and its old
`~/.codex/agents/<name>.toml` stays as a working Codex agent with outdated
instructions. `doctor.sh` loops over the same sources, so it reports nothing.
After this plan, bootstrap and sync remove what they created for sources that
no longer exist, and doctor reports leftovers. The plan also makes the sync
script stop with an error on frontmatter it cannot convert, instead of writing
a wrong TOML file.

## Current state

`bootstrap.sh` (125 lines). `AI_HOME="$HOME/.ai"` (line 5). Helper `run`
(lines 8-16) prints the command instead of running it when `DRY_RUN=1`.
Function `link_dir` ends at line 63. The loops:

```bash
# bootstrap.sh:75-83
for skill in "$AI_HOME"/skills/*; do
  [[ -d "$skill" ]] || continue

  name="$(basename "$skill")"

  link_dir "$skill" "$HOME/.claude/skills/x-$name"
  link_dir "$skill" "$HOME/.agents/skills/x-$name"
  link_dir "$skill" "$HOME/.agent/skills/x-$name"
done
```

```bash
# bootstrap.sh:88-95
for agent in "$AI_HOME"/agents/*.md; do
  [[ -f "$agent" ]] || continue

  name="$(basename "$agent")"

  backup_and_link "$agent" "$HOME/.claude/agents/$name"
  backup_and_link "$agent" "$HOME/.gemini/config/agents/$name"
done
```

All links are created with an absolute target that starts with `$AI_HOME/`
(`ln -s "$source" "$target"`, lines 42 and 61).

`scripts/sync-codex-agents.sh` (85 lines):

```bash
# sync-codex-agents.sh:5-8
SRC="$HOME/.ai/agents"
DST="$HOME/.codex/agents"

mkdir -p "$DST"
```

```bash
# sync-codex-agents.sh:30-33 (inside sync_agent)
  # Escape for a TOML basic string.
  description="$(frontmatter_value "description" "$source")"
  description="${description//\\/\\\\}"
  description="${description//\"/\\\"}"
```

```bash
# sync-codex-agents.sh:64-84
  {
    echo "name = \"$name\""
    echo "description = \"$description\""
    [[ -n "$codex_model" ]] && echo "model = \"$codex_model\""
    [[ -n "$codex_effort" ]] && echo "model_reasoning_effort = \"$codex_effort\""
    echo "sandbox_mode = \"${codex_sandbox:-read-only}\""
    echo
    # Literal string: backslashes in the body stay as written.
    echo "developer_instructions = '''"
    echo "$body"
    echo "'''"
  } > "$target"

  echo "Synced: $target"
}

for source in "$SRC"/*.md; do
  sync_agent "$source"
done

echo "Codex agents synced."
```

`frontmatter_value` (lines 11-22) returns the text after `key: ` on one line.
It does not understand YAML quoting or multi-line values (`description: >`).
All five current agents use a plain one-line description, so nothing is broken
today.

`scripts/doctor.sh` (334 lines). Helpers `ok`, `warn`, `fail`, `section`
(lines 10-26). `fail` increases `FAILURES`, and the script exits 1 when it is
above 0. The skill loop is lines 99-114, the agent loop is lines 118-136, and
the next section starts at line 138 with `section "Scripts"`.

`scripts/test.sh` — created by plan 001. It runs the scripts with `HOME` set to
a temp folder (`$TEST_HOME`), where `$HOME/.ai` is a symlink to the repository.
It has sections that start with `echo "==> ..."`, helpers `pass`, `die` and
`assert_link`, a variable `REPO` with the real repository path, and a section
`echo "==> Doctor reports no failures"` near the end.

Conventions to match: 2-space indent, `[[ ... ]]`, `local` in functions, quoted
expansions, and macOS Bash 3.2 compatibility (no associative arrays, no
`mapfile`). `set -e` is active in `bootstrap.sh` and `sync-codex-agents.sh`:
write guards as `[[ cond ]] || continue`, never as a bare `[[ cond ]] && cmd`
as the last command of a loop body.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Syntax | `for f in bootstrap.sh scripts/*.sh; do bash -n "$f" \|\| echo "FAIL $f"; done` | no output |
| Smoke test | `scripts/test.sh` | `All 9 checks passed.` after this plan, exit 0 |
| Lint (optional) | `shellcheck bootstrap.sh scripts/*.sh` | exit 0. Only if installed. |

Run all commands from the repository root. Never run `bootstrap.sh` or
`sync-codex-agents.sh` directly while executing this plan: that would change
the real home folder. Use `scripts/test.sh` only.

## Scope

**In scope** (the only files you should modify):

- `bootstrap.sh`
- `scripts/sync-codex-agents.sh`
- `scripts/doctor.sh`
- `scripts/test.sh`
- `README.md` (one bullet, step 6)

**Out of scope** (do NOT touch):

- `agents/*.md`, `skills/` — sources stay as they are.
- A full YAML parser for frontmatter. The guard in step 3 is the whole fix.
- The mtime check at `doctor.sh:131` (`-nt`). Plan 003 replaces it.
- `MONOREPO-GUIDE.md`, `TELEGRAM-BOT-GUIDE.md`, `.agents/`, `.claude/`,
  `skills-lock.json` — the owner's uncommitted work.

## Git workflow

- Branch: `advisor/002-prune-stale-links-and-codex-agents`
- Conventional commits, for example
  `fix: prune links and Codex agents of removed skills and agents`.
- Commit with an explicit path list (`git commit -m "..." -- <files>`), because
  the owner may have other files staged.
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Add `prune_dangling` to `bootstrap.sh`

Add this function directly after `link_dir` (after line 63):

```bash
# Remove links left behind by a renamed or deleted skill or agent.
# Only touches dangling symlinks that point into $AI_HOME.
prune_dangling() {
  local dir="$1"
  local link

  [[ -d "$dir" ]] || return 0

  for link in "$dir"/*; do
    [[ -L "$link" && ! -e "$link" ]] || continue
    [[ "$(readlink "$link")" == "$AI_HOME"/* ]] || continue

    run rm "$link"
    echo "Pruned: $link"
  done
}
```

Directly after the `done` of the skills loop (line 83), add:

```bash

prune_dangling "$HOME/.claude/skills"
prune_dangling "$HOME/.agents/skills"
prune_dangling "$HOME/.agent/skills"
```

Directly after the `done` of the agents loop (line 95), add:

```bash

prune_dangling "$HOME/.claude/agents"
prune_dangling "$HOME/.gemini/config/agents"
```

**Verify**: `bash -n bootstrap.sh && grep -c "prune_dangling" bootstrap.sh` → `6`.

### Step 2: Mark and prune generated TOML files in `sync-codex-agents.sh`

1. After the `DST=` line (line 6), add:

   ```bash
   # First line of every generated file. Files without it are never deleted.
   MARKER="# Generated by ~/.ai/scripts/sync-codex-agents.sh. Do not edit."
   ```

2. In the output block (line 64-65), add the marker as the first line:

   ```bash
     {
       echo "$MARKER"
       echo "name = \"$name\""
   ```

3. After the `done` of the final `for source` loop (line 82) and before
   `echo "Codex agents synced."`, add:

   ```bash

   # Remove generated agents whose source Markdown is gone.
   for target in "$DST"/*.toml; do
     [[ -f "$target" ]] || continue
     [[ "$(head -n 1 "$target")" == "$MARKER" ]] || continue
     [[ ! -f "$SRC/$(basename "$target" .toml).md" ]] || continue

     rm "$target"
     echo "Pruned: $target"
   done
   ```

**Verify**: `bash -n scripts/sync-codex-agents.sh && grep -c 'MARKER' scripts/sync-codex-agents.sh` → `3`.

### Step 3: Make the sync script reject frontmatter it cannot convert

In `sync_agent`, directly after the line
`description="$(frontmatter_value "description" "$source")"` and BEFORE the two
escape lines, add:

```bash
  # frontmatter_value reads one plain line. Quoted or multi-line YAML would
  # be copied into the TOML wrongly, so stop instead.
  case "$description" in
    ''|\"*|\'*|'>'*|'|'*)
      echo "Unsupported description in $source: use one plain unquoted line" >&2
      exit 1
      ;;
  esac
```

Directly after the `body="$( ... )"` assignment (ends at line 62) and before
the output block, add:

```bash
  if [[ "$body" == *"'''"* ]]; then
    echo "Agent body contains ''' and cannot be written as TOML: $source" >&2
    exit 1
  fi
```

**Verify**: `bash -n scripts/sync-codex-agents.sh && scripts/test.sh` →
`All 7 checks passed.` (all five current agents still convert).

### Step 4: Report leftovers in `doctor.sh`

Add this function directly after `check_link` (after line 75):

```bash
check_dangling() {
  local dir="$1"
  local link

  for link in "$dir"/*; do
    [[ -L "$link" && ! -e "$link" ]] || continue
    [[ "$(readlink "$link")" == "$AI_HOME"/* ]] || continue

    fail "Dangling link: $link (run bootstrap.sh)"
  done
}
```

Directly after the `done` of the skills loop (line 114), add:

```bash

check_dangling "$HOME/.claude/skills"
check_dangling "$HOME/.agents/skills"
check_dangling "$HOME/.agent/skills"
```

Directly after the `done` of the agents loop (line 136), add:

```bash

check_dangling "$HOME/.claude/agents"
check_dangling "$HOME/.gemini/config/agents"

for codex_agent in "$HOME"/.codex/agents/*.toml; do
  [[ -f "$codex_agent" ]] || continue
  [[ "$(head -n 1 "$codex_agent")" == "# Generated by ~/.ai/scripts/sync-codex-agents.sh."* ]] || continue
  [[ -f "$AI_HOME/agents/$(basename "$codex_agent" .toml).md" ]] ||
    fail "Orphan Codex agent: $codex_agent (run sync-codex-agents.sh)"
done
```

The marker text must be the same as `MARKER` in `sync-codex-agents.sh`, up to
and including `sync-codex-agents.sh.`.

**Verify**: `bash -n scripts/doctor.sh && scripts/test.sh` → `All 7 checks passed.`

### Step 5: Add tests to `scripts/test.sh`

Insert these two sections directly BEFORE the line
`echo "==> Doctor reports no failures"`:

```bash
echo "==> Removed skills and agents are cleaned up"

ln -s "$HOME/.ai/skills/gone" "$HOME/.claude/skills/x-gone"
ln -s "$HOME/.ai/agents/gone.md" "$HOME/.claude/agents/gone.md"
ln -s "$HOME/elsewhere" "$HOME/.claude/skills/foreign"
head -n 1 "$HOME/.codex/agents/builder.toml" > "$HOME/.codex/agents/gone.toml"
echo 'name = "mine"' > "$HOME/.codex/agents/mine.toml"

"$HOME/.ai/bootstrap.sh" >/dev/null

[[ ! -L "$HOME/.claude/skills/x-gone" ]] || die "Dangling skill link not pruned"
[[ ! -L "$HOME/.claude/agents/gone.md" ]] || die "Dangling agent link not pruned"
[[ ! -e "$HOME/.codex/agents/gone.toml" ]] || die "Orphan Codex agent not pruned"
[[ -L "$HOME/.claude/skills/foreign" ]] || die "Pruned a link that is not ours"
[[ -f "$HOME/.codex/agents/mine.toml" ]] || die "Pruned a Codex agent that is not ours"
pass "leftovers pruned, foreign files kept"

echo "==> Sync rejects frontmatter it cannot convert"

BAD_HOME="$TEST_HOME/bad-home"
mkdir -p "$BAD_HOME/.ai/agents"
printf -- '---\nname: bad\ndescription: "quoted"\n---\nbody\n' > "$BAD_HOME/.ai/agents/bad.md"

if HOME="$BAD_HOME" "$REPO/scripts/sync-codex-agents.sh" >/dev/null 2>&1; then
  die "sync accepted a quoted description"
fi
pass "unsupported frontmatter rejected"
```

**Verify**: `scripts/test.sh; echo "exit=$?"` → `All 9 checks passed.` and `exit=0`.

**Verify (the tests really test)**: temporarily comment out the three
`prune_dangling` skill calls in `bootstrap.sh`, run `scripts/test.sh` → it must
fail with `Dangling skill link not pruned`. Restore the lines and run again →
`All 9 checks passed.`

### Step 6: Update `README.md`

In the list under "What bootstrap does with files that already exist"
(`README.md:96-100`), after the `**Existing symlinks** are replaced.` bullet,
add:

```markdown
* **Leftovers of a renamed or deleted skill or agent** are removed: dangling symlinks that point into `~/.ai`, and generated `~/.codex/agents/*.toml` files whose source is gone. Files bootstrap did not create are left alone.
```

**Verify**: `grep -c "Leftovers of a renamed" README.md` → `1`.

## Test plan

- New test sections in `scripts/test.sh` (step 5):
  - a dangling skill link and a dangling agent link into `~/.ai` are removed;
  - a generated TOML with the marker and no source is removed;
  - a dangling link that points outside `~/.ai` is kept;
  - a TOML without the marker is kept;
  - a quoted `description` makes the sync script exit non-zero.
- The existing "Doctor reports no failures" section runs after these and
  proves doctor accepts the cleaned-up state.
- Verification: `scripts/test.sh` → `All 9 checks passed.`

## Done criteria

ALL must hold:

- [ ] `scripts/test.sh` exits 0 and prints `All 9 checks passed.`
- [ ] `for f in bootstrap.sh scripts/*.sh; do bash -n "$f" || echo FAIL; done` prints nothing
- [ ] `grep -c "prune_dangling" bootstrap.sh` → `6`
- [ ] `grep -c "check_dangling" scripts/doctor.sh` → `6`
- [ ] `git status --short` shows changes only in the in-scope files (plus the
      owner's files listed under "Out of scope")
- [ ] `plans/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- The code at the locations in "Current state" does not match the excerpts.
- `scripts/test.sh` does not exist. Plan 001 has not landed; this plan depends
  on it.
- Any change would delete something that is not a dangling symlink into
  `$AI_HOME` or a TOML file whose first line is the marker. The safety of this
  plan rests on those two conditions; do not widen them (for example, do not
  delete every `*.toml` without a source).
- The guard in step 3 rejects one of the existing files in `agents/`. Report
  the file and its `description` line. Do not edit the agent or loosen the guard.
- A verification fails twice after a reasonable fix attempt.

## Maintenance notes

- TOML files generated before this change have no marker. They get one the
  next time `sync-codex-agents.sh` or `bootstrap.sh` runs. An orphan generated
  before this change has no marker and must be deleted by hand once.
- The marker string lives in two files (`sync-codex-agents.sh` and
  `doctor.sh`). Change both together.
- If a new tool folder is added to `bootstrap.sh`, add a matching
  `prune_dangling` and `check_dangling` call.
- Plan 003 edits the same agent loop in `doctor.sh` and the `DST=` line in
  `sync-codex-agents.sh`. Land this plan first.
- A reviewer should read every `rm` in the diff and confirm the two conditions
  in front of it.
