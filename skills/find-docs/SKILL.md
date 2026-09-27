---
name: x-find-docs
description: >-
  Fetch current documentation, API references, and code examples for any library, framework,
  SDK, CLI, or cloud service via Context7 (`ctx7`). Use for API syntax, configuration, setup,
  version migrations, library-specific debugging, and "how do I" questions naming a library,
  even well-known ones and even when you think you know the answer: training data goes stale.
  Prefer over web search for library docs.
---

# Documentation Lookup

Two steps with the globally installed `ctx7` CLI. At most 3 calls per question; then use the best result.

```bash
ctx7 library <name> "<query>"     # 1. resolve name → library ID
ctx7 docs <libraryId> "<query>"   # 2. query docs with that ID
```

Skip step 1 only when the user gives an ID (`/org/project` or `/org/project/version`). IDs need the `/` prefix: `/facebook/react`, not `facebook/react`.

## Resolve

- Use the official name with punctuation ("Next.js", "Three.js", "Customer.io"). If results look wrong, try an alternate spelling before changing the query.
- Pick by name match, then description relevance, code snippet count, source reputation (High/Medium), and benchmark score (max 100).
- Several good matches: say so and use the best. None: say so and suggest refinements. Ambiguous query: ask first.
- User named a version: use the closest ID from the result's version list, e.g. `/vercel/next.js/v14.3.0-canary.87`.

## Query

- Always pass a query; it drives ranking. Describe what to look up, not the task to complete.
- One specific topic per `docs` call: `"React useEffect cleanup with async operations"`, not `"hooks"` or `"routing and auth and caching"`. Split multi-concept questions unless they're about how the concepts interact.
- Never include secrets, credentials, personal data, or proprietary code in a query.

## Errors

On a quota error ("Monthly quota reached", "quota exceeded"): tell the user, suggest `ctx7 login` or `CONTEXT7_API_KEY` for higher limits, and if they decline, answer from training knowledge marked as possibly outdated. Never fall back silently.
