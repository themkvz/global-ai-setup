# Observer

Behavioral.

## Intent

Let many objects subscribe to events from one, so the publisher never knows who listens.

## Use when

- Something changes and an open-ended, runtime-defined set of parties must react (UI updates, cache invalidation, audit logging, analytics).
- Subscriptions come and go (components mount and unmount).

## Do not use when

- There is one listener known at compile time. Call it.
- The platform already publishes: DOM `EventTarget`, Node `EventEmitter`, Zustand `subscribe`, TanStack Query invalidation, React state. Reuse the existing bus.
- You need request/response between parties. That is a function call or a [Mediator](mediator.md).

## Example

```ts
const createSignal = <T>() => {
  const listeners = new Set<(value: T) => void>()
  return {
    subscribe: (listener: (value: T) => void) => {
      listeners.add(listener)
      return () => listeners.delete(listener)
    },
    emit: (value: T) => listeners.forEach((listener) => listener(value)),
  }
}
```

In the browser, `new EventTarget()` does the same with zero code. In Node, `EventEmitter`. Reach for those before writing this.

## Pitfalls

- Forgotten unsubscribe is the classic leak. Return the unsubscribe from `subscribe` and call it in cleanup (`useEffect` return, `AbortSignal`).
- Listener order is not a contract. If B must run after A, call them in sequence instead of subscribing both.
- A listener that throws stops the others. Decide: isolate with try/catch per listener, or let it propagate.
- Emitting inside a listener creates reentrancy. Queue if it happens.

## Related

- The usual mechanism behind [Mediator](mediator.md).
- [Chain of Responsibility](chain-of-responsibility.md) passes one request until handled. Observer fans out to all.
- [Command](command.md) makes a one-way link from one sender to one receiver.
