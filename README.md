# Global AI Setup

Shared configuration for coding agents across Claude Code, Codex CLI, Antigravity, and Copilot.

Goal: configure common behavior once, reuse it everywhere, and keep project-specific knowledge inside each project.

## What This Setup Provides

* shared global agent instructions
* shared reusable skills
* shared specialized agents
* centralized bootstrap
* configuration health checks
* token-efficient tooling
* security boundaries outside model prompts

## Structure

```text
~/.ai/
├── GLOBAL.md
├── bootstrap.sh
│
├── agents/
│   ├── builder.md
│   ├── debugger.md
│   ├── frontend-validator.md
│   ├── security-reviewer.md
│   └── verifier.md
│
├── skills/
│   ├── ask-skill/
│   ├── bff-api-architecture-flow/
│   ├── bff-api-client/
│   ├── create-issue/
│   ├── design-patterns/
│   ├── design-system-board/
│   ├── find-docs/
│   ├── issue-comment/
│   ├── model-router/
│   ├── playwright-cli/
│   ├── preferred-stack/
│   ├── ship-check/
│   └── wait-what/
│
└── scripts/
    ├── sync-codex-agents.sh
    └── doctor.sh
```

`~/.ai` is source of truth. Provider directories reference or receive generated configuration from it.

## Quick Start

Clone repository as:

```bash
git clone <repo-url> ~/.ai
```

Make bootstrap executable:

```bash
chmod +x ~/.ai/bootstrap.sh
```

Preview changes:

```bash
DRY_RUN=1 ~/.ai/bootstrap.sh
```

Apply:

```bash
~/.ai/bootstrap.sh
```

Verify setup:

```bash
~/.ai/scripts/doctor.sh
```

Healthy result:

```text
==> Summary
Failures: 0
Warnings: 0
```

## Global Context

Canonical global instructions:

```text
~/.ai/GLOBAL.md
```

Provider files link to it:

```text
~/.claude/CLAUDE.md
~/.codex/AGENTS.md
~/.gemini/GEMINI.md
~/.copilot/copilot-instructions.md
        ↓
~/.ai/GLOBAL.md
```

`GLOBAL.md` contains only behavior useful across nearly every coding session:

* scope and judgment
* evidence-first investigation
* minimal implementation
* verification requirements
* safety
* concise technical communication

It intentionally excludes framework details, package preferences, project architecture, and provider-specific workflows.

## Skills

Reusable specialized instructions live under:

```text
~/.ai/skills/
```

### `x-preferred-stack`

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

### `x-find-docs`

Uses Context7 CLI for current framework/library/API documentation.

Use when implementation depends on version-specific behavior, configuration, migrations, setup, or library-specific debugging.

```bash
ctx7 library <name> "<query>"
ctx7 docs <library-id> "<query>"
```

### `x-bff-api-architecture-flow`

Chooses authentication architecture for React Router v7+ Framework Mode BFFs, external REST/Spring Boot/Elysia APIs, Valkey-backed web sessions, PostgreSQL-backed refresh tokens, and Expo mobile clients.

Covers three modes:

```text
external API, one token
API with access + refresh tokens
own full-stack monorepo
```

Constant across all three: API tokens stay server-side, the browser holds only an opaque session ID, `401` ends the session and `403` does not.

Use when implementing login, registration, session handling, access/refresh tokens, retry behavior, logout, token storage, or authorization boundaries.

### `x-bff-api-client`

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

### `x-create-issue`

User-invoked only. Creates one concise issue from the current conversation using a connected tracker MCP integration or an installed, authenticated CLI.

It supports Linear, Jira, Azure DevOps, GitHub, GitLab, and other configured trackers. If no publishing tool is available, it returns a title and body ready to paste.

### `x-issue-comment`

User-invoked only. Posts one short, professional comment on a tracker issue about the work done in the current conversation and branch.

```text
/x-issue-comment        short status update
/x-issue-comment qa     caveman-terse QA handoff: changed, test steps, regression risk
```

Describes behavior, not code. Uses the same tracker and tool detection as `x-create-issue`; prints the comment ready to paste if no tool is available.

### `x-design-patterns`

Finds the design pattern that fits a concrete situation, or rejects one when a plain TypeScript feature suffices. Catalog and rationale follow refactoring.guru; examples are rewritten as idiomatic TypeScript (functions, closures, discriminated unions) with the class form noted where it earns its place.

```text
SKILL.md                 symptom → pattern table, rules, anti-signals
references/<pattern>.md  intent, use when, do not use when, TS example, pitfalls, related
```

Use when structuring new code, refactoring conditionals, duplication, or coupling, reviewing an abstraction, or when a pattern is named.

### `x-playwright-cli`

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

### `x-ship-check`

User-invoked only. Final pre-launch verification for any product type: website, web app, internal tool, backend/API, worker, CLI, or mobile app. Detects the product type, runs the project's own checks, walks the matching checklists, and reports findings with evidence and a ship verdict. Changes nothing.

```text
/x-ship-check
/x-ship-check api https://staging.example.com
```

Report sections: Performance, Security, Best practices, UX, Maintainability, plus "Needs confirmation" for what the repo cannot prove (DNS, backups, store settings). Checklists live in `references/` (core, web, backend, mobile) and load by product type.

### `x-wait-what`

User-invoked only. Re-explains the last message as a smart caveman: short line, 3–6 steps, why, next action. Keeps real terms and `path:line` references. Runs on Haiku at low effort to save tokens. Pass the confusing part to narrow it.

```text
/x-wait-what
```

### `x-ask-skill`

User-invoked only. Reads the current session and recommends the best-fitting skill: shared `~/.ai` skills first (including manual-only ones the agent cannot see), other installed skills only when they fit better. Returns the pick, the exact command with arguments filled from context, at most one alternative, or "no skill needed". Never runs the pick without a yes. Pass a short problem to steer it.

```text
/x-ask-skill
```

### `x-design-system-board`

User-invoked only. Generates a design system documentation board (sections DS-00 to DS-05) with dark-theme, tech-blue defaults. Pass product, theme, or brand color to override the defaults.

```text
/x-design-system-board
```

### `x-model-router`

User-invoked only. Asks Jev (TypeSafe) which of the current host's available models best fits a task. Sends the task description and per-model criteria to `https://api.typesafe.ai/v1/systemone`; needs `TYPESAFE_API_KEY` in the environment.

```text
/x-model-router
```

## Agents

Canonical agents live under:

```text
~/.ai/agents/
```

### Debugger

Investigates failures and traces symptoms to root cause before recommending smallest fix.

### Frontend Validator

Validates changed UI behavior in browser, preferably using Playwright CLI.

### Security Reviewer

Reviews changed attack surface for concrete security vulnerabilities and trust-boundary problems.

### Builder

Implements a decided change (approved spec, known-cause fix, mechanical multi-file edit) on Haiku at medium effort, then stops. Spawned proactively; limited to Read, Edit, Write, Bash, and Skill.

### Verifier

Runs the feature, adds edge-case tests at high effort, reports problems without changing code.

Claude and Antigravity consume shared Markdown agent definitions directly.

Codex requires TOML definitions, generated from every `agents/*.md` (description and `codex-*` keys come from the frontmatter) with:

```bash
~/.ai/scripts/sync-codex-agents.sh
```

## Safety

Safety-critical behavior should not depend only on prompt instructions.

Provider-level permissions protect operations such as:

```text
git add / commit / push    → approval
force push                 → blocked
git reset --hard           → blocked
destructive git clean      → blocked
sensitive credential reads → blocked or approval
```

Exact provider configuration remains provider-specific.

## Token Efficiency

Setup uses two complementary tools:

**RTK** compresses shell/tool output.

**Ponytail** encourages smaller implementations, YAGNI, and fewer unnecessary abstractions.

They solve different problems and can be used together.

Context-heavy MCP servers are avoided when lightweight CLI/skill alternatives exist.

Examples:

```text
Context7 CLI   instead of Context7 MCP
Playwright CLI instead of Playwright MCP
```

## Project-Level Context

Global configuration must not describe individual projects.

Project owns:

* architecture
* domain terminology
* framework versions
* project commands
* deployment constraints
* feature specifications

OpenSpec is used for project-level specification and change workflows.

Separation:

```text
GLOBAL.md
→ universal behavior

global skills
→ reusable specialized knowledge

project context
→ repository-specific knowledge

OpenSpec
→ feature/change specifications
```

## Bootstrap

`bootstrap.sh` recreates shared links and generated configuration.

Preview:

```bash
DRY_RUN=1 ~/.ai/bootstrap.sh
```

Apply:

```bash
~/.ai/bootstrap.sh
```

Bootstrap does not own every provider setting. Provider-specific permissions, credentials, authentication, and local-only settings remain outside shared configuration unless explicitly templated.

## Doctor

Run health check:

```bash
~/.ai/scripts/doctor.sh
```

It validates:

* required files
* symlinks
* skills
* agents
* generated Codex agents
* script syntax and permissions
* JSON/TOML syntax
* important CLI availability
* selected integrations

Doctor is read-only.

## Maintenance

After changing shared agents:

```bash
~/.ai/scripts/sync-codex-agents.sh
```

After changing bootstrap:

```bash
bash -n ~/.ai/bootstrap.sh
DRY_RUN=1 ~/.ai/bootstrap.sh
```

After any setup change:

```bash
~/.ai/scripts/doctor.sh
```

Optional shell validation:

```bash
shellcheck ~/.ai/bootstrap.sh
shellcheck ~/.ai/scripts/*.sh
```

## Design Principles

Keep global context small.

Use skills for specialized knowledge.

Keep project context inside project.

Prefer existing provider capabilities over duplicate tooling.

Keep one canonical source whenever possible.

Avoid storing credentials, tokens, or machine-specific secrets in this repository.

## Summary

```text
                    ~/.ai/
                      │
          ┌───────────┼───────────┐
          │           │           │
      GLOBAL.md     skills      agents
          │           │           │
          └───────────┼───────────┘
                      │
              provider adapters
                      │
          Claude / Codex / Antigravity
```

This repository provides one maintainable configuration layer for multiple coding agents while keeping permanent context small and specialized behavior on demand.

## License

[MIT](LICENSE)
