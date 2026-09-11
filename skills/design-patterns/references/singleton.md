# Singleton

Creational.

## Intent

Guarantee one instance of something and give the program one access point to it.

## Use when

- A resource must be shared and created once: a connection pool, a logger, a config object parsed from env.
- You want a controlled global instead of ad-hoc module-level mutable variables.

## Do not use when

- The instance is only "convenient" to reach globally. Pass it in. Hidden globals make tests order-dependent and hide dependencies.
- Two instances would be fine. Then it is not a singleton, it is a cache.
- The classic class with a private constructor and `getInstance()` is never needed in TypeScript. ES modules are singletons: a module evaluates once per process.

## Example

```ts
// logger.ts — an ES module evaluates once per process, so this is already a singleton.
export const logger = createLogger({ level: 'info' })

// Lazy variant, when construction needs runtime config:
let db: Db | undefined
export const getDb = (url: string): Db => (db ??= connect(url))

declare const createLogger: (opts: { level: string }) => { info: (msg: string) => void }
type Db = { query: (sql: string) => Promise<unknown[]> }
declare const connect: (url: string) => Db
```

## Pitfalls

- Bundlers and test runners may evaluate a module more than once (separate module graphs, HMR, worker threads). If uniqueness matters for correctness, enforce it at the resource, not the module.
- A singleton that holds request-scoped data (current user, tenant) is a data leak across requests. Keep singletons stateless or process-scoped.
- Prefer dependency injection at the composition root: create once, pass down. The module-level export is the fallback, not the goal.

## Related

- A [Facade](facade.md) is often a module, hence already a singleton.
- [Flyweight](flyweight.md) shares many immutable instances. Singleton is one mutable instance.
- [Abstract Factory](abstract-factory.md), [Builder](builder.md), [Prototype](prototype.md) registries are usually module singletons.
