#!/usr/bin/env bash

set -uo pipefail

AI_HOME="$HOME/.ai"

FAILURES=0
WARNINGS=0

ok() {
  printf '✓ %s\n' "$1"
}

warn() {
  printf '! %s\n' "$1"
  WARNINGS=$((WARNINGS + 1))
}

fail() {
  printf '✗ %s\n' "$1"
  FAILURES=$((FAILURES + 1))
}

section() {
  printf '\n==> %s\n' "$1"
}

resolve_path() {
  local path="$1"

  if command -v realpath >/dev/null 2>&1; then
    realpath "$path" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$path" 2>/dev/null
  else
    return 1
  fi
}

check_link() {
  local target="$1"
  local expected="$2"

  if [[ ! -e "$target" && ! -L "$target" ]]; then
    fail "Missing: $target"
    return
  fi

  if [[ ! -L "$target" ]]; then
    warn "Not symlink: $target"
    return
  fi

  if [[ ! -e "$target" ]]; then
    fail "Broken symlink: $target"
    return
  fi

  local resolved_target
  local resolved_expected

  resolved_target="$(resolve_path "$target" || true)"
  resolved_expected="$(resolve_path "$expected" || true)"

  if [[ -z "$resolved_target" || -z "$resolved_expected" ]]; then
    warn "Could not resolve symlink: $target"
    return
  fi

  if [[ "$resolved_target" == "$resolved_expected" ]]; then
    ok "$target -> $expected"
  else
    fail "$target points to $resolved_target, expected $resolved_expected"
  fi
}

section "Shared configuration"

for file in \
  "$AI_HOME/GLOBAL.md" \
  "$AI_HOME/bootstrap.sh"
do
  if [[ -f "$file" ]]; then
    ok "$file"
  else
    fail "Missing: $file"
  fi
done

section "Global context links"

check_link "$HOME/.claude/CLAUDE.md" "$AI_HOME/GLOBAL.md"
check_link "$HOME/.codex/AGENTS.md" "$AI_HOME/GLOBAL.md"
check_link "$HOME/.gemini/GEMINI.md" "$AI_HOME/GLOBAL.md"
check_link "$HOME/.copilot/copilot-instructions.md" "$AI_HOME/GLOBAL.md"

section "Shared skills"

for skill in "$AI_HOME"/skills/*; do
  [[ -d "$skill" ]] || continue

  name="$(basename "$skill")"

  if [[ ! -f "$skill/SKILL.md" ]]; then
    fail "$name missing SKILL.md"
    continue
  fi

  ok "$name"

  check_link "$HOME/.claude/skills/x-$name" "$skill"
  check_link "$HOME/.agents/skills/x-$name" "$skill"
  check_link "$HOME/.agent/skills/x-$name" "$skill"
done

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

section "Scripts"

for script in "$AI_HOME"/scripts/*.sh "$AI_HOME/bootstrap.sh"; do
  [[ -f "$script" ]] || continue

  name="$(basename "$script")"

  if [[ -x "$script" ]]; then
    ok "$name executable"
  else
    fail "$name not executable"
  fi

  if bash -n "$script" >/dev/null 2>&1; then
    ok "$name syntax"
  else
    fail "$name syntax error"
  fi
done

if command -v shellcheck >/dev/null 2>&1; then
  section "ShellCheck"

  for script in "$AI_HOME"/scripts/*.sh "$AI_HOME/bootstrap.sh"; do
    [[ -f "$script" ]] || continue

    name="$(basename "$script")"

    if shellcheck "$script" >/dev/null 2>&1; then
      ok "$name"
    else
      warn "$name has ShellCheck findings"
    fi
  done
fi

section "JSON configs"

if command -v jq >/dev/null 2>&1; then
  json_files=(
    "$HOME/.claude/settings.json"
    "$HOME/.gemini/antigravity-cli/settings.json"
    "$HOME/.gemini/config/hooks.json"
  )

  for file in "${json_files[@]}"; do
    [[ -f "$file" ]] || continue

    if jq empty "$file" >/dev/null 2>&1; then
      ok "$file"
    else
      fail "Invalid JSON: $file"
    fi
  done

  for file in "$HOME"/.copilot/hooks/*.json; do
    [[ -f "$file" ]] || continue

    if jq empty "$file" >/dev/null 2>&1; then
      ok "$file"
    else
      fail "Invalid JSON: $file"
    fi
  done
else
  warn "jq not installed; JSON validation skipped"
fi

section "Codex TOML"

if command -v python3 >/dev/null 2>&1 &&
   python3 -c 'import tomllib' >/dev/null 2>&1; then

  toml_files=("$HOME/.codex/config.toml")

  for file in "$HOME"/.codex/agents/*.toml; do
    [[ -f "$file" ]] && toml_files+=("$file")
  done

  for file in "${toml_files[@]}"; do
    [[ -f "$file" ]] || continue

    if python3 - "$file" <<'PY' >/dev/null 2>&1
import sys
import tomllib

with open(sys.argv[1], "rb") as f:
    tomllib.load(f)
PY
    then
      ok "$file"
    else
      fail "Invalid TOML: $file"
    fi
  done
else
  warn "Python tomllib unavailable; TOML validation skipped"
fi

section "Tools"

show_version() {
  local binary="$1"
  shift

  if ! command -v "$binary" >/dev/null 2>&1; then
    warn "$binary not installed"
    return
  fi

  local output
  output="$("$@" 2>&1 || true)"
  output="${output%%$'\n'*}"

  if [[ -n "$output" ]]; then
    ok "$binary: $output"
  else
    warn "$binary installed but version unavailable"
  fi
}

show_version claude claude --version
show_version codex codex --version
show_version agy agy --version
show_version rtk rtk --version
show_version ctx7 ctx7 --version
show_version playwright-cli playwright-cli --version

section "Claude integrations"

if command -v claude >/dev/null 2>&1; then
  plugin_output="$(claude plugin list 2>/dev/null || true)"

  if grep -q 'ponytail' <<<"$plugin_output"; then
    ok "Ponytail detected"
  else
    warn "Ponytail not detected"
  fi

  if grep -q 'typescript-lsp' <<<"$plugin_output"; then
    ok "TypeScript LSP detected"
  else
    warn "TypeScript LSP not detected"
  fi
fi

section "RTK"

if command -v rtk >/dev/null 2>&1; then
  rtk_output="$(rtk init --show 2>/dev/null || true)"

  if grep -q '\[ok\] Hook:' <<<"$rtk_output"; then
    ok "RTK Claude hook configured"
  else
    warn "RTK Claude hook not detected"
  fi

  gain_output="$(rtk gain 2>/dev/null || true)"

  if [[ -n "$gain_output" ]]; then
    saved_line="$(grep 'Tokens saved:' <<<"$gain_output" | head -n 1 || true)"

    if [[ -n "$saved_line" ]]; then
      ok "$saved_line"
    fi
  fi
else
  warn "rtk not installed"
fi

section "Bootstrap"

if [[ -x "$AI_HOME/bootstrap.sh" ]]; then
  ok "bootstrap.sh present and executable"

  if grep -q 'DRY_RUN' "$AI_HOME/bootstrap.sh"; then
    ok "bootstrap.sh declares DRY_RUN support"
  else
    warn "bootstrap.sh has no DRY_RUN support"
  fi

  printf '  Run manually when needed:\n'
  printf '  DRY_RUN=1 %s/bootstrap.sh\n' "$AI_HOME"
else
  fail "bootstrap.sh not executable"
fi

printf '\n==> Summary\n'
printf 'Failures: %d\n' "$FAILURES"
printf 'Warnings: %d\n' "$WARNINGS"

if (( FAILURES > 0 )); then
  exit 1
fi

exit 0
