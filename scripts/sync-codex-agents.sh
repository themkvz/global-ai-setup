#!/usr/bin/env bash

set -euo pipefail

SRC="$HOME/.ai/agents"
DST="$HOME/.codex/agents"

mkdir -p "$DST"

# Read a single "key: value" line from the source's YAML frontmatter.
frontmatter_value() {
  local key="$1" file="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { fm = 1; next }
    fm && $0 == "---" { exit }
    fm && $0 ~ "^" key ": " {
      sub("^" key ": *", "")
      print
      exit
    }
  ' "$file"
}

sync_agent() {
  local name="$1"
  local description="$2"
  local source="$SRC/$name.md"
  local target="$DST/$name.toml"

  if [[ ! -f "$source" ]]; then
    echo "Missing: $source" >&2
    return 1
  fi

  # Codex-specific model/effort, set via the x-model-router skill scoped to
  # Codex's own catalog. Absent means: inherit Codex's default model/effort.
  local codex_model codex_effort codex_sandbox
  codex_model="$(frontmatter_value "codex-model" "$source")"
  codex_effort="$(frontmatter_value "codex-effort" "$source")"
  codex_sandbox="$(frontmatter_value "codex-sandbox" "$source")"

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

  {
    echo "name = \"$name\""
    echo "description = \"$description\""
    [[ -n "$codex_model" ]] && echo "model = \"$codex_model\""
    [[ -n "$codex_effort" ]] && echo "model_reasoning_effort = \"$codex_effort\""
    echo "sandbox_mode = \"${codex_sandbox:-read-only}\""
    echo
    echo "developer_instructions = \"\"\""
    echo "$body"
    echo "\"\"\""
  } > "$target"

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

sync_agent \
  "builder" \
  "Implements an approved feature spec exactly as written, then stops."

sync_agent \
  "verifier" \
  "Verifies an implemented feature by running it first, then adding edge-case tests. Reports problems; never changes implementation code."

echo "Codex agents synced."
