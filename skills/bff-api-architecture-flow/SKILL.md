---
name: x-bff-api-architecture-flow
description: >
  Design and review authentication for a web BFF (React Router v7+ Framework Mode or similar)
  in front of a REST API, optionally with an Expo/mobile client calling the API directly.
  Covers login, registration, server-side web sessions (Valkey/Redis), access and refresh
  tokens, refresh rotation and retry, logout, token storage, and 401/403 handling. Use when
  implementing or reviewing any of these, when choosing where tokens live, or when users get
  "randomly logged out", even if the user does not say "BFF".
---

# Auth Architecture: BFF + API + Mobile

Pick the simplest model the API actually supports. Never invent auth behavior the API does not have (no fake refresh in the BFF for a single-token API).

## Pick the mode

| API gives you | Mode | Details |
|---|---|---|
| One token, no refresh endpoint (common with external Spring Boot APIs) | 1. Single token | [references/single-token-api.md](references/single-token-api.md) |
| Access + refresh tokens, API owned by someone else | 2. Existing access/refresh | rules below are the whole story |
| You own the API too (new full-stack project) | 3. Own API | [references/own-api.md](references/own-api.md) for the API side |

For a new project needing web and mobile, default to Mode 3: React Router BFF + Valkey sessions + API (Elysia) + PostgreSQL, with Expo calling the API directly. Stay at this level; add a separate auth service or OIDC only for a real SSO or multi-client requirement.

## Ownership

- **API** owns authentication and authorization. It enforces every permission, even when the BFF also checks claims for UI and routing.
- **BFF** owns the browser session. It holds API tokens server-side and calls the API with `Authorization: Bearer`.
- **Mobile** calls the API directly and owns its own token state.

The BFF may decode access-token claims without verifying the signature, for redirects and UI only. That is safe because the token came from the BFF's own session store and the API re-verifies it on every call. Never branch on decoded claims for anything the API does not also enforce.

## Where credentials live

| Client | Credential | Storage |
|---|---|---|
| Browser | opaque random session ID | cookie: `HttpOnly`, `Secure`, `SameSite` |
| BFF | API token(s) | server-side session store (Valkey/Redis), keyed by session ID, with a TTL |
| Mobile, access + refresh | access token | memory |
| Mobile, access + refresh | refresh token | `expo-secure-store` |
| Mobile, single token | token | `expo-secure-store` |

The browser never sees an API token: not in `localStorage`, `sessionStorage`, a JS-readable cookie, persisted frontend state, or a cookie *payload* (see Mode 1 reference for why `createCookieSessionStorage` is not enough).

AsyncStorage is for non-secret state only (drafts, theme). A persisted query cache stores API responses unencrypted at rest: exclude authenticated data you would not want on a dumped device, and clear the cache on logout together with the tokens.

Lifetimes must line up. A session cookie or store TTL that outlives the API credential shows the user as signed in until the first action fails. One that expires before a still-valid refresh token logs them out for nothing. Renew the store TTL on every write.

## 401 vs 403

- `401`: credential missing, invalid, or expired. Refresh once if the mode supports it; otherwise end the session.
- `403`: credential valid, permission missing. Render a forbidden state and keep the session.

Collapsing `403` into `401` turns one over-restricted route into a full logout and hides authorization bugs as "random sign-outs".

Ending a session on web means deleting the server-side session key **and** clearing the cookie, then redirecting to login. Clearing only the cookie leaves a live session holding valid tokens until its TTL. On mobile, clear every stored token (and any persisted cache).

## Refresh (Modes 2 and 3)

Expect the API to return `accessToken`, `refreshToken`, and `expiresIn` or `accessTokenExpiresAt`: a short-lived access token (10–15 min) and a revocable refresh token (~30 days) rotated on every refresh. If the contract differs, follow the API, not this default.

```text
request → 401 → POST /auth/refresh (refresh token) → new access + refresh pair
        → replace stored pair → retry the original request once
refresh rejected → end the session (above)
```

- Retry at most once; never loop refresh/retry.
- Proactive refresh before expiry is optional. Keep the `401` path as the fallback anyway. Store `accessTokenExpiresAt` only if you refresh proactively; a purely reactive client never reads it.
- On web, update the tokens inside the existing session. Keep the session ID and cookie unchanged.

**Single-flight across requests.** Rotating refresh tokens are single-use. If two requests refresh with the same token, reuse detection revokes the whole family and the user is silently logged out. On mobile, share one refresh promise across all requests. On the BFF, a promise per API-client instance is not enough when clients are built per request (a second tab, a document load racing a form post). Pick one:

- **Rotation grace window** (simpler, needs API support): the just-rotated token stays valid ~10–30 s and returns the successor pair it already minted. Weakens reuse detection inside that window; that is the trade.
- **Cross-request lock**: Valkey `SET NX` on `sess:<id>:refresh`; the loser waits, then re-reads the session's new access token.

## Logout

Call the API's logout/revoke endpoint with the refresh token (or token) when one exists, then end the session locally. With no revoke endpoint, delete local state only and accept that the API token stays valid until it expires.

## Review checklist

Flag any of these:

- API token in browser storage, a JS-readable cookie, or a cookie payload
- secret in AsyncStorage; authenticated cache left on device after logout
- refresh behavior invented for an API that has none
- business authorization enforced only in the BFF
- `403` handled as `401`
- refresh retried more than once, or deduplicated only per client instance
- session ID rotated on every token refresh
- logout or refresh failure that clears the cookie but not the server-side session
- cookie or session TTL out of step with the API credential lifetime
- `GET /me` (or a DB status check) on every request to emulate revocation
