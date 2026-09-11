# Memento

Behavioral.

## Intent

Save snapshots of an object's state and restore them later without exposing its internals.

## Use when

- Undo, rollback, "restore draft", checkpoints before a risky operation.
- The object's internals must stay private, so outsiders cannot rebuild it field by field.

## Do not use when

- State is small and immutable. Then the state value is its own memento: keep the previous value.
- Operations are cheap to reverse individually. Then [Command](command.md) with `undo()` avoids storing whole snapshots.

## Example

```ts
type EditorState = { readonly text: string; readonly cursor: number }

const createHistory = (initial: EditorState) => {
  const stack: EditorState[] = [initial]
  return {
    commit: (next: EditorState) => stack.push(next),
    undo: (): EditorState => {
      if (stack.length > 1) stack.pop()
      return stack[stack.length - 1] as EditorState
    },
  }
}
```

Immutable state makes the snapshot free: the state value is its own memento.

## Pitfalls

- Snapshots of mutable state must be deep copies (`structuredClone`) or later mutations corrupt history.
- Storing every keystroke fills memory. Bound the stack or store diffs.
- A snapshot that captures references to live resources (connections, timers) restores nothing useful.

## Related

- [Command](command.md) plus Memento is the standard undo/redo. [Prototype](prototype.md) is enough for simple copies.
- Can capture and resume [Iterator](iterator.md) state.
