# Backend checks (APIs, services, workers, CLIs)

Start by listing every route or entry point (router files, OpenAPI spec, queue consumers, cron jobs, CLI commands). Most security findings come from comparing this list with the auth middleware.

## Performance

- Critical endpoints: P95 latency ≤ 500 ms unless the project has its own SLO. Measure only locally or with permission; otherwise read the hot path.
- No N+1 queries in list endpoints. Hot queries have indexes (check the schema; run `EXPLAIN` on a local database if one is available).
- Every list endpoint has a limit and pagination. No unbounded `SELECT *` on large tables.
- Outbound calls (HTTP, database, queues) have timeouts. Retries use backoff and only for safe or idempotent operations.
- Database connections use a pool sized for the deploy target. Serverless code does not open a new pool per request.
- Slow work (email, image processing, reports) runs in a background job, not in the request.
- Request body size is limited.

## Security

- **Authentication** on every non-public route. Public routes are an explicit, short list.
- **Authorization** per object and per action (owner, tenant, role). Admin routes are protected server-side, not only hidden in the UI.
- **Injection:** parameterized queries or ORM everywhere; no string-built SQL with input. No shell commands built from input. File paths from input are normalized and kept inside an allowed folder (path traversal).
- **SSRF:** server-side fetches of user-given URLs use an allowlist and block internal addresses.
- **Rate limits** on login, registration, password reset, OTP, and expensive or public endpoints.
- **CORS:** allowlist of own origins. Never `*` together with credentials. No reflecting any `Origin`.
- **Tokens:** JWTs check signature, algorithm, `exp`, and audience. Refresh tokens rotate and can be revoked.
- **Webhooks** verify the signature and reject replays.
- **File uploads** check type and size, are stored outside the web root or in object storage, and never run.
- Error responses contain no stack traces, SQL, or internal hostnames.
- Container: runs as non-root, pinned base image, no secrets baked into the image.

## Best practices

- Health and readiness endpoints for the platform's checks.
- Graceful shutdown: finish in-flight requests and jobs on SIGTERM.
- Idempotency for payments and other writes that clients may retry (idempotency key or unique constraint).
- Migrations run in CI or the deploy pipeline, are tested on a copy of production-like data, and work with the previous app version during rollout.
- Jobs and queues: failed jobs retry with a limit and land in a dead-letter queue or log that someone watches.
- Metrics for request rate, errors, and latency. Alerts on error rate and saturation.
- API versioning or a clear plan for breaking changes. Old mobile clients may call this API for months.
- OpenAPI or other spec matches the real routes and responses.

## UX (developer experience of the API or CLI)

- One consistent error format (for example, RFC 9457 problem details) with a machine-readable code and a human message.
- Correct status codes: 400 bad input, 401 not authenticated, 403 not allowed, 404 not found, 409 conflict, 422 validation, 429 rate limited, 5xx only for server faults.
- Validation errors name the field and the rule.
- Pagination, sorting, and filtering work the same way on every list endpoint.
- CLIs: `--help` works, exit codes are 0 for success and non-zero for failure, errors go to stderr, output can be piped (`--json` where useful), destructive commands ask for confirmation or need `--yes`.

## Maintainability

- Integration tests hit real routes with a real (test) database for auth, writes, and money paths.
- Local setup in one command (`docker compose up`, a `dev` script) with seed data.
- Routes, handlers, validation, and data access are separated enough to find and test each part.
