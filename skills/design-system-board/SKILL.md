---
name: x-design-system-board
description: "Generate a production-ready design system documentation board: dark theme, tech blue brand, sections DS-00 to DS-05, laid out like a Figma file ready for developer handoff."
argument-hint: "[product, theme, or brand overrides]"
disable-model-invocation: true
---

# Design system board

Generate a comprehensive, production-ready design system documentation board for an Enterprise Automation web app.

If the user gave arguments (product, theme, brand color), they replace the defaults below. Everything else stays.

## Defaults

- Theme: dark mode, deep grays and slate tones.
- Primary brand color: tech-focused blue.
- Layout: a clean, organized grid of labeled sections.

## Sections

**DS - 00 Overview.** A text-heavy section with design principles and general usage rules.

**DS - 01 Color.**
- Primitive palette: grayscale and primary color swatch scales, 100 to 900.
- Semantic roles: map colors to backgrounds, text, borders, and interactive states (success, warning, error).

**DS - 02 Typography.** A complete type scale, from small captions to large H1 headings, plus a section with writing rules.

**DS - 03 Foundations.** Visual examples and scales for spacing tokens, border radius sizes, and elevation (drop shadows).

**DS - 04 Component Usage.** Component behavior and anatomy guidelines.

**DS - 05 Components.** A core native component library. Show each element in default, hover, and disabled states. Must include:
- Primary and secondary buttons
- Text fields
- Status badges
- Navigation items

## Output

- Must look like a professional, organized Figma file ready for developer handoff.
- Clear section dividers, large section headers, high-contrast typography.
- Components use the tokens from DS-01 to DS-03, not one-off values.
