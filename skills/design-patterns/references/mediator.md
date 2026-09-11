# Mediator

Behavioral.

## Intent

Stop components from talking to each other directly. They talk to one mediator, which knows the rules of collaboration.

## Use when

- Components reference each other in a web (form fields enabling other fields, chat users messaging users, panels syncing panels), and changing one breaks others.
- Components should be reusable outside this specific collaboration.

## Do not use when

- Two components talk. One callback prop.
- The mediator would just forward calls with no rules. That is an [Observer](observer.md) bus.
- In React, a shared store (Zustand) or lifted state already is the mediator. Do not add another.

## Example

```ts
type Listener = (message: string, from: string) => void

const createRoom = () => {
  const members = new Map<string, Listener>()
  return {
    join: (name: string, listener: Listener) => members.set(name, listener),
    send: (from: string, message: string) => {
      for (const [name, listener] of members) if (name !== from) listener(message, from)
    },
  }
}
```

Members know `room`, never each other. Collaboration rules live in `send`, not scattered across members.

## Pitfalls

- The mediator absorbs every interaction rule and becomes the god object. Split by feature when it stops fitting on one screen.
- Debugging indirect flows is harder. Name events and keep the mediator's API small and explicit.

## Related

- [Observer](observer.md) is often the mechanism inside a mediator (mediator publishes, components subscribe).
- [Facade](facade.md) is one-directional and adds no rules. Mediator coordinates peers.
- [Chain of Responsibility](chain-of-responsibility.md) and [Command](command.md) are the other sender/receiver decouplings.
