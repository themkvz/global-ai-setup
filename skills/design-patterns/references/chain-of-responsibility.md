# Chain of Responsibility

Behavioral.

## Intent

Pass a request along a sequence of handlers. Each decides to handle it, pass it on, or stop.

## Use when

- Several independent checks or handlers apply to a request and the set or order changes: authentication methods, validation rules, event handlers, support escalation.
- Handlers must run in a specific order and any one may short-circuit.

## Do not use when

- The framework already has middleware (Hono, Elysia, Express, React Router middleware). That is this pattern. Use it.
- There are two handlers and the order never changes. Two `if` statements.
- Every handler must run and none stops the chain. That is a list of functions you `for`-loop over, no pattern name needed.

## Example

```ts
type Principal = { userId: string }
type Authenticator = (req: Request) => Principal | undefined

const authenticate = (req: Request, chain: Authenticator[]): Principal | undefined => {
  for (const authenticator of chain) {
    const principal = authenticator(req)
    if (principal) return principal
  }
  return undefined
}
```

The `next()` style — each handler receives the rest of the chain — is what framework middleware (Hono, Elysia, Express) already gives you. Use that instead of reimplementing it.

## Pitfalls

- A request that no handler accepts must be a deliberate outcome (`undefined`, 401), not a silent fall-through.
- Handlers that depend on each other's side effects are not a chain, they are a sequence with hidden coupling.
- Linked-list `setNext()` handler classes are the textbook form. An array is shorter and reorderable.

## Related

- [Command](command.md), [Mediator](mediator.md), [Observer](observer.md) are the other ways to connect senders and receivers.
- [Decorator](decorator.md) looks similar but every layer delegates. A chain handler may stop.
- Walks up a [Composite](composite.md) tree via parent links (event bubbling).
