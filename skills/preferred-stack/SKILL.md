---
name: preferred-stack
description: Apply preferred technologies, libraries, and tooling when choosing dependencies, starting greenfield projects, designing architecture, or selecting between equivalent implementation options. Do not use to replace an existing project's established stack without explicit reason.
---

# Preferred Stack

Use these as defaults when project does not already establish another choice.

## Priority

Follow this order:

1. Existing project architecture and dependencies.
2. Project-level specs and instructions.
3. This preferred stack.
4. General ecosystem defaults.

Do not migrate existing code only to match these preferences.

Do not add a dependency when existing project code or platform APIs solve problem cleanly.

## JavaScript / TypeScript

Prefer:

* TypeScript
* Bun runtime where compatible
* latest stable Node.js when Bun is unsuitable
* `bun` / `bunx`
* Biome for linting and formatting
* Bun Test or Vitest
* Valibot or Zod for validation

Avoid introducing unless project already uses or specifically needs them:

* npm
* yarn
* ESLint
* Prettier
* Jest

## Frontend

Prefer:

* React
* React Router Framework Mode v7+
* Expo for React Native
* Tailwind CSS
* shadcn/ui
* Zustand for client state
* TanStack Query for server state

Avoid introducing unless justified:

* Redux
* styled-components
* Material UI

Use platform/framework capabilities before adding another abstraction.

## Backend

Prefer:

* Bun
* Hono
* Elysia
* TypeScript
* Drizzle ORM
* PostgreSQL or MySQL
* SQLite for small projects, local tools, and tests
* Valibot, TypeBox, or Zod for validation
* Pino for structured logging

## Preferred Libraries

When functionality requires a library and project has no established equivalent, prefer evaluating:

* `@tanstack/react-query`
* `@tanstack/react-query-devtools`
* `@t3-oss/*`
* `better-result`
* `date-fns`
* `drizzle-orm`
* `http-status-codes`
* `lefthook`
* `maplibre-gl`
* `nuqs`
* `ofetch`
* `openapi-fetch`
* `openapi-typescript`
* `pino`
* `remix-hook-form`
* `remix-utils`
* `release-it`
* `@release-it/conventional-changelog`
* `ts-pattern`
* `remix-toast`

Treat this list as preference, not permission to install packages automatically.

## OpenAPI connector
Use `openapi-fetch` and `openapi-typescript` to generate API clients from OpenAPI specs. Avoid using other OpenAPI generators unless project already uses them. Preffered `openapi-typescript` options to generate schema: `--enum --dedupe-enums --enum-values --make-paths-enum`

Before adding dependency:

1. Check whether project already has equivalent capability.
2. Check whether framework/platform provides suitable built-in solution.
3. Confirm package fits current architecture.
4. Prefer existing dependency over introducing competing library.
5. Add new dependency only when benefit is concrete.

## Decision Behavior

When several valid choices exist, prefer option matching this stack.

When preferred option conflicts with established project architecture, preserve project architecture.

When recommending deviation from this stack, state reason briefly.

Do not mention this skill or preference list unless relevant to decision.
