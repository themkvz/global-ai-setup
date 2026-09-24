# Mode 3: Own API (API Side)

Client-side rules (sessions, refresh, single-flight, logout) are in `SKILL.md`. This file covers what the API itself must do. Examples use Elysia + PostgreSQL; the rules hold for any stack.

## Storage

| Store | Holds | Never holds |
|---|---|---|
| PostgreSQL | users, password hashes, refresh-token hashes and state, business data | access JWTs, plaintext refresh tokens |
| Valkey | web sessions only: `sess:<id> → { accessToken, refreshToken }` | anything else auth-related |

## Registration and login

```text
register: validate input → check identity uniqueness → hash password → create user → issue pair
login:    find user → verify hash → check account state → build current claims → issue pair
```

- Hash passwords with Argon2id.
- Rate-limit credential endpoints (`/sign-in`, password-reset request) in the API, not the BFF: mobile bypasses the BFF.

## Access token

Short-lived JWT, ~15 minutes. Minimum claims:

```text
sub  user ID
iss  issuer
aud  the API (resource server), not the BFF or web client
exp  expiration
```

Tenant/role claims (`orgId`, `role`) may be embedded so common routes authorize without a DB read. They are stale until the next refresh: acceptable for member-level access, not for elevated access (see Authorization).

When authorization state changes mid-session (joins or switches org), issue a **new access token only** and overwrite it in the session. Keep the refresh token, session ID, and cookie.

## Verification

Verify signature, `exp`, `iss`, and `aud` on every request. JWT libraries commonly check only signature and `exp`; `@elysia/jwt`'s `verify()` skips `iss`/`aud` unless passed per call. Route all verification through one helper that checks all four.

A valid token proves identity, not access. Authorization is a separate step.

## Authorization

- Member-level routes: authorize from verified claims alone.
- Manager/owner-level routes: re-read the membership row by primary key and re-check existence, block state, and current role. One indexed lookup, privileged routes only.
- No global DB-backed session-status check on every request.

## Refresh token

Opaque, 32 random bytes, base64url, ~30-day lifetime. Return the plaintext once; store only its SHA-256 hash. The record holds user ID, token hash, family ID, expiry, rotation state, and revocation state.

Rotation:

```text
hash presented token → find active record → atomically consume it
→ re-read current user/membership claims → issue new access token
→ issue new refresh token in the same family
```

Reuse detection: an already-rotated token presented again means replay. Revoke the whole family and return `401`. This is why clients must single-flight refresh, or the API must offer a short rotation grace window (see `SKILL.md`).

## Logout and revocation

`/auth/logout` takes the refresh token and revokes it or its family, per policy.

Revoke all active refresh credentials on password reset, account block, account removal, and explicit logout-everywhere. Role changes can propagate on the next refresh unless the app needs them immediately; for those, rely on the privileged-route re-check above.
