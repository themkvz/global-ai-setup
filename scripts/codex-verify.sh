#!/usr/bin/env bash

if ! ~/.ai/scripts/verify-project.sh >&2; then
  echo "Verification failed. Fix reported errors before finishing." >&2
  exit 2
fi

exit 0
