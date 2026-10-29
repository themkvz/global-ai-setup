---
name: x-ship-check
description: "Final pre-launch verification of a product: website, web app, internal tool, backend/API, worker, CLI, or mobile app. Checks performance, security, best practices, UX, and maintainability with evidence, then gives a ship verdict. Report only; changes nothing."
argument-hint: "[path or product type] [staging URL] [focus]"
disable-model-invocation: true
---

# Ship Check

A last check before release. Find what will hurt users, leak data, or wake someone up at 3am, and prove each finding. Report only: do not edit code, config, or git state.

## Rules

- **Evidence or nothing.** Every finding points to `file:line`, a config key, a command result, or a response header. No generic advice that the project does not need.
- **Run before you read.** The project's own lint, type check, tests, build, and dependency audit give facts. Read code for what tools cannot check.
- **Four states per check:** Pass, Fail, N/A (say why), Not verified (say why). Never mark Pass what you could not see. DNS, SSL coverage, backups, on-call people, and store settings usually live outside the repo: list them under "Needs confirmation".
- **Project budgets win.** Thresholds in the references are defaults. Use the project's own budgets, SLOs, or Lighthouse config when they exist.
- **Never print secrets.** Report location and key type only. Use the redacted commands in `references/core.md`.
- **No outward impact without asking.** Local commands and a few read-only requests to a URL the user gave are fine (`curl -sI`, Lighthouse). Ask first before load tests, active scanners (OWASP ZAP active scan), anything that writes data, or many requests to production.
- **Read a script before you run it.** Test, build, and `pre`/`post` hooks can migrate, seed, deploy, publish, or call whatever `DATABASE_URL` or API the local `.env` points to. Skip such a script, or ask first, and record it as Not verified.
- **No new dependencies.** Prefer tools already installed. One-off runners (`npx`, `bunx`, `uvx`) are fine for read-only scanners.
- **Fewer real findings beat many weak ones.** Do not inflate severity. Separate real problems from nice-to-have hardening.

## Process

1. **Scope.** Arguments win: a path, a product type, a staging URL, or a focus. Otherwise check the whole repo.
2. **Detect product types** from evidence: `package.json` dependencies, framework config, `Dockerfile`, `app.json`/`eas.json`, `ios/`/`android/`, `pubspec.yaml`, OpenAPI files, `bin` entries. A repo can have several (for example, Expo app + API). Also decide the audience: public, or internal behind login. State the result in one line.
3. **Load references.** Always `references/core.md`. Then:
   - `references/web.md` for anything that runs in a browser. Internal tools skip the SEO part but must not be indexed.
   - `references/backend.md` for APIs, services, workers, and CLIs.
   - `references/mobile.md` for iOS, Android, React Native, Expo, Flutter.
4. **Run checks.** Use the project's scripts and package manager: lint, type check, tests, production build (note bundle or binary size), dependency audit. If a check cannot run, record it as Not verified with the error.
5. **Read the risky core first:** auth, payments, data writes, public inputs, file uploads, the first screen, and the main user flow. Then walk the reference checklists. Mark each item that applies.
6. **Live checks** (optional), only on a URL the user gave or a local server. Reuse a running server; stop any server you started.
7. **Go deeper when needed** (optional). If available: the `security-reviewer` agent for auth, payments, or sensitive data; `frontend-validator` or `x-playwright-cli` to click through the main UI flow.
8. **Report** in the format below. Then offer to fix the Blockers and High findings. Do not fix anything without approval.

## Severity

- **Blocker**: do not ship. Security hole, data loss, secret leak, main flow broken, crash on start, store rejection.
- **High**: fix before launch, or ship only with a written reason. Real user or ops harm.
- **Medium**: fix soon after launch.
- **Low**: polish or hardening with a concrete benefit.

## Report format

```markdown
# Ship check: <product> (<types>, <public | internal>)

**Verdict:** Ship | Ship after fixes | Don't ship. <One sentence: why.>
**Findings:** <n> Blocker, <n> High, <n> Medium, <n> Low.

## Checks run
- `<command>`: <pass | fail | could not run>, <one-line result>

## Performance
- [Severity] `file:line` — <title>
  <What is wrong and who it hurts.> Fix: <smallest fix.>

## Security
## Best practices
## UX
## Maintainability

## Needs confirmation
- <Item you cannot check from here, and who or what can confirm it.>

## Not verified
- <Check you could not run, and why.>
```

Rules for the report:

- Sort findings by severity inside each section. Write `No issues found.` under a section that has none.
- Best practices covers ops and release: config, monitoring, logging, migrations, backups, rollback, CI, SEO, store and legal requirements.
- UX covers what a person meets: accessibility, error, empty, and loading states, error pages, responsive layout, forms. For an API or CLI, the "user" is the developer who calls it: error format, status codes, exit codes, help text, docs.
- Do not list passed checks one by one. The summary line and "Checks run" are enough.

## Example finding

```markdown
- [Blocker] `src/routes/orders.ts:42` — Any logged-in user can read any order
  `GET /orders/:id` loads the order by ID and never compares `order.userId` with the session user. Fix: add `where userId = session.userId` to the query.
```
