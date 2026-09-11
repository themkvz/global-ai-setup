# State

Behavioral.

## Intent

Make an object's behavior depend on its current state explicitly, with each state's rules in one place, instead of `if (status === ...)` scattered across methods.

## Use when

- An entity has a lifecycle (draft, paid, shipped, cancelled) and several operations check the status field.
- Transitions have rules, and invalid transitions must be impossible or rejected in one place.
- The same status checks are duplicated across functions.

## Do not use when

- Two states, one check. A boolean.
- State never changes after creation. That is a type, not a state machine.

## Example

```ts
type Order =
  | { status: 'draft'; items: string[] }
  | { status: 'paid'; items: string[]; paidAt: Date }
  | { status: 'shipped'; items: string[]; paidAt: Date; trackingId: string }

type OrderEvent = { type: 'pay' } | { type: 'ship'; trackingId: string }

const transition = (order: Order, event: OrderEvent): Order => {
  if (order.status === 'draft' && event.type === 'pay') return { ...order, status: 'paid', paidAt: new Date() }
  if (order.status === 'paid' && event.type === 'ship') return { ...order, status: 'shipped', trackingId: event.trackingId }
  return order
}
```

Every transition rule lives in one function. `trackingId` cannot exist on a draft or paid order — the compiler enforces it, not a runtime check.

## Pitfalls

- Returning the same state for an invalid event silently swallows bugs. Decide per domain: ignore, return a `Result`, or throw.
- Persisting a union: store `status` plus nullable columns, validate on read back into the union.
- Putting side effects in `transition` (send email on paid) makes it untestable. Return the new state, let the caller act.

## Related

- Same shape as [Strategy](strategy.md), but states know each other and drive transitions. Strategies are independent.
- [Bridge](bridge.md) and [Adapter](adapter.md) share the composition structure with different intent.
