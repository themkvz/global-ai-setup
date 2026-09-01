#!/usr/bin/env bash

set -euo pipefail

SRC="$HOME/.ai/agents"
DST="$HOME/.codex/agents"

mkdir -p "$DST"

sync_agent() {
  local name="$1"
  local description="$2"
  local source="$SRC/$name.md"
  local target="$DST/$name.toml"

  if [[ ! -f "$source" ]]; then
    echo "Missing: $source" >&2
    return 1
  fi

  # Strip YAML frontmatter from shared Markdown agent.
  body="$(
    awk '
      BEGIN { frontmatter = 0; done = 0 }

      NR == 1 && $0 == "---" {
        frontmatter = 1
        next
      }

      frontmatter && $0 == "---" {
        frontmatter = 0
        done = 1
        next
      }

      !frontmatter && done {
        print
      }
    ' "$source"
  )"

  cat > "$target" <<EOF
name = "$name"
description = "$description"
sandbox_mode = "read-only"

developer_instructions = """
$body
"""
EOF

  echo "Synced: $target"
}

sync_agent \
  "debugger" \
  "Investigates bugs, errors, failing tests, and unexpected behavior. Finds root cause before recommending the smallest fix."

sync_agent \
  "frontend-validator" \
  "Validates changed frontend behavior in a real browser using available browser automation."

sync_agent \
  "security-reviewer" \
  "Reviews security-sensitive changes for concrete exploitable vulnerabilities and trust-boundary problems."

echo "Codex agents synced."
