---
name: design-patterns
description: Find and apply the right design pattern (refactoring.guru catalog, GoF creational/structural/behavioral) for a concrete coding situation, or reject one when a plain TypeScript feature suffices. Use when structuring new code, refactoring conditionals, duplication, or coupling, reviewing an abstraction, or when the user names a pattern (strategy, observer, factory, adapter, decorator, state, command, builder, proxy, visitor, etc.) or asks "which pattern", "how should I structure this", "is this over-engineered".
---

# Design Patterns

Router. Each pattern has a detailed guide in `references/<pattern>.md`: intent, use when, do not use when, a short TypeScript example, pitfalls, related patterns. Read the guide before applying a pattern.

## Workflow

1. Name the pain in one sentence (symptom, not pattern). Read the code it touches first.
2. Look up the symptom in the table below.
3. Check the **Native TS form** column. That is the default; it is usually the whole solution.
4. Read `references/<pattern>.md` and its "Do not use when" section before adding structure.
5. Apply the minimal form. Add the class-based form only when the guide says it earns its place.
6. State the trade-off in one line: what it costs, when to upgrade.

## Symptom → pattern

| You see | Pattern | Native TS form |
|---|---|---|
| `if`/`switch` choosing between algorithm variants | [Strategy](references/strategy.md) | pass a function |
| Behavior depends on a status field, checked in many places | [State](references/state.md) | discriminated union + transition function |
| Same operation for every member of a union or tree, logic lives outside the types | [Visitor](references/visitor.md) | exhaustive `switch` / `ts-pattern` |
| Undo, queue, schedule, retry, or audit an operation | [Command](references/command.md) | `{ execute, undo }` object |
| Restore previous state, rollback | [Memento](references/memento.md) | immutable snapshots in an array |
| Many parts react when something changes | [Observer](references/observer.md) | subscribe function, `EventTarget`, store |
| Components call each other directly, N×N coupling | [Mediator](references/mediator.md) | event bus / store |
| Several handlers may process a request in order | [Chain of Responsibility](references/chain-of-responsibility.md) | array of handlers / middleware |
| Custom traversal of a collection or tree | [Iterator](references/iterator.md) | generator / `Symbol.iterator` |
| Same algorithm skeleton, a few steps differ | [Template Method](references/template-method.md) | function taking a hooks object |
| Two things vary independently (what × how), class count multiplies | [Bridge](references/bridge.md) | pass the implementation in |
| Third-party interface does not match yours | [Adapter](references/adapter.md) | wrapper mapping to your type |
| Add behavior around an existing function without changing it | [Decorator](references/decorator.md) | higher-order function |
| Cache, lazy-load, guard, or log access, same interface | [Proxy](references/proxy.md) | wrapper with the same type |
| Part/whole tree, callers treat leaf and container alike | [Composite](references/composite.md) | recursive union type |
| Subsystem with many moving parts, callers need a few operations | [Facade](references/facade.md) | module exporting a few functions |
| Huge number of similar objects, memory pressure | [Flyweight](references/flyweight.md) | `Map` cache of shared immutable parts |
| Code picks a concrete implementation from config or env | [Factory Method](references/factory-method.md) | function returning the interface type |
| Need a matching set of implementations (prod vs test infra) | [Abstract Factory](references/abstract-factory.md) | object of factory functions |
| Many optional constructor params, or multi-step construction | [Builder](references/builder.md) | options object with defaults |
| Copy an object including its configuration | [Prototype](references/prototype.md) | spread / `structuredClone` |
| Exactly one shared instance | [Singleton](references/singleton.md) | ES module export |

## Rules

- A language feature that solves the problem beats a pattern. Functions, closures, discriminated unions, generators, modules, and `Map` cover most of the catalog.
- One variant is not a pattern. Strategy, Factory, Adapter, Bridge earn their place at the second concrete implementation, not before.
- Reach for the class-based form only when a framework demands subclassing or the object carries private mutable state plus several methods over it.
- Structure identical, intent differs: Decorator vs Proxy, Strategy vs State, Facade vs Mediator. Pick by the guide's intent line and move on. Do not debate the name.
- Prefer what the project already has: framework middleware over hand-rolled Chain of Responsibility, Zustand or TanStack Query over hand-rolled Observer, `ts-pattern` over a hand-written Visitor.
- Naming makes the pattern visible: `with*` for Decorator/Proxy wrappers, `create*` for factories, `adapt*` for adapters, `transition` for State, `*Handlers` for chains.

## Anti-signals

Do not apply a pattern when:

- the code has one implementation and no concrete second one is scheduled
- the "flexibility" is speculative ("someone might want to swap the DB")
- a conditional with two or three stable branches is clear as written
- the pattern's own guide lists the situation under "Do not use when"

## Recommendation format

When asked which pattern fits, answer with:

1. Pattern name and one-line intent.
2. Why it matches this code (the symptom).
3. Minimal TypeScript form, in the project's style.
4. What it costs and when to upgrade to the fuller form.
5. The nearest alternative and why it lost.
