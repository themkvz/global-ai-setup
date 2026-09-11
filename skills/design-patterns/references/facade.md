# Facade

Structural.

## Intent

Give callers a small, task-oriented interface to a complex subsystem, so they do not orchestrate its parts themselves.

## Use when

- A use case touches several services in a fixed sequence (reserve stock, charge, create shipment) and that sequence is repeated or must be correct once.
- A third-party SDK exposes fifty calls and your app needs three.
- You want a layer boundary: routes call the facade, never the subsystem.

## Do not use when

- The "subsystem" is one function. Call it.
- The facade would re-export everything. Then it is a barrel file, not a facade, and it hides nothing.

## Example

```ts
// checkout.server.ts — the route calls this, never the three services directly.
export const checkout = async (cart: Cart, deps: Deps) => {
  const reservationId = await deps.inventory.reserve(cart.items)
  const paymentId = await deps.payments.charge(cart.total)
  return { paymentId, shipmentId: await deps.shipping.create(reservationId) }
}

type Cart = { items: unknown[]; total: number }
type Deps = {
  inventory: { reserve: (items: unknown[]) => Promise<string> }
  payments: { charge: (amount: number) => Promise<string> }
  shipping: { create: (reservationId: string) => Promise<string> }
}
```

## Pitfalls

- A facade that keeps growing becomes the god module. Split by use case (`checkout`, `refund`), not by "everything about orders".
- A facade adds no behavior of its own beyond orchestration. If it starts owning state, it is a service.
- Keep subsystem types out of the facade's signature where practical, or callers couple to the subsystem anyway.

## Related

- [Adapter](adapter.md) converts one object's interface. Facade simplifies many objects.
- [Mediator](mediator.md) centralizes communication between peers. Facade is one-directional: caller to subsystem.
- [Abstract Factory](abstract-factory.md) when the only complexity hidden is construction.
- A facade module is already a [Singleton](singleton.md).
