---
name: bff-api-architecture-flow
description: >
  Design and review authentication flows for React Router v7+ Framework Mode BFFs,
  external REST APIs, Spring Boot APIs, Elysia APIs, Valkey-backed web sessions,
  PostgreSQL-backed refresh tokens, and Expo mobile clients. Use this skill when
  implementing login, registration, session handling, access tokens, refresh tokens,
  retry behavior, logout, token storage, or authorization boundaries.
---

# Auth Architecture: BFF + API + Mobile

## Goal

Choose the simplest correct authentication model for these common stacks:

1. React Router v7+ BFF + external REST API with one token + Expo mobile.
2. React Router v7+ BFF + API with access/refresh tokens + Expo mobile.
3. Full monorepo: React Router v7+ BFF + Valkey + Elysia API + PostgreSQL + Expo mobile.

Do not invent authentication behavior that the API does not support.

---

# Core Principles

## Ownership

- API owns authentication and authorization.
- BFF owns browser-specific session handling.
- Mobile talks to API directly and owns its local token state.
- Browser must not receive or store API access/refresh tokens directly.
- Authorization must always be enforced by API, even if BFF also checks claims for UI/routing.
- BFF may decode access-token claims without verifying the signature, for redirects and UI only — the token arrived through the BFF's own trusted session store, and every request that acts on those claims is re-verified by the API. Never branch on decoded claims for anything the API does not independently enforce.

## Browser

Use:

- `HttpOnly`
- `Secure`
- `SameSite`
- opaque random session ID

Browser stores only BFF session credential.

Do not store API tokens in:

- `localStorage`
- `sessionStorage`
- browser-readable cookies
- frontend state persisted across reloads

## Mobile / Expo

If API uses access + refresh:

- access token: memory
- refresh token: `expo-secure-store`

If API returns one long-lived token:

- token: `expo-secure-store`

Do not persist secrets in AsyncStorage.

AsyncStorage is fine for non-secret local state (drafts, theme, read
flags). If a persisted query cache is used, remember it stores API
*response* data at rest unencrypted — exclude anything the API only
returns to an authenticated caller and would not want on a dumped device,
and clear it on logout together with the token.

## HTTP semantics

- `401 Unauthorized`: missing, invalid, or expired credential.
- `403 Forbidden`: authenticated user lacks permission.
- Handle the two differently. `401` ends the session. `403` does not — the
  credential is still valid, the user just cannot reach that resource. Render
  a forbidden state or redirect within the app; never destroy the session.
  Collapsing `403` into `401` turns one over-restricted route into a
  full logout, and hides authorization bugs as "random sign-outs".
- Retry original request at most once after refresh.
- Never create infinite refresh/retry loops.

---

# Mode 1: External API With One Token

Use when external backend, commonly Spring Boot, returns one authentication token and exposes no refresh-token flow.

## Registration

Web:

```text
Browser
→ BFF
→ API /sign-up
```

Mobile:

```text
Expo
→ API /sign-up
```

API owns:

- input validation
- user creation
- password hashing
- registration result

If registration returns a token, establish authenticated state immediately.

If registration does not return a token, perform sign-in separately.

## Login

### Web

```text
Browser
→ credentials
→ BFF
→ API /sign-in
→ token
→ BFF session
→ session cookie
→ Browser
```

BFF holds the API token; the browser gets only the session cookie. See
Web Session Storage below for what that cookie actually carries.

### Mobile

```text
Expo
→ credentials
→ API /sign-in
→ token
→ SecureStore
```

## Web Session Storage

Store the API token server-side (Valkey/Redis) and give the browser only
an opaque session ID. This holds in Mode 1 too — a single-token API is a
reason to skip refresh logic, not a reason to skip the session store.

```text
cookie  = opaque sessionId, HttpOnly + Secure + SameSite
session = { token }, server-side, keyed by sessionId, with a TTL
```

### Migrating Off a Cookie-Payload Session

React Router's `createCookieSessionStorage` keeps the whole session value
*in the cookie*. Putting the API token there is a common starting point
and a known-bad end state:

- the token leaves the server and sits in the browser's cookie jar, on
  disk, replayed on every BFF request. `HttpOnly` stops JS, not a stolen
  cookie file or a compromised proxy.
- signed is not encrypted. Anyone holding the cookie reads the token.
- logout is cookie-only. A copied cookie keeps working until the API
  token's own expiry — there is nothing server-side to delete, and no way
  to kill a session from the admin side.
- the 4KB cookie limit caps the payload, so identity data competes with
  the token for space.

Migration is contained — the cookie stays, its contents change:

```text
cookie payload { token, ...user }   →   cookie payload { sessionId }
                                        store: sessionId → { token, ...user }
```

Everything above the session helper (middleware, API client, routes) is
untouched. Existing cookies fail the read and land the user on login once.

A session holding a refresh token must be server-side, always — never a
cookie payload. So if the API later gains access/refresh tokens, this
migration is a prerequisite, not an optional cleanup.

### What the Session Holds

```text
required: the API token
useful:   identity/role fields the login response already returned,
          for rendering and route gating
never:    anything the API would not re-derive and re-authorize itself
```

Caching identity in the session avoids a `GET /me` on every navigation.
It goes stale — accept staleness for chrome (name, avatar, nav items), and
let the API's `403` be the real gate.

Do not call `GET /me` from a middleware that runs on every protected
request. That is one extra round trip on every navigation to emulate
revocation the single-token API cannot give you anyway. Fetch it at login,
store it in the session, and refresh it on the routes that need it fresh.

### Cookie Lifetime

Cookie `maxAge` must not outlive the API token it carries or points at.

```text
cookie maxAge  30 days
API token exp   1 hour
→ 29 days of looking signed in, then a 401 on the first action
```

Match the cookie's `maxAge` to the token's lifetime, or accept and handle
the mid-session logout explicitly. Do not pick 30 days by habit.

## Protected Request

### Web

```text
Browser
→ session cookie
→ BFF
→ load server-side session
→ API token
→ Authorization: Bearer <token>
→ API
```

### Mobile

```text
Expo
→ token
→ Authorization: Bearer <token>
→ API
```

## 401 / Expiration

There is no refresh flow.

```text
request
→ API
→ 401
→ clear authenticated state
→ require sign-in again
```

Web:

- delete server-side session (store model A)
- clear browser cookie
- redirect to login

Mobile:

- delete token from secure storage
- return to unauthenticated state

Only a `401` triggers this. A `403` from a protected route means the token
is valid and the user lacks permission — show the forbidden state, keep
the session.

Do not implement a fake refresh mechanism in BFF.

## Logout

If API exposes logout/revoke endpoint:

```text
API logout/revoke
→ delete local session/token
```

If API exposes no revocation endpoint:

```text
delete local session/token only
```

Accept that server-side token may remain valid until its API-defined expiration.

---

# Mode 2: API With Access + Refresh Tokens

Use when Spring Boot or another API already implements short-lived access tokens and long-lived refresh tokens.

## API Contract

Expected login/sign-up response:

```text
accessToken
refreshToken
accessTokenExpiresAt OR expiresIn
```

Recommended semantics:

```text
Access token:
short-lived, typically 10–15 minutes

Refresh token:
long-lived, typically around 30 days
revocable
rotated on refresh
```

## Registration / Login

### Web

```text
Browser
→ credentials
→ BFF
→ API
→ accessToken + refreshToken
→ BFF server-side session
→ opaque sessionId cookie
```

Server-side session stores:

```text
accessToken
refreshToken
accessTokenExpiresAt   (only if refreshing proactively)
```

A purely reactive `401 → refresh → retry` client never reads the expiry.
Do not store it just because the API returns it — either use it for
proactive refresh or drop it at the session boundary.

Browser never receives API tokens.

### Mobile

```text
Expo
→ credentials
→ API
→ accessToken + refreshToken

accessToken → memory
refreshToken → SecureStore
```

## Protected Request

Web:

```text
Browser
→ BFF session
→ accessToken
→ Authorization: Bearer <accessToken>
→ API
```

Mobile:

```text
Expo
→ accessToken from memory
→ Authorization: Bearer <accessToken>
→ API
```

## Refresh

Preferred reactive flow:

```text
resource request
→ 401
→ POST /auth/refresh with refreshToken
→ new accessToken + refreshToken
→ replace stored pair
→ retry original request once
```

Optionally refresh shortly before known expiry, but always keep `401` handling as fallback.

### BFF Refresh

Update tokens inside existing session.

Do not rotate browser session ID just because API tokens rotated.

```text
sessionId stays unchanged

AT1 + RT1
↓
AT2 + RT2
```

Browser cookie normally remains unchanged.

### Mobile Refresh

```text
new accessToken → memory
new refreshToken → replace old refreshToken in SecureStore
```

## Single-Flight Requirement

Refresh must be deduplicated.

Multiple parallel requests must not independently reuse same rotating refresh token.

Desired behavior:

```text
multiple 401 responses
→ one refresh operation
→ all waiting requests reuse new access token
→ retry once
```

BFF should dedupe refresh by web session.

Mobile should share one refresh promise/operation across requests.

A per-API-client-instance promise only dedupes requests that share that
instance. If the BFF builds one client per incoming HTTP request, two
concurrent browser requests (second tab, document load racing a form
submission) each present the same refresh token, and reuse detection
revokes the whole family — a silent forced logout under ordinary use.

Pick one:

```text
A. Rotation grace window (simpler)
   rotated token stays accepted for ~10-30s
   and returns the successor pair it already minted
   → concurrent refreshes converge, no family revocation

B. Cross-request lock (Valkey SET NX on sess:<id>:refresh)
   loser waits, then re-reads the session's new access token
```

Grace window is the smaller change and removes the race at the source.
Note it weakens reuse detection within that window; that is the trade.

## Refresh Failure

```text
401
→ refresh
→ refresh rejected
→ authenticated session is invalid
```

Web:

- delete server-side session
- clear cookie
- redirect to login

Mobile:

- clear access token
- clear refresh token
- require login

## Logout

```text
client
→ API logout/revoke using refresh token
→ API revokes refresh credential
```

Then:

Web:

- delete server-side session
- clear cookie

Mobile:

- clear access token
- clear refresh token

---

# Mode 3: Full Monorepo

Use when project controls:

- React Router v7+ Framework Mode BFF
- Valkey
- Elysia API
- PostgreSQL
- Expo mobile client

This is preferred baseline for a new full-stack project needing both web and mobile.

## Responsibility Boundaries

### Elysia API

Owns:

- registration
- credential validation
- password hashing
- user identity
- access-token issuance
- refresh-token issuance
- refresh rotation
- refresh revocation
- access-token verification
- authorization
- business logic

### PostgreSQL

Stores:

- users
- password hashes
- refresh-token hashes/state
- business data

Do not persist access JWTs in PostgreSQL.

### React Router BFF

Owns:

- browser session
- secure session cookie
- Valkey session
- server-to-server API calls
- refresh/retry orchestration

### Valkey

Stores web sessions only.

Example logical value:

```text
sessionId
→ {
    accessToken,
    refreshToken
  }
```

Add `accessTokenExpiresAt` only when the BFF actually refreshes ahead of
expiry. Reactive-only refresh does not need it.

Session TTL must be renewed on every write, and must be >= remaining
refresh-token lifetime. A session that expires while its refresh token is
still valid logs the user out for no reason.

### Expo

Owns mobile auth state:

```text
accessToken → memory
refreshToken → SecureStore
```

---

# Registration

Web:

```text
Browser
→ BFF
→ Elysia
```

Mobile:

```text
Expo
→ Elysia
```

Elysia:

```text
validate registration input
↓
check identity uniqueness
↓
hash password
↓
create user
↓
issue access token
↓
issue refresh token
```

Use a strong password-hashing algorithm suitable for password storage, preferably Argon2id.

Rate-limit credential endpoints (`/sign-in`, password-reset request) at
the API, not the BFF — mobile bypasses the BFF entirely.

---

# Login

```text
credentials
↓
Elysia
↓
find user
↓
verify password hash
↓
check account state
↓
build current authorization claims
↓
issue access token
↓
issue refresh token
```

## Access Token

Use short-lived JWT.

Typical TTL:

```text
15 minutes
```

Include only required claims.

At minimum:

```text
sub → user ID
iss → issuer
aud → API/resource server
exp → expiration
```

`aud` identifies API/resource server receiving token, not BFF/web client.

### Authorization Claims

Tenant/role claims (`orgId`, `membershipId`, `role`) may be embedded so
common routes authorize without a DB read.

Cost: claims are stale until the next refresh. Accept that for
member-level access; do not accept it for elevated access — see
Authorization Strategy.

When authorization state changes mid-session (user joins an org, creates
one, changes tenant), issue a **new access token only** and swap it into
the existing session. Do not rotate the refresh token and do not rotate
the session ID for a claims change.

```text
claims changed
→ new accessToken
→ overwrite accessToken in session
→ same refreshToken, same sessionId, same cookie
```

## Refresh Token

Use opaque cryptographically random secret.

Recommended:

```text
32 random bytes
base64url encoded
~30 day lifetime
```

Return plaintext refresh token to client once.

Store only a cryptographic hash, e.g. SHA-256, in PostgreSQL.

Refresh-token record should support:

- user ID
- token hash
- family ID
- expiration
- rotation state
- revocation state

---

# Web Login Storage

After Elysia returns access + refresh pair:

```text
BFF
→ generate opaque random sessionId
→ store tokens in Valkey under sessionId
→ send sessionId in HttpOnly cookie
```

Browser never receives API access or refresh token.

---

# Protected API Request

## Web

```text
Browser
→ session cookie
→ BFF
→ load Valkey session
→ accessToken
→ Authorization: Bearer <accessToken>
→ Elysia
```

## Mobile

```text
Expo
→ accessToken from memory
→ Authorization: Bearer <accessToken>
→ Elysia
```

## API Verification

Elysia verifies:

```text
signature
expiration
issuer
audience
```

JWT libraries commonly verify signature and `exp` only. `@elysia/jwt`'s
`verify()` does **not** enforce `iss`/`aud` unless passed per call. Route
every verification through one helper that checks all four explicitly,
rather than assuming the library does it.

Then:

```text
sub
→ authenticated user ID
→ authorization
→ business logic
```

Authentication and authorization are separate.

A valid token does not automatically grant access to resource.

---

# Authorization Strategy

Common authenticated/member-level routes may rely on verified claims only.

Security-sensitive elevated operations may re-check current membership/account state in PostgreSQL when immediate demotion/block/removal behavior is required.

Do not add a global DB-backed `/session-status` check to every protected request.

Concretely: guard for member-level access from claims alone; for
manager/owner-level access, re-read the membership row by primary key and
re-check existence, block state, and current role before proceeding. One
indexed lookup on privileged routes only.

---

# Refresh Rotation

When access token is expired:

```text
API returns 401
↓
client sends refreshToken to /auth/refresh
```

Elysia:

```text
hash presented refresh token
↓
find active refresh-token record
↓
atomically consume old token
↓
re-read current user/membership claims
↓
issue new access token
↓
issue new refresh token in same family
↓
mark old refresh token unusable
```

Result:

```text
AT1 + RT1
↓
AT2 + RT2
```

## Reuse Detection

If already-rotated refresh token is presented again:

```text
refresh-token replay detected
↓
revoke token family
↓
401
```

This requires single-flight refresh on clients.

---

# BFF Refresh

BFF updates same Valkey session:

```text
sess:<sessionId>

AT1 + RT1
↓
AT2 + RT2
```

Keep:

```text
same sessionId
same browser cookie
```

Then retry original resource request once.

Refresh deduplication must work across parallel requests sharing same session, not only inside one local API-client instance.

When refresh fails, clearing the browser cookie is not enough — delete the
server-side session key too. A cookie-only logout leaves a live session
holding valid-shaped tokens until its TTL expires.

---

# Mobile Refresh

```text
refreshToken from SecureStore
↓
POST /auth/refresh
↓
new accessToken → memory
new refreshToken → replace SecureStore value
↓
retry waiting requests once
```

Use one shared refresh operation.

---

# Logout

API:

```text
refreshToken
→ /auth/logout
→ revoke refresh token or family according to policy
```

Web:

```text
delete Valkey session
→ clear browser cookie
```

Mobile:

```text
clear accessToken from memory
→ delete refreshToken from SecureStore
```

---

# Revocation Events

For own API, revoke active refresh credentials on security-sensitive events such as:

- password reset
- account block
- account removal
- explicit logout

Role changes may simply propagate on next refresh unless application requires immediate effect.

For privileged routes requiring immediate revocation semantics, re-check current permission/membership state on those routes.

---

# Decision Table

| Requirement | One-token API | Existing AT/RT API | Own Elysia API |
|---|---|---|---|
| Browser stores API token | No | No | No |
| Browser credential | BFF session | BFF session | BFF session ID |
| Web session storage | Server-side | Server-side | Valkey |
| Mobile persistent credential | Single token | Refresh token | Refresh token |
| Mobile access token | API-dependent | Memory | Memory |
| Refresh supported | No | Yes | Yes |
| 401 behavior | Login again | Refresh + retry | Refresh + retry |
| 403 behavior | Forbidden UI, keep session | Forbidden UI, keep session | Forbidden UI, keep session |
| Refresh rotation | N/A | Prefer/contract | Required |
| API owns authorization | Yes | Yes | Yes |
| Refresh state persistence | N/A | API-owned | PostgreSQL |
| Browser session persistence | BFF-owned | BFF-owned | Valkey |
| Authz claims in access token | API-dependent | API-dependent | Optional, staleness-bounded |
| Refresh dedup scope | N/A | Per session | Per session |

---

# Anti-Patterns

Do not:

- store access/refresh tokens in browser `localStorage`
- put refresh token in AsyncStorage
- invent refresh behavior when external API exposes none
- trust BFF-only authorization for protected business operations
- retry refresh indefinitely
- rotate web session ID on every API token refresh without need
- allow multiple concurrent refreshes with same rotating refresh token
- use BFF/web client identifier as JWT `aud` when API is resource server
- query DB on every authenticated request solely to emulate revocation
- add separate auth service/OIDC infrastructure without a real multi-client/SSO requirement
- dedupe refresh per API-client instance when clients are built per request
- rotate the refresh token or session ID for an authorization-claims change
- clear the browser cookie on logout/refresh failure without deleting the server-side session
- store `accessTokenExpiresAt` in the session while refreshing purely reactively
- assume a JWT library checks `iss`/`aud` by default
- treat `403` as `401` and destroy the session on a permission denial
- keep the API token in the cookie payload instead of a server-side
  session, single-token API included
- set a 14/30-day session cookie in front of a short-lived API token
- call `GET /me` from a middleware on every protected request to emulate
  revocation a single-token API does not support
- persist authenticated API responses to unencrypted mobile storage and
  leave them there after logout

---

# Default Recommendations

## External one-token API

Respect API contract.

```text
Web → BFF session → API token
Mobile → secure token → API
401 → login again
403 → forbidden UI, session intact
```

Server-side session store here as well — the single token is the only
thing simpler about Mode 1. Revisit the whole model, not just the token
handling, if the API later adds refresh tokens.

## Existing access/refresh API

Use API token lifecycle as designed.

```text
Web → server-side BFF session
Mobile → AT memory + RT secure storage
401 → one refresh → one retry
```

## New full-stack project

Prefer:

```text
Browser
→ React Router BFF
→ Valkey session
→ Elysia API
→ PostgreSQL

Expo
→ Elysia API directly
```

Auth model:

```text
15-minute access JWT
+
rotating opaque ~30-day refresh token
+
hashed refresh-token state in PostgreSQL
+
opaque BFF session ID in browser cookie
```

Keep architecture at this level unless concrete requirements justify more complexity.
