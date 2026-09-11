# Proxy

Structural.

## Intent

Stand in for another object with the same interface and control access to it: lazy creation, caching, access checks, logging, remote calls.

## Use when

- Lazy initialization of a heavy object until first use.
- Caching results of repeated calls with identical arguments.
- Access control before a call reaches the real object.
- Transparent remote access: the proxy does the network, the caller sees a local interface.

## Do not use when

- The framework already provides the hook (TanStack Query for caching, route middleware for access control, an ORM's lazy relations).
- You are adding domain behavior rather than controlling access. That is [Decorator](decorator.md), same code, different reason.

## Example

```ts
type Forecast = { city: string; tempC: number }
type Weather = { forecast: (city: string) => Promise<Forecast> }

const withCache = (service: Weather, ttlMs: number): Weather => {
  const cache = new Map<string, { at: number; value: Forecast }>()
  return {
    forecast: async (city) => {
      const hit = cache.get(city)
      if (hit && Date.now() - hit.at < ttlMs) return hit.value
      const value = await service.forecast(city)
      cache.set(city, { at: Date.now(), value })
      return value
    },
  }
}
```

## Pitfalls

- A cache with no TTL and no bound is a memory leak. Decide eviction up front.
- A remote proxy hides latency and failure. Callers still need timeouts and error handling, so do not make it look too local.
- Same-interface means same-interface. If the proxy needs an extra method, it is no longer substitutable.

## Related

- [Decorator](decorator.md) is the same shape. Proxy manages the service's lifecycle and access, Decorator adds behavior the client composes.
- [Adapter](adapter.md) changes the interface. Proxy keeps it.
- [Facade](facade.md) simplifies a subsystem. Proxy is interchangeable with its service.
