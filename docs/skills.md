# Skills

Shared skills live in `skills/<name>/SKILL.md`. `bootstrap.sh` links each one as `x-<name>` into `~/.claude/skills/`, `~/.agents/skills/` and `~/.agent/skills/`.

Skills marked **user-invoked only** set `disable-model-invocation: true`: the agent will not load them on its own, you run them with `/x-<name>`.

## `x-preferred-stack`

Provides preferred defaults when project does not already establish another choice.

Examples:

* TypeScript
* Bun
* Biome
* React
* React Router
* Tailwind CSS
* shadcn/ui
* Zustand
* TanStack Query
* Hono / Elysia
* Drizzle ORM
* PostgreSQL / MySQL / SQLite

Priority:

```text
existing project
→ project instructions/spec
→ x-preferred-stack
→ ecosystem defaults
```

Existing project architecture always wins.

## `x-find-docs`

Uses Context7 CLI for current framework/library/API documentation.

Use when implementation depends on version-specific behavior, configuration, migrations, setup, or library-specific debugging.

```bash
ctx7 library <name> "<query>"
ctx7 docs <library-id> "<query>"
```

## `x-bff-api-architecture-flow`

Chooses authentication architecture for React Router v7+ Framework Mode BFFs, external REST/Spring Boot/Elysia APIs, Valkey-backed web sessions, PostgreSQL-backed refresh tokens, and Expo mobile clients.

Covers three modes:

```text
external API, one token
API with access + refresh tokens
own full-stack monorepo
```

Constant across all three: API tokens stay server-side, the browser holds only an opaque session ID, `401` ends the session and `403` does not.

Use when implementing login, registration, session handling, access/refresh tokens, retry behavior, logout, token storage, or authorization boundaries.

## `x-bff-api-client`

Wires the server-side API client inside a React Router v7+ Framework Mode BFF.

```text
createApiClient()   per-request factory
apiClientContext    React Router context
requireSession      middleware builds client, sets context
<domain>.server.ts  one thin fn per endpoint
route loader        reads client from context
```

The route never builds a client and never sees a token, so auth headers, `401` handling, correlation IDs, timeouts, and logging stay in one file.

Use when adding an API call to a loader, action, or resource route, adding an endpoint wrapper, creating a protected or guest route layout, writing auth middleware, or testing a wrapper or loader.

## `x-create-issue`

User-invoked only. Creates one concise issue from the current conversation using a connected tracker MCP integration or an installed, authenticated CLI.

It supports Linear, Jira, Azure DevOps, GitHub, GitLab, and other configured trackers. If no publishing tool is available, it returns a title and body ready to paste.

## `x-issue-comment`

User-invoked only. Posts one short, professional comment on a tracker issue about the work done in the current conversation and branch.

```text
/x-issue-comment        short status update
/x-issue-comment qa     caveman-terse QA handoff: changed, test steps, regression risk
```

Describes behavior, not code. Uses the same tracker and tool detection as `x-create-issue`; prints the comment ready to paste if no tool is available.

## `x-design-patterns`

Finds the design pattern that fits a concrete situation, or rejects one when a plain TypeScript feature suffices. Catalog and rationale follow refactoring.guru; examples are rewritten as idiomatic TypeScript (functions, closures, discriminated unions) with the class form noted where it earns its place.

```text
SKILL.md                 symptom → pattern table, rules, anti-signals
references/<pattern>.md  intent, use when, do not use when, TS example, pitfalls, related
```

Use when structuring new code, refactoring conditionals, duplication, or coupling, reviewing an abstraction, or when a pattern is named.

## `x-playwright-cli`

Provides browser automation for frontend validation:

* navigation
* forms
* interactions
* console errors
* network failures
* screenshots
* user flows

The body and `references/` are a copy of the skill bundled with `@playwright/cli`; only the frontmatter and the `Local rules` section are ours. To sync after a CLI update:

```bash
bun add -g @playwright/cli@latest
src=~/.bun/install/global/node_modules/@playwright/cli/skills/playwright-cli
diff -r "$src" ~/.ai/skills/playwright-cli   # review, then copy the changed upstream files
```

Keep `name: x-playwright-cli`, the local description and `allowed-tools`, and the `Local rules` section.

## `x-ship-check`

User-invoked only. Final pre-launch verification for any product type: website, web app, internal tool, backend/API, worker, CLI, or mobile app. Detects the product type, runs the project's own checks, walks the matching checklists, and reports findings with evidence and a ship verdict. Changes nothing.

```text
/x-ship-check
/x-ship-check api https://staging.example.com
```

Report sections: Performance, Security, Best practices, UX, Maintainability, plus "Needs confirmation" for what the repo cannot prove (DNS, backups, store settings). Checklists live in `references/` (core, web, backend, mobile) and load by product type.

## `x-wait-what`

User-invoked only. Re-explains the last message as a smart caveman: short line, 3–6 steps, why, next action. Keeps real terms and `path:line` references. Runs at low effort to save tokens. Pass the confusing part to narrow it.

```text
/x-wait-what
```

## `x-ask-skill`

User-invoked only. Reads the current session and recommends the best-fitting skill: shared `~/.ai` skills first (including manual-only ones the agent cannot see), other installed skills only when they fit better. Returns the pick, the exact command with arguments filled from context, at most one alternative, or "no skill needed". Never runs the pick without a yes. Pass a short problem to steer it.

```text
/x-ask-skill
```

## `x-design-system-board`

User-invoked only. Generates a design system documentation board (sections DS-00 to DS-05) with dark-theme, tech-blue defaults. Pass product, theme, or brand color to override the defaults.

```text
/x-design-system-board
```

## `x-model-router`

User-invoked only. Asks Jev (TypeSafe) which of the current host's available models best fits a task. Sends the task description and per-model criteria to `https://api.typesafe.ai/v1/systemone`; needs `TYPESAFE_API_KEY` in the environment.

```text
/x-model-router
```

