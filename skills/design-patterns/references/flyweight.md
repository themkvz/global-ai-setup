# Flyweight

Structural.

## Intent

Fit more objects in memory by sharing the parts of state that are identical across many instances, keeping only the varying part per instance.

## Use when

- You have measured memory pressure from a very large number of similar objects (map markers, glyphs, particles, tokens in an editor, rows in a grid).
- Objects contain heavy immutable data (textures, parsed schemas, compiled regexes) duplicated across instances.

## Do not use when

- You have not measured. This is an optimization with a real readability cost.
- The shared part is small. Duplicating a few numbers is cheaper than an indirection.

## Example

```ts
type Sprite = { readonly model: string; readonly texture: Uint8Array } // shared, immutable

const sprites = new Map<string, Sprite>()

const getSprite = (model: string): Sprite => {
  const cached = sprites.get(model)
  if (cached) return cached
  const sprite: Sprite = { model, texture: loadTexture(model) }
  sprites.set(model, sprite)
  return sprite
}

declare const loadTexture: (model: string) => Uint8Array
```

## Pitfalls

- The shared part must be immutable. One mutation is visible everywhere.
- The cache must be bounded or cleared, or the flyweight becomes the leak. Use an LRU or `WeakRef` when keys are unbounded.
- Recomputing extrinsic context on every call trades memory for CPU. Measure both.

## Related

- Shared leaves of a [Composite](composite.md) tree are flyweights.
- [Singleton](singleton.md) is one mutable instance. Flyweight is many immutable ones.
- [Facade](facade.md) makes one object for a subsystem. Flyweight makes many small ones.
