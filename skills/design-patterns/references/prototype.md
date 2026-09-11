# Prototype

Creational.

## Intent

Create new objects by copying a configured existing one instead of rebuilding it from scratch, without depending on its concrete class.

## Use when

- A configured object is expensive or tedious to set up and you need many variations of it (presets, templates, "duplicate this document").
- You hold an object through an interface and must copy it without knowing its concrete type.

## Do not use when

- The object is a plain data record. Spread syntax is the whole pattern.
- Copying is cheap and the object has no meaningful configuration.

## Example

```ts
type Widget = { color: string; size: number; tags: string[] }

const base: Widget = { color: 'gray', size: 16, tags: [] }
const red: Widget = { ...base, color: 'red' } // shallow copy: tags array still shared
const detached: Widget = structuredClone(base) // deep copy, no shared references
```

## Pitfalls

- `structuredClone` drops functions and class prototypes and throws on DOM nodes. Objects with methods need their own `clone()`.
- Spread copies one level. A nested array or object is still shared; mutating it changes both copies.
- Deep-cloning an object holding a DB connection or socket is a bug, not a copy. Reconnect instead.

## Related

- Alternative to [Factory Method](factory-method.md) when configuration, not type selection, is the hard part.
- Simpler than [Memento](memento.md) for snapshots of simple objects.
- Copies [Command](command.md) objects into history, and [Composite](composite.md) trees.
