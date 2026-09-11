# Iterator

Behavioral.

## Intent

Traverse a collection without exposing how it is stored, and let several traversals run independently.

## Use when

- The structure is not a flat array: tree, graph, paginated API, linked nodes, a depth-limited walk.
- Traversal logic is non-trivial and repeated in several places.
- You want lazy or resumable iteration (stream large data, stop early).

## Do not use when

- It is an array. `for...of`, `map`, `filter`.
- You would write a custom `Iterator` interface with `hasNext`/`next`. JavaScript already has the iteration protocol.

## Example

```ts
type Contact = { name: string; friends: Contact[] }

function* contactsUpTo(root: Contact, depth: number): Generator<Contact> {
  yield root
  if (depth === 0) return
  for (const friend of root.friends) yield* contactsUpTo(friend, depth - 1)
}
```

A generator implements the iteration protocol for free — `for...of`, spread, and `Array.from` all just work.

## Pitfalls

- A generator runs once. Spread it into an array if you need to iterate twice.
- Mutating the collection during iteration gives undefined results. Snapshot first or iterate over a copy.
- Hand-rolled `{ hasNext(), next() }` objects do not work with `for...of`, spread, or `Array.from`.

## Related

- Traverses [Composite](composite.md) trees. Pairs with [Visitor](visitor.md) to act on each element.
- [Factory Method](factory-method.md) lets a collection return the right iterator. [Memento](memento.md) can snapshot iteration state.
