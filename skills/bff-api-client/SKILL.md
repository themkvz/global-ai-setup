---
name: x-bff-api-client
description: >
  Wiring the server-side API client in a React Router v7+ Framework Mode BFF:
  the per-request client factory, its React Router context, the auth
  middleware that builds it, the endpoint wrapper layer, and loader/action
  error handling. Use when adding an API call to a loader, action, or
  resource route, adding an endpoint wrapper, creating a protected or guest
  route layout, writing auth middleware, testing a wrapper or loader, or
  reviewing how a route reaches the API.
---

# BFF API Client

The route never builds a client and never sees a token. The middleware
builds one **per-request client**, puts it in React Router context, and
every loader, action, and wrapper below reads it from there. This is the
**client-in-context** rule, and it is what keeps auth headers, `401`
handling, correlation IDs, timeouts, and logging in exactly one file.

## Layers

```text
client.server.ts   createApiClient()  — per-request factory
context.ts         apiClientContext   — createContext<ApiClient>()
middleware.server  requireSession     — builds client, sets context
_protected.tsx     middleware = [...] — layout applies it to a subtree
<domain>.server.ts getCategories()    — one thin fn per endpoint
route loader       context.get(...)   — reads client, calls wrappers
```

## The factory

`createApiClient` wraps the generated client (Eden treaty, `openapi-fetch`)
and is the only place these live:

- `Authorization` header from the session's token
- `401` → run `onUnauthorized` (destroy session, redirect to login)
- correlation ID header and request/response logging
- request timeout
- refresh + retry, if the API has refresh tokens

Take credentials and callbacks as arguments; return the wrapped client.
Build a fresh one per request — it closes over one user's credentials, so
a module-level singleton would serve them to the next request.

Accept an absent credential and return an anonymous client, so guest
routes flow through the same factory.

`onUnauthorized` must **throw** its `redirect()`, never return it. A
callback that returns leaves the `401` to fall through to the route, where
it reads as an ordinary error and renders a broken screen instead of
sending the user to log in.

Pass the incoming `request.signal` through to the underlying fetch. When
the user navigates away mid-load, React Router aborts the request and the
upstream call dies with it rather than running on to completion.

## The context

```ts
export type ApiClient = ReturnType<typeof createApiClient>
export const apiClientContext = createContext<ApiClient>()
```

Derive `ApiClient` from the factory's return type. Every wrapper and route
types against that one alias, so swapping the underlying HTTP library
touches the factory alone.

Import the factory with `import type` here. This module is reached from
route modules that also run in the browser, and a value import would drag
the server client — and its secrets — into the client bundle.

## The middleware

Each auth middleware ends by setting a client into context — including the
guest one:

| Middleware | Session | Sets into context |
|---|---|---|
| `requireSession` | required, else redirect to login | credentialed client |
| `requireGuest` | must be absent, else redirect in | anonymous client |
| `optionalSession` | either | credentialed if present, else anonymous |

Because every branch sets a client, a route below is guaranteed one and
never constructs its own. A login or register action reads the anonymous
client from context exactly like a dashboard loader reads the
credentialed one.

Attach the middleware to a pathless layout route (`_protected.tsx`,
`_admin.tsx`), so the whole subtree inherits it:

```ts
export const middleware: Route.MiddlewareFunction[] = [requireSession]
```

## The wrapper layer

One file per domain (`categories.server.ts`, `events.server.ts`), one
function per endpoint, `client` always first:

```ts
export function getCategories(client: ApiClient) {
  return client.categories.get()
}

export function updateCategory(
  client: ApiClient,
  params: { categoryId: string } & CategoryValues
) {
  const { categoryId, ...body } = params
  return client.categories({ id: categoryId }).patch(body)
}
```

Keep the body a single call. The wrapper exists to name the endpoint and
pin its path and param shape in one place — the only place in the app
that knows an API route's path or `schema.gen` shape. Regenerating the
schema then lands in the wrapper files and nowhere else.

Taking `client` as a parameter rather than importing one is what keeps the
per-request client flowing and the wrapper trivially testable.

Return the underlying client's result shape unchanged. Re-wrapping every
call in a project-specific envelope costs a translation layer in both
directions and throws away the generated response types.

Business logic (date math, aggregation, branching on results) belongs to
the route or a domain module, not here.

## The route

```ts
export async function loader({ context }: Route.LoaderArgs) {
  const client = context.get(apiClientContext)

  const [orgResult, categoriesResult] = await Promise.all([
    getCurrentOrg(client),
    getCategories(client),
  ])

  if (orgResult.error) throwApiError(orgResult.error)
  if (categoriesResult.error) throwApiError(categoriesResult.error)

  return { org: orgResult.data, categories: categoriesResult.data }
}
```

Fire independent calls with `Promise.all`. A route that awaits three
wrappers in sequence pays three round trips for no reason.

Return the fields the UI renders, not the raw API response. Loader data is
serialized to the browser, so anything passed straight through is
published — including fields the API returns for other consumers.

## Errors at the route boundary

`401` never arrives here — the factory handled it. Everything else splits
by whether the user can fix it in place:

- **Loader** — nothing to type into, so `throw` a `Response` carrying the
  upstream status and let the route's `ErrorBoundary` render it.
- **Action** — `return` the message so the form renders it on the field or
  in a form-level alert, and the user's input survives.
- **Action, unfixable** (`403`, `5xx`) — `throw` from the action too.
  Retyping the form changes nothing, so the error boundary is the honest
  destination.

Put this split in one helper pair next to the factory (`throwApiError` /
`toActionError`) and call it from every route, so a status never gets
classified twice differently.

Let `403` render as forbidden. It means the credential is valid and the
user lacks permission; destroying the session over it turns one
over-restricted route into a full logout and hides the authorization bug.

## Adding an endpoint

1. Add or extend the wrapper in the domain's `<domain>.server.ts`, `client`
   first, body a single call.
2. In the loader or action, read the client from `apiClientContext`.
3. Call the wrapper; join independent calls with `Promise.all`.
4. Route the result's error through `throwApiError` or `toActionError`.
5. Return only the fields the component renders.

Done when the route names no API path, holds no token, and constructs no
client.

## Resource routes

A resource route (loader/action, no default export) reaches the API through
the same client. It gets one by sitting inside the layout whose middleware
sets it — nesting is what runs the middleware, so a resource route parked
outside the protected subtree has no session and no client.

Its caller is `fetch`, not a navigation, and that changes the `401`:

```text
navigation   401 → redirect("/login")  → browser lands on the login page
fetch        401 → redirect("/login")  → fetch follows it and resolves 200
                                         with login HTML as the payload
```

Give resource routes an `onUnauthorized` that throws a bare `401`
`Response` instead. The caller then sees the status, and the page that
owns the fetch decides whether to redirect.

Return `Response` (or `data()` with headers) here, and apply the same rule
as a loader about which fields cross the boundary.

## Testing

The `client`-first wrapper signature is the seam — a test supplies a fake
client as an ordinary argument, so no module mocking is involved:

```ts
const client = { categories: { get: async () => ({ data: [], error: null }) } }
await getCategories(client as unknown as ApiClient)
```

Fake only the endpoints under test; the cast absorbs the rest.

For a loader or action, build the context the middleware would have set:

```ts
const context = new RouterContextProvider()
context.set(apiClientContext, client as unknown as ApiClient)

await loader({ context, request, params } as Route.LoaderArgs)
```

Calling the loader directly tests its logic. Reach for `createRoutesStub`
when the middleware itself is under test — redirects, session loading, and
which client lands in context.

## Guardrails

- Construct a client only inside the factory and the middleware.
- Pass the client, not the token. A function taking a raw token builds its
  own client per call and silently opts out of every behavior above.
- Reach `client.GET('/some/path')` only from a wrapper.
