# Builder

Creational.

## Intent

Construct a complex object step by step, so the same steps can produce different representations and no constructor needs a dozen optional parameters.

## Use when

- Construction is genuinely multi-step: steps are optional, repeatable, order-sensitive, or validated against each other (query builders, request builders, composite trees).
- The same construction steps must produce different outputs (SQL string vs prepared statement, HTML vs Markdown document).

## Do not use when

- The only problem is many optional parameters. TypeScript solves that with an options object and defaults. This covers most "builder" requests.
- Steps are fixed and independent. An object literal is the builder.

## Example

```ts
// Most "builder" requests are really just many optional constructor params.
type CreateUserInput = { email: string; name?: string; role?: 'admin' | 'member' }

const createUser = ({ email, name = email.split('@')[0] ?? email, role = 'member' }: CreateUserInput) => ({
  email,
  name,
  role,
})
```

Reach for a fluent, step-by-step builder only when steps accumulate and a final `build()` validates the whole:

```ts
type Query = { table: string; where: string[]; limit?: number }

const createQuery = (table: string, state: Query = { table, where: [] }) => ({
  where: (clause: string) => createQuery(table, { ...state, where: [...state.where, clause] }),
  limit: (n: number) => createQuery(table, { ...state, limit: n }),
  build: (): string => {
    const where = state.where.length ? ` WHERE ${state.where.join(' AND ')}` : ''
    const limit = state.limit === undefined ? '' : ` LIMIT ${state.limit}`
    return `SELECT * FROM ${state.table}${where}${limit}`
  },
})

const sql = createQuery('users').where('active = true').limit(10).build()
```

Each step returns a new builder, so a partially built query can be shared and reused safely.

## Pitfalls

- A mutable builder shared between two call sites leaks steps. Return new state per step.
- A "director" class that scripts builder steps is only worth it when the same script runs against several builders.
- Do not write a builder for a type with three fields.

## Related

- [Factory Method](factory-method.md) when creation is one call. [Abstract Factory](abstract-factory.md) returns the product immediately, Builder returns it after `build()`.
- Builds [Composite](composite.md) trees recursively.
