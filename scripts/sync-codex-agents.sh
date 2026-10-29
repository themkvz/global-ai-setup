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
  local source="$1"
  local name target description
  name="$(basename "$source" .md)"
  target="$DST/$name.toml"

  # Escape for a TOML basic string.
  description="$(frontmatter_value "description" "$source")"
  description="${description//\\/\\\\}"
  description="${description//\"/\\\"}"

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
