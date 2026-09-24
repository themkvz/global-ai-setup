# Mode 1: API With One Token

The API returns one token at sign-in (and maybe sign-up) and has no refresh endpoint. The single token is the only thing simpler here: the BFF still uses a server-side session store.

## Flows

```text
Web login      Browser → BFF → API /sign-in → token → BFF session store → session-ID cookie
Mobile login   Expo → API /sign-in → token → SecureStore
Web request    cookie → BFF loads session → Bearer token → API
Mobile request SecureStore token → Bearer token → API
401            end the session, require sign-in again (no refresh)
```

Registration goes through the same path to `/sign-up`; the API owns validation, user creation, and password hashing. If sign-up returns a token, establish the session immediately; otherwise sign in as a separate step.

## What the session holds

```text
required: the API token
useful:   identity/role fields the login response already returned, for rendering and route gating
never:    anything the API would not re-derive and re-authorize itself
```

Caching identity in the session avoids a `GET /me` per navigation. It goes stale; accept that for chrome (name, avatar, nav) and let the API's `403` be the real gate. Fetch `/me` at login and on the routes that need it fresh, never from middleware on every request: that round trip emulates revocation this API cannot give you anyway.

## Cookie lifetime

```text
cookie maxAge 30 days, API token exp 1 hour
→ 29 days of looking signed in, then a 401 on the first action
```

Match `maxAge` to the token lifetime, or handle the mid-session logout explicitly. Do not pick 30 days by habit.

## Migrating off a cookie-payload session

React Router's `createCookieSessionStorage` keeps the whole session value in the cookie. Putting the API token there is a common start and a bad end state:

- the token sits in the browser's cookie jar on disk; `HttpOnly` stops JS, not a stolen cookie file or a compromised proxy
- signed is not encrypted: whoever holds the cookie reads the token
- logout is cookie-only: a copied cookie works until the token expires, and nothing server-side can kill the session
- the 4 KB limit makes identity data compete with the token

The migration is contained: the cookie stays, its contents change.

```text
cookie { token, ...user }   →   cookie { sessionId }
                                store: sessionId → { token, ...user }
```

Middleware, API client, and routes are untouched. Existing cookies fail the read and land the user on login once. If the API later adds refresh tokens this migration becomes mandatory, since a refresh token must never live in a cookie payload; revisit the whole model then, not just the token handling.
