#!/usr/bin/env bash

# Stop hook: block once on failure, then let Claude stop (avoids block loops).
if grep -q '"stop_hook_active" *: *true'; then
  exit 0
fi

# Claude only feeds stderr back on exit 2; send tsc output there.
if ! ~/.ai/scripts/verify-project.sh >&2; then
  echo "Verification failed. Fix reported errors before finishing." >&2
  exit 2
fi

exit 0
