# Decorator

Structural.

## Intent

Add behavior to an object or function by wrapping it in something with the same interface, so wrappers stack and the original stays untouched.

## Use when

- Cross-cutting behavior around an existing operation: logging, retry, timing, metrics, validation, compression, encryption.
- Behaviors must combine at runtime in different sets or orders.
- The wrapped thing cannot be subclassed or edited (third-party, frozen, or shared).

## Do not use when

- There is one behavior and one call site. Put it inline.
- The wrapper changes the interface. That is [Adapter](adapter.md).
- The framework already has the hook: middleware, interceptors, React higher-order components, `fetch` wrappers in `ofetch`. Use those.

## Example

```ts
type Fetcher = (url: string) => Promise<Response>

const withLogging = (fetcher: Fetcher): Fetcher => async (url) => {
  const response = await fetcher(url)
  console.log(url, response.status)
  return response
}

const withCache = (fetcher: Fetcher): Fetcher => {
  const cache = new Map<string, Response>()
  return async (url) => {
    const cached = cache.get(url)
    if (cached) return cached.clone()
    const response = await fetcher(url)
    cache.set(url, response.clone())
    return response
  }
}

const cachedAndLogged = withLogging(withCache(fetch))
```

Wrappers stack: `cachedAndLogged` logs every call, cached or not, because logging sits outside the cache.

## Pitfalls

- Order matters: `withLogging(withCache(f))` logs on every call, `withCache(withLogging(f))` logs only on a miss. Make the order explicit at the composition site.
- Removing one layer from the middle of a stack is awkward. Compose at one place so the stack is visible.
- TypeScript's `@decorator` syntax is a different feature (class member metadata). Do not reach for it to implement this pattern.

## Related

- [Proxy](proxy.md) has the same shape, different intent: Proxy controls access or lifecycle, Decorator adds behavior the client chose. Do not argue about which one you wrote.
- [Composite](composite.md) has many children, Decorator has one.
- [Chain of Responsibility](chain-of-responsibility.md) handlers may stop the chain, decorators always delegate.
- [Strategy](strategy.md) swaps the inside, Decorator wraps the outside.
