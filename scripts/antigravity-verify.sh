#!/usr/bin/env bash

# Antigravity sends hook metadata through stdin.
cat >/dev/null

if ~/.ai/scripts/verify-project.sh >&2; then
  echo '{"decision":"allow"}'
else
  echo '{"decision":"continue","reason":"Project verification failed. Fix reported errors before finishing."}'
fi
