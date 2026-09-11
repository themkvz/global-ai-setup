# Template Method

Behavioral.

## Intent

Fix the skeleton of an algorithm in one place and let variants override specific steps without changing the order.

## Use when

- Several implementations run the same sequence with small differences in individual steps (import pipelines, report generation, request lifecycles).
- Duplicated step-by-step code across near-identical functions.

## Do not use when

- Only one step varies. Pass that one as a function ([Strategy](strategy.md)).
- The skeleton itself varies. Then there is no template.

## Example

```ts
type LineItem = { description: string; amount: number }
type InvoiceFormat = { header: (invoiceNumber: string) => string; line: (item: LineItem) => string }

const formatInvoice = (invoiceNumber: string, items: LineItem[], format: InvoiceFormat): string =>
  [format.header(invoiceNumber), ...items.map(format.line)].join('\n')
```

The skeleton (`header` then each `line`) is fixed; only the steps vary per format.

## Pitfalls

- Hooks that must be called in a specific order, or that share hidden state between steps, make the template fragile. Pass explicit data between steps.
- A template with ten hooks is a configuration DSL. Split the pipeline.
- Overriding a step to do nothing usually means the skeleton is wrong for that variant.

## Related

- [Strategy](strategy.md) replaces the whole algorithm at runtime. Template Method fixes the skeleton and varies steps.
- [Factory Method](factory-method.md) is a Template Method step that creates something.
