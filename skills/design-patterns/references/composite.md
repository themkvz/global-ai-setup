# Composite

Structural.

## Intent

Represent part/whole hierarchies as a tree and let callers treat a single item and a container of items through the same interface.

## Use when

- The domain is a tree: file system, UI component tree, nested packages in a shipment, org chart, expression tree, menu with submenus.
- Callers want one operation (`totalPrice`, `render`, `size`) that works on a leaf and on any subtree.

## Do not use when

- The structure is flat. An array is not a composite.
- Leaves and containers share no meaningful operations. Forcing one interface produces methods that throw "not supported".

## Example

```ts
type Item = { kind: 'product'; price: number } | { kind: 'box'; children: Item[] }

const totalPrice = (item: Item): number =>
  item.kind === 'product' ? item.price : item.children.reduce((sum, child) => sum + totalPrice(child), 0)
```

Operations live outside the type as recursive functions, so adding an operation is one new function and adding a node kind is a compiler-checked union member.

## Pitfalls

- Deep recursion on huge trees can overflow the stack. Iterate with an explicit stack when depth is unbounded.
- Parent links make the structure a graph. Only add them when a real operation needs them, and never serialize them.
- The class form (`Component` with `add`/`remove` on leaves) is the "not supported" trap. The union form has no such methods on leaves.

## Related

- Traverse with [Iterator](iterator.md) (a generator). Operate across the tree with [Visitor](visitor.md).
- [Decorator](decorator.md) has the same recursive shape but one child and adds behavior.
- [Builder](builder.md) constructs trees step by step. [Chain of Responsibility](chain-of-responsibility.md) can walk up parent links.
