# Factory Method

Creational.

## Intent

Provide one place that creates objects behind an interface, so callers never name the concrete type and the choice can change without touching them.

## Use when

- Callers should not know the concrete implementation: it is picked from config, env, or a runtime flag.
- A library or framework must let users plug in their own implementation.
- Creation is expensive and instances should be pooled or reused.

## Do not use when

- There is one concrete type. Call its constructor or factory function directly.
- The choice is made once at startup and never varies. A plain `if` at the composition root is enough.
- The classic form (abstract `createProduct()` overridden in subclasses) is only needed when a framework forces subclassing.

## Example

```ts
type Notifier = { send: (to: string, body: string) => Promise<void> }

const createEmailNotifier = (): Notifier => ({ send: async (to, body) => {/* SMTP */} })
const createSmsNotifier = (): Notifier => ({ send: async (to, body) => {/* SMS API */} })

// The factory method: the only place that knows the concrete type.
const createNotifier = (channel: 'email' | 'sms'): Notifier =>
  channel === 'sms' ? createSmsNotifier() : createEmailNotifier()
```

## Pitfalls

- A factory that grows a `switch` with ten cases is a lookup table: `const factories: Record<Channel, (c: NotifyConfig) => Notifier>`.
- Do not hide the decision inside the product. The factory decides, the product does its job.
- Keep the return type the interface, never the concrete type, or the abstraction leaks.

## Related

- Grows into [Abstract Factory](abstract-factory.md) when a whole family of related objects must match.
- [Builder](builder.md) when construction is multi-step. [Prototype](prototype.md) when copying a configured object is cheaper than building.
- A step inside [Template Method](template-method.md) is often a factory method.
