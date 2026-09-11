# Visitor

Behavioral.

## Intent

Keep operations over a set of related types outside those types, so new operations can be added without touching them.

## Use when

- A fixed set of node types (AST, document elements, product kinds) and a growing set of operations (export, price, validate, render).
- An operation needs to accumulate state across a traversal.
- The behavior does not belong to the types (shipping cost is not a property of a `Product`).

## Do not use when

- Types grow more often than operations. Then put the method on the type.
- One operation. One function with a `switch`.
- The classic double-dispatch (`element.accept(visitor)`) is only needed when you cannot switch on the type: elements are classes from another package with no discriminant.

## Example

```ts
type Product = { kind: 'physical'; price: number; weightKg: number } | { kind: 'digital'; price: number }

const shippingCost = (product: Product): number => {
  switch (product.kind) {
    case 'physical':
      return product.weightKg * 2
    case 'digital':
      return 0
  }
}

const tax = (product: Product): number => {
  switch (product.kind) {
    case 'physical':
      return product.price * 0.2
    case 'digital':
      return product.price * 0.1
  }
}
```

Two operations over the same union, zero changes to `Product`. That is the pattern's value: `shippingCost` and `tax` are separate "visitors" that never touch each other's code.

## Pitfalls

- Visitors cannot see private fields. If an operation needs internals, it belongs on the type.
- A `default` branch in the `switch` disables the exhaustiveness check. Leave it out.
- Exhaustiveness needs `noImplicitReturns` (or a `never`-check default) turned on in `tsconfig.json` — without it, a missing case just returns `undefined` at runtime.
- One visitor that does three things at once (validate and price and render) is three visitors.

## Related

- Runs over [Composite](composite.md) trees, walked by an [Iterator](iterator.md).
- A [Command](command.md) generalized to many receiver types.
