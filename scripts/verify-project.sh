#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------
# Git repository
# ------------------------------------------------------------

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside Git repository. Skip verification."
  exit 0
fi

ROOT="$(git rev-parse --show-toplevel)"

echo "==> Verifying project: $ROOT"

# Do not cd to Git root.
# Current directory may be a package inside a monorepo.

# ------------------------------------------------------------
# Git validation
# ------------------------------------------------------------

echo "==> git diff --check"
git diff --check

# ------------------------------------------------------------
# JS/TS project detection
# ------------------------------------------------------------

if [[ ! -f package.json ]]; then
  echo "==> No package.json in current directory. Skip JS/TS checks."
  echo "==> Verification passed"
  exit 0
fi

# ------------------------------------------------------------
# Package manager
# ------------------------------------------------------------

if [[ -f bun.lock || -f bun.lockb ]]; then
  PM="bun"
elif [[ -f pnpm-lock.yaml ]]; then
  PM="pnpm"
elif [[ -f yarn.lock ]]; then
  PM="yarn"
elif [[ -f package-lock.json ]]; then
  PM="npm"
else
  echo "==> No lock file found. Skip package scripts."
  echo "==> Verification passed"
  exit 0
fi

if [[ ! -d node_modules ]]; then
  echo "==> No node_modules. Skip package scripts."
  exit 0
fi

if ! command -v "$PM" >/dev/null 2>&1; then
  echo "Package manager '$PM' not installed." >&2
  exit 1
fi

echo "==> Package manager: $PM"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

has_script() {
  local script="$1"

  if command -v node >/dev/null 2>&1; then
    node -e "
      const p = require('./package.json');
      process.exit(p.scripts?.['$script'] ? 0 : 1);
    "
  elif command -v bun >/dev/null 2>&1; then
    bun -e "
      const p = await Bun.file('package.json').json();
      process.exit(p.scripts?.['$script'] ? 0 : 1);
    "
  else
    return 1
  fi
}

run_script() {
  local script="$1"

  case "$PM" in
    bun)
      bun run "$script"
      ;;
    pnpm)
      pnpm run "$script"
      ;;
    yarn)
      yarn "$script"
      ;;
    npm)
      npm run "$script"
      ;;
  esac
}

# ------------------------------------------------------------
# Type checking
# ------------------------------------------------------------

if has_script "typecheck"; then
  echo "==> Typecheck"
  run_script "typecheck"

elif has_script "type-check"; then
  echo "==> Typecheck"
  run_script "type-check"

elif has_script "check-types"; then
  echo "==> Typecheck"
  run_script "check-types"

elif has_script "ts"; then
  echo "==> Typecheck"
  run_script "ts"

else
  echo "==> No typecheck script found. Skip."
fi

# ------------------------------------------------------------
# Optional full test suite
# ------------------------------------------------------------

if [[ "${VERIFY_FULL_TESTS:-0}" == "1" ]]; then
  if has_script "test"; then
    echo "==> Full test suite"
    run_script "test"
  else
    echo "==> No test script found. Skip."
  fi
fi

echo "==> Verification passed"
