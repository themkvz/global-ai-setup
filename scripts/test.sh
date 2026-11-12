#!/usr/bin/env bash

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

mkdir -p "$TEST_HOME/.ai"
cp -R "$REPO/GLOBAL.md" "$REPO/bootstrap.sh" "$REPO/agents" "$REPO/skills" "$REPO/scripts" "$TEST_HOME/.ai/"

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

env HOME="$TEST_HOME" DRY_RUN=1 "$TEST_HOME/.ai/bootstrap.sh" >/dev/null
for dir in .claude .codex .gemini .copilot .agents .agent; do
  [[ ! -e "$TEST_HOME/$dir" ]] || die "Dry run created $dir"
done
pass "dry run wrote nothing"

echo "==> Bootstrap creates links and keeps a backup"

mkdir -p "$TEST_HOME/.codex"
echo "old instructions" > "$TEST_HOME/.codex/AGENTS.md"
env HOME="$TEST_HOME" "$TEST_HOME/.ai/bootstrap.sh" >/dev/null

assert_link "$TEST_HOME/.claude/CLAUDE.md" "$TEST_HOME/.ai/GLOBAL.md"
assert_link "$TEST_HOME/.codex/AGENTS.md" "$TEST_HOME/.ai/GLOBAL.md"
assert_link "$TEST_HOME/.gemini/GEMINI.md" "$TEST_HOME/.ai/GLOBAL.md"
assert_link "$TEST_HOME/.copilot/copilot-instructions.md" "$TEST_HOME/.ai/GLOBAL.md"
pass "global context links"

[[ "$(cat "$TEST_HOME/.codex/AGENTS.md.backup")" == "old instructions" ]] || die "Backup missing"
pass "existing file backed up"

for skill in "$TEST_HOME"/.ai/skills/*/; do
  name="$(basename "$skill")"
  for dir in .claude/skills .agents/skills .agent/skills; do
    assert_link "$TEST_HOME/$dir/x-$name" "$TEST_HOME/.ai/skills/$name"
  done
done
pass "skill links"

for agent in "$TEST_HOME"/.ai/agents/*.md; do
  name="$(basename "$agent")"
  assert_link "$TEST_HOME/.claude/agents/$name" "$agent"
  assert_link "$TEST_HOME/.gemini/config/agents/$name" "$agent"
  [[ -s "$TEST_HOME/.codex/agents/${name%.md}.toml" ]] || die "Missing Codex agent: ${name%.md}.toml"
done
pass "agent links and Codex agents"

echo "==> Bootstrap is safe to run twice"

env HOME="$TEST_HOME" "$TEST_HOME/.ai/bootstrap.sh" >/dev/null
assert_link "$TEST_HOME/.claude/CLAUDE.md" "$TEST_HOME/.ai/GLOBAL.md"
[[ "$(cat "$TEST_HOME/.codex/AGENTS.md.backup")" == "old instructions" ]] || die "Backup changed"
pass "second run"

echo "==> Doctor reports no failures"

env HOME="$TEST_HOME" PATH="/usr/bin:/bin" "$TEST_HOME/.ai/scripts/doctor.sh" > "$TEST_HOME/doctor.log" ||
  { cat "$TEST_HOME/doctor.log"; die "doctor.sh failed"; }
grep -q '^Failures: 0$' "$TEST_HOME/doctor.log" || die "doctor.sh reported failures"
pass "doctor"

printf '\nAll %d checks passed.\n' "$CHECKS"
