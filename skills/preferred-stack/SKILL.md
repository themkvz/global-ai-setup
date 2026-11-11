---
name: x-preferred-stack
description: Preferred technologies, libraries, tooling, and code style defaults. Use before adding a dependency, scaffolding a project, picking between equivalent options, or writing new code where the project has no convention. Never use it to replace an existing project's established stack or style.
---

# Preferred Stack

Defaults for when the project has not already made the choice.

## Priority

1. Existing project architecture and dependencies.
2. Project-level specs and instructions.
3. This list.
4. General ecosystem defaults.

Do not migrate existing code to match these preferences. When a preference conflicts with the project, the project wins; when you deviate from this list, give the reason in one line. Mention this skill only when it explains a decision.

## Before adding a dependency

1. The project or the platform already covers it? Use that.
2. The project already has a competing library? Use that one.
3. It fits the current architecture and the benefit is concrete? Then add it, with the project's package manager.

Listed packages are preferences, not permission to install.

## TypeScript / JavaScript

| Concern | Prefer | Avoid introducing |
|---|---|---|
| Language | TypeScript | |
| Runtime and package manager | Bun (`bun`, `bunx`); latest stable Node.js where Bun is unsuitable | npm, yarn |
| Lint and format | Biome | ESLint, Prettier |
| Tests | Bun Test or Vitest | Jest |
| Validation | Valibot or Zod (TypeBox on the backend) | |
| Git hooks | `lefthook` | |
| Releases | `release-it` + `@release-it/conventional-changelog` | |

## Frontend

| Concern | Prefer | Avoid introducing |
|---|---|---|
| Web | React, React Router v7+ Framework Mode | |
| Mobile | Expo | |
| Styling and components | Tailwind CSS, shadcn/ui | styled-components, Material UI |
| Server state | TanStack Query (`@tanstack/react-query`, devtools) | |
| Client state | Zustand | Redux |
| URL state | `nuqs` | |
| Forms and route utilities | `remix-hook-form`, `remix-utils`, `remix-toast` | |
| Maps | `maplibre-gl` | |

Use platform and framework capabilities before adding another abstraction.

## Backend

| Concern | Prefer |
|---|---|
| Runtime | Bun |
| HTTP framework | Hono or Elysia |
| Database | PostgreSQL or MySQL; SQLite for small projects, local tools, and tests |
| ORM | Drizzle (`drizzle-orm`) |
| Logging | Pino |
| Env validation | `@t3-oss/env-*` |

## Shared utilities

- `ts-pattern` for exhaustive matching
- `better-result` for typed errors
- `date-fns` for dates
- `http-status-codes` instead of numeric literals
- `ofetch` for plain HTTP calls

## OpenAPI clients

Generate types with `openapi-typescript` and call through `openapi-fetch`. Do not add another generator unless the project already uses one. Preferred options:

```bash
openapi-typescript <spec> -o <out> --enum --dedupe-enums --enum-values --make-paths-enum
```

## Code style defaults

For new code when the project has no convention.

General:

- Strict type checking; lint + format in a pre-commit hook; example env file. Containerize deployable services.
- Organize by feature/domain; each feature owns its data access, validation, and UI. Shared generic code in a common layer. Backend: separate routes, handlers, and validation.
- Named constants instead of magic numbers, with the unit in the name or comment. `is`/`has` booleans.
- Validate every external input (env, forms, requests, API responses) with a schema kept next to its inferred type. Generate types from the source of truth (OpenAPI, DB schema).
- Early returns; small pure functions; immutable updates; independent async work in parallel.
- Errors: reads may log with context and return a safe fallback; writes must surface failure. The HTTP layer maps failures to status codes and user-facing messages.
- Security: hashed passwords, httpOnly/secure cookies, generic auth errors, no stack traces in production.
- Tests: cover the risky core (state logic, auth, error handling), not coverage numbers. Behavior-named, integration-style where practical. Add a regression test with bug fixes.

TypeScript/JavaScript:

- 2-space indent, single quotes, no semicolons, ~100 line width, sorted imports, path aliases over deep relative imports.
- kebab-case files, PascalCase components/types, camelCase functions/variables, SCREAMING_SNAKE constants, `handle` event handlers, `use` hooks.
- Functions and closures over classes.
- Frontend state: URL for navigation state, query cache for server state, a small store for client-only state.
- Accessible UI components with variant-based APIs.

Avoid:

- Returning an un-awaited promise inside try/catch, so the catch never fires.
- Repeated markup instead of mapping over data.
- Mixed languages in user-facing text.
