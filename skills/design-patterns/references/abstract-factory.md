# Abstract Factory

Creational.

## Intent

Produce families of related objects that are guaranteed to work together, without naming their concrete types.

## Use when

- Several objects must be consistent with each other: the production DB with the production cache with the production mailer, or the in-memory versions of all three for tests.
- A module already has several factory functions and their combination is the real responsibility.

## Do not use when

- Only one object varies. That is [Factory Method](factory-method.md).
- There is one family. Build the objects in the composition root.
- The "families" are theoretical (no second environment or platform exists yet).

## Example

```ts
type Db = { query: (sql: string) => Promise<unknown[]> }
type Cache = { get: (key: string) => Promise<string | null> }
type Infra = { db: Db; cache: Cache } // the family

const createProdInfra = (): Infra => ({ db: createPgDb(), cache: createValkeyCache() })
const createTestInfra = (): Infra => ({ db: createMemoryDb(), cache: createMemoryCache() })

declare const createPgDb: () => Db
declare const createValkeyCache: () => Cache
declare const createMemoryDb: () => Db
declare const createMemoryCache: () => Cache
```

## Pitfalls

- Adding a member to the family touches every factory. Keep families small and cohesive.
- Do not mix families: a factory that returns a prod DB with a fake mailer is a bug the pattern exists to prevent.

## Related

- Built from [Factory Method](factory-method.md) functions. Can compose [Prototype](prototype.md) clones instead.
- Alternative to [Facade](facade.md) when the goal is hiding construction.
- Pairs with [Bridge](bridge.md) when an abstraction only works with certain implementations.
