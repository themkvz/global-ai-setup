# Adapter

Structural.

## Intent

Let code that expects one interface use an object that exposes another, by wrapping it.

## Use when

- Integrating a third-party or legacy API whose shape, units, or naming does not match your domain type, and you cannot change it.
- Two implementations you want to swap (Redis vs Valkey vs in-memory) expose different clients but your code needs one shape.
- Test doubles: adapt a real SDK to a small interface so tests can substitute a fake.

## Do not use when

- You own both sides. Change the interface instead of wrapping it.
- Only one method differs by name. Alias it at the call site.
- The wrapper adds behavior. That is [Decorator](decorator.md) or [Proxy](proxy.md).

## Example

```ts
type KeyValueStore = { get: (key: string) => Promise<string | null> }
type RedisLikeClient = { GET: (key: string) => Promise<string | undefined> }

const adaptRedis = (client: RedisLikeClient): KeyValueStore => ({
  get: async (key) => (await client.GET(key)) ?? null,
})
```

## Pitfalls

- Keep the target interface small and yours. An adapter that mirrors the vendor API one-to-one adapts nothing.
- Unit and error conversion belong in the adapter (miles to km, vendor error codes to your error type). Do not leak vendor types through it.
- Also wrap data, not just calls: mapping an API response to your domain type is the same pattern (`toUser(apiUser)`).

## Related

- [Bridge](bridge.md) is designed up front to separate abstraction from implementation. Adapter retrofits.
- [Decorator](decorator.md) keeps the interface and adds behavior. [Proxy](proxy.md) keeps the interface and controls access. Adapter changes the interface.
- [Facade](facade.md) simplifies a whole subsystem. Adapter converts one object.
