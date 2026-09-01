#!/usr/bin/env bash

if ~/.ai/scripts/verify-project.sh >&2; then
  echo '{"decision":"allow"}'
else
  echo '{"decision":"block","reason":"Project verification failed. Fix reported errors before finishing."}'
fi
