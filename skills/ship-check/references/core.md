# Core checks (every product)

## Performance

- Production build uses production mode: no debug flags, dev servers, verbose logging, or source-level hot reload.
- Slow or heavy work does not block the request, UI thread, or startup. It runs in the background, in a queue, or lazily.
- Lists and queries that can grow have limits or pagination.

## Security

- **No secrets in the repo or its history.** `.env` and similar files are in `.gitignore`. Scan with redaction; these commands print locations only, never values:
  - `gitleaks git --redact .` if installed (before v8.19: `gitleaks detect --redact`).
  - `trufflehog` has no redact flag and prints raw values. Use it only through JSON and keep the location: `trufflehog git file://. --json --no-verification | jq -c '{d: .DetectorName, s: .SourceMetadata.Data.Git | {commit, file, line}}'`
  - Fallback, current files: `git grep -nIiE '(api[_-]?key|secret|token|passw(or)?d|private[_-]?key|BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16}|sk_live_|ghp_|xox[abprs]-)' | cut -d: -f1,2`
  - Fallback, history: `git log --all -i -G '<same pattern>' --format='%h' --name-only`
  - A hit is a lead, not a finding. Open the location and check if it is a real value or a variable name. A real secret in history is a Blocker even if it was deleted later: it must be rotated.
- **Nothing secret ships to the client.** Every value in a browser bundle or app binary is public. Check public env prefixes (`NEXT_PUBLIC_`, `VITE_`, `EXPO_PUBLIC_`, `REACT_APP_`) and build output.
- **Dependencies:** audit with the project's tool (`npm audit`, `pnpm audit`, `bun audit`, `pip-audit`, `cargo audit`, `govulncheck`, `bundle audit`, `osv-scanner`). Critical or High in production dependencies with a reachable path = finding. Dev-only tools are Low at most.
- **Input:** every external input is validated on the server: request bodies, query strings, headers, files, webhooks, env vars, third-party API responses.
- **Auth:** every protected action checks who the user is and that they may touch this object (no IDOR). Passwords hashed with argon2, bcrypt, or scrypt. Login and reset errors are generic.
- **Errors and logs:** no stack traces or internal details shown to users in production. Logs contain no passwords, tokens, or full personal data.
- **Least privilege:** database users, API tokens, cloud roles, and service accounts have only the access they need.

## Best practices

- **Config:** all environment config comes from env or a secret manager, is validated at startup, and is documented in an example env file.
- **Monitoring:** error tracking (Sentry or similar) with alerts to a real person. Uptime or health checks for anything that runs all the time.
- **Logs:** structured, with a request or correlation ID, at a sane level for production.
- **Data safety:** backups exist and a restore was tested. A fresh backup is taken before a migration. Migrations are backward compatible, or the deploy order is planned.
- **Rollback:** the previous version can be redeployed fast. Feature flags or a kill switch for risky features.
- **CI:** lint, type check, tests, and build run on every change to the main branch. Deploys come from CI, not laptops.
- **Legal:** privacy policy and terms if the product collects personal data. Cookie or tracking consent where the law requires it. Licenses of dependencies allow this use.
- **Launch day** (usually Needs confirmation): someone owns the launch and can respond; the team knows how to roll back; status page or support channel is ready.

## UX

- Error messages say what happened and what to do next, in the product's language. No raw codes or exceptions.
- No dead ends: every error or empty state offers a way forward.
- Destructive actions ask for confirmation or can be undone.

## Maintainability

- Lint, format check, and type check pass with strict settings. No new ignore comments or `any` to hide problems.
- Tests exist for the risky core (auth, money, state changes, data writes) and pass. Coverage numbers do not matter; the risky paths do.
- README explains how to set up, run, test, and deploy. A new developer can start in one or two commands.
- Lockfile is committed. Dependencies are maintained, not abandoned or far behind on major versions with known issues.
- No commented-out code, stray debug logs, or TODOs on the critical path.
- Structure is clear enough that the next person can find where a feature lives.
