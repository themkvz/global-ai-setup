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

## HTTP semantics

- `401 Unauthorized`: missing, invalid, or expired credential.
- `403 Forbidden`: authenticated user lacks permission.
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
→ BFF server-side session
→ opaque sessionId cookie
→ Browser
```

BFF stores API token server-side.

Browser receives only opaque session ID.

### Mobile

```text
Expo
→ credentials
→ API /sign-in
→ token
→ SecureStore
```

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

- delete server-side session
- clear browser cookie
- redirect to login

Mobile:

- delete token from secure storage
- return to unauthenticated state

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
accessTokenExpiresAt
```

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
    refreshToken,
    accessTokenExpiresAt
  }
```

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
| Server-side web token storage | Yes | Yes | Valkey |
| Mobile persistent credential | Single token | Refresh token | Refresh token |
| Mobile access token | API-dependent | Memory | Memory |
| Refresh supported | No | Yes | Yes |
| 401 behavior | Login again | Refresh + retry | Refresh + retry |
| Refresh rotation | N/A | Prefer/contract | Required |
| API owns authorization | Yes | Yes | Yes |
| Refresh state persistence | N/A | API-owned | PostgreSQL |
| Browser session persistence | BFF-owned | BFF-owned | Valkey |

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

---

# Default Recommendations

## External one-token API

Respect API contract.

```text
Web → BFF session → API token
Mobile → secure token → API
401 → login again
```

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
