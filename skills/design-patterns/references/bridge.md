# Bridge

Structural.

## Intent

Split something that varies along two independent axes into two hierarchies, abstraction and implementation, so they can change separately instead of multiplying.

## Use when

- You see class names like `EmailAlert`, `SlackAlert`, `EmailDigest`, `SlackDigest`: N kinds × M platforms.
- The implementation must be switchable at runtime (different DB driver, renderer, transport) while high-level logic stays the same.

## Do not use when

- Only one axis varies. That is [Strategy](strategy.md) or plain parameterization.
- The class is cohesive and small. Splitting it adds indirection with no second axis to justify it.

## Example

```ts
// Implementation axis: how a message gets delivered.
type Channel = { deliver: (to: string, text: string) => Promise<void> }

// Abstraction axis: what gets sent. Neither axis knows the other varies.
const sendAlert = (channel: Channel) => (to: string, incidentId: string) =>
  channel.deliver(to, `ALERT ${incidentId}`)

const sendDigest = (channel: Channel) => (to: string, items: string[]) =>
  channel.deliver(to, items.map((item) => `- ${item}`).join('\n'))

const alertBySlack = sendAlert(slackChannel)
const digestByEmail = sendDigest(emailChannel)

declare const slackChannel: Channel
declare const emailChannel: Channel
```

Two abstractions × any number of channels, with no new class per combination — that is the multiplication Bridge avoids.

## Pitfalls

- Bridge is a design-time decision. If you are gluing existing incompatible code, you want [Adapter](adapter.md).
- Keep the implementation interface primitive (`deliver`), keep the abstraction expressive (`sendAlert`). Mixing levels collapses the bridge.

## Related

- Same shape as [Strategy](strategy.md) and [State](state.md): composition with an injected object. Different problem.
- [Abstract Factory](abstract-factory.md) can create the matching implementation for an abstraction.
- [Builder](builder.md) with several builders behind one director is a bridge.
