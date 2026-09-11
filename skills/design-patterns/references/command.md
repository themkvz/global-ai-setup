# Command

Behavioral.

## Intent

Turn an operation into a value that carries everything needed to run it, so it can be stored, queued, logged, replayed, or undone.

## Use when

- Undo/redo: each command knows how to reverse itself.
- Queueing, scheduling, retrying, or sending operations elsewhere (job queues, event sourcing, macros).
- UI actions bound to several triggers (button, shortcut, menu) that must stay in sync.

## Do not use when

- You just need to pass behavior around. A function is a command with no undo.
- Undo can be done by restoring a snapshot. Then [Memento](memento.md) with immutable state is less code.

## Example

```ts
type Command = { execute: () => void; undo: () => void }
type Doc = { text: string }

const insertText = (doc: Doc, at: number, value: string): Command => ({
  execute: () => {
    doc.text = doc.text.slice(0, at) + value + doc.text.slice(at)
  },
  undo: () => {
    doc.text = doc.text.slice(0, at) + doc.text.slice(at + value.length)
  },
})
```

## Pitfalls

- A command that reads current state at `undo()` time instead of what it captured at `execute()` time undoes the wrong thing after other commands ran.
- Serializable commands must not capture closures or live objects. Split into data plus a handler map.
- One class per command with `execute()` and nothing else is a function wearing a costume.

## Related

- [Memento](memento.md) stores state to undo, Command stores operations. They combine.
- [Strategy](strategy.md) is "how", Command is "what to do later".
- [Chain of Responsibility](chain-of-responsibility.md) handlers can be commands. [Visitor](visitor.md) is a command over many types.
- [Prototype](prototype.md) copies commands into history.
