# Global AI Setup

Shared configuration for coding agents across Claude Code, Codex CLI, Antigravity, and Copilot.

Goal: configure common behavior once, reuse it everywhere, and keep project-specific knowledge inside each project.

## What This Setup Provides

* shared global agent instructions
* shared reusable skills
* shared specialized agents
* automatic project verification
* provider-specific verification hooks
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
│   ├── debugger.md
│   ├── frontend-validator.md
│   └── security-reviewer.md
│
├── skills/
│   ├── find-docs/
│   ├── playwright-cli/
│   └── preferred-stack/
│
└── scripts/
    ├── verify-project.sh
    ├── claude-verify.sh
    ├── codex-verify.sh
    ├── antigravity-verify.sh
    ├── copilot-verify.sh
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

### `preferred-stack`

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
→ preferred-stack
→ ecosystem defaults
```

Existing project architecture always wins.

### `find-docs`

Uses Context7 CLI for current framework/library/API documentation.

Use when implementation depends on version-specific behavior, configuration, migrations, setup, or library-specific debugging.

```bash
ctx7 library <name> "<query>"
ctx7 docs <library-id> "<query>"
```

### `playwright-cli`

Provides browser automation for frontend validation:

* navigation
* forms
* interactions
* console errors
* network failures
* screenshots
* user flows

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

Claude and Antigravity consume shared Markdown agent definitions directly.

Codex requires TOML definitions, generated with:

```bash
~/.ai/scripts/sync-codex-agents.sh
```

## Verification

Shared verifier:

```text
~/.ai/scripts/verify-project.sh
```

Provider hooks call this script when coding work completes.

```text
Claude ────────┐
Codex ─────────┤
Antigravity ───┼─→ verify-project.sh
Copilot ───────┘
```

Current checks include:

```text
git diff --check
package-manager detection
project-defined typecheck
optional full test suite
```

Run manually:

```bash
~/.ai/scripts/verify-project.sh
```

Run with full tests:

```bash
VERIFY_FULL_TESTS=1 ~/.ai/scripts/verify-project.sh
```

Verification is intentionally non-mutating. It reports problems rather than silently fixing them.

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

Prefer deterministic hooks over hoping model follows validation instructions.

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
                      │
                 verification
```

This repository provides one maintainable configuration layer for multiple coding agents while keeping permanent context small and specialized behavior on demand.
