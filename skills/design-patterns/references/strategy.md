# Strategy

Behavioral.

## Intent

Define a family of interchangeable algorithms and let the caller pick one at runtime, without the code that uses them knowing which.

## Use when

- A function switches between algorithm variants (pricing rules, sort orders, retry policies, serialization formats).
- Several classes or functions differ only in one step.
- A growing `switch` on a "method" or "kind" argument.

## Do not use when

- One algorithm. Inline it.
- Two stable variants. A boolean or a two-branch `if` is clearer than an indirection.
- The variants need to know each other or change the caller's state. That is [State](state.md).

## Example

```ts
type ShippingStrategy = (weightKg: number) => number

const shippingStrategies = {
  flat: () => 5,
  weight: (weightKg: number) => weightKg * 1.2,
} satisfies Record<string, ShippingStrategy>

const shippingCost = (weightKg: number, method: keyof typeof shippingStrategies) =>
  shippingStrategies[method](weightKg)
```

The lookup object replaces a `switch`. Adding a method is one line.

## Pitfalls

- Clients must know which strategy to pick. If that choice itself needs logic, put it in a [Factory Method](factory-method.md), not in every caller.
- Strategy classes with one method are functions. Write the function.
- Do not pass the context's whole state into the strategy. Pass what the algorithm needs.

## Related

- [State](state.md) is Strategy where the strategies know each other and swap themselves.
- [Template Method](template-method.md) varies steps through inheritance. Strategy varies the whole algorithm through composition.
- [Decorator](decorator.md) wraps outside. Strategy replaces inside.
- [Command](command.md) is an operation to run later. Strategy is how to run one now.
