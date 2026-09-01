#!/usr/bin/env bash

set -euo pipefail

AI_HOME="$HOME/.ai"

if [[ ! -f "$AI_HOME/GLOBAL.md" ]]; then
  echo "Missing $AI_HOME/GLOBAL.md" >&2
  exit 1
fi

backup_and_link() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" ]]; then
    rm "$target"
  elif [[ -e "$target" ]]; then
    local backup="${target}.backup"
    echo "Backing up: $target -> $backup"
    mv "$target" "$backup"
  fi

  ln -s "$source" "$target"
  echo "Linked: $target -> $source"
}

link_dir() {
  local source="$1"
  local target="$2"

  [[ -d "$source" ]] || return 0

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" ]]; then
    rm "$target"
  elif [[ -e "$target" ]]; then
    echo "Skip existing non-symlink: $target"
    return 0
  fi

  ln -s "$source" "$target"
  echo "Linked: $target -> $source"
}

echo "==> Global context"

backup_and_link "$AI_HOME/GLOBAL.md" "$HOME/.claude/CLAUDE.md"
backup_and_link "$AI_HOME/GLOBAL.md" "$HOME/.codex/AGENTS.md"
backup_and_link "$AI_HOME/GLOBAL.md" "$HOME/.gemini/GEMINI.md"
backup_and_link "$AI_HOME/GLOBAL.md" "$HOME/.copilot/copilot-instructions.md"

echo
echo "==> Shared skills"

for skill in "$AI_HOME"/skills/*; do
  [[ -d "$skill" ]] || continue

  name="$(basename "$skill")"

  link_dir "$skill" "$HOME/.claude/skills/$name"
  link_dir "$skill" "$HOME/.agents/skills/$name"
  link_dir "$skill" "$HOME/.agent/skills/$name"
done

echo
echo "==> Shared agents"

for agent in "$AI_HOME"/agents/*.md; do
  [[ -f "$agent" ]] || continue

  name="$(basename "$agent")"

  backup_and_link "$agent" "$HOME/.claude/agents/$name"
  backup_and_link "$agent" "$HOME/.gemini/config/agents/$name"
done

echo
echo "==> Codex agents"

if [[ -x "$AI_HOME/scripts/sync-codex-agents.sh" ]]; then
  "$AI_HOME/scripts/sync-codex-agents.sh"
else
  echo "Skip: sync-codex-agents.sh not found or not executable"
fi

echo
echo "==> Scripts"

if [[ -d "$AI_HOME/scripts" ]]; then
  chmod +x "$AI_HOME"/scripts/*.sh 2>/dev/null || true
fi

echo
echo "AI bootstrap complete."
