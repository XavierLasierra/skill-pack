---
name: fe-react-component
description: Write or refactor a clean React component. Use when asked to create, build, write, or refactor a React/JSX/TSX component, fix a messy component, design a component's props API, decide whether to reuse an existing component, or place a shared vs feature/domain component. Covers reuse-before-create, common vs domain components, composition, props design, hooks, lists/forms, and Server vs Client components. For state/effect discipline see fe-react-effects.
targets: [all]
---
## React Component

Builds on [[cq-clean-code]] — apply it, don't repeat it. For state, effects, and re-render performance, use [[fe-react-effects]]. The best component is small, pure, and composed from smaller ones.

Presentation siblings: [[fe-responsive]] (layout), [[fe-touch]] (mobile/tablet), [[fe-ui-states]] (loading/empty/error), [[fe-ui-foundations]] (spacing/tokens), [[fe-a11y]].

### Before you create one
- Search first. The best new component is the one you didn't write — reuse or compose an existing one before building a new variant. Two near-identical components are a bug.
- Reuse vs duplicate is a judgment, not a reflex: reuse when the data flow and props fit; if making the existing one fit means bending its API or threading flags through it, copy instead and let the two diverge.
- Don't pre-generalize. A one-off lives next to its only caller. Promote it to shared only on the second or third real use — usage proves the abstraction, not a guess.

### Common vs domain components
Separate the two; it decides where the file lives and what it may import.
- **Common / shared** (`shared/components`, the design system): generic, presentational, zero business logic or domain types. `Button`, `Input`, `Modal`, `Card`. Reusable in any feature. A shared component that imports domain code is no longer shared — that's the test.
- **Domain / feature** (`features/<x>/components`): composed from common components, knows the feature's data and rules. `CheckoutSummary`, `InvoiceRow`.
- **Dependency direction is one-way:** features import shared, never the reverse; features don't import each other. Cross-feature need → lift the piece into shared.

### Shape
- One component does one thing. If it fetches, transforms, and renders three sections, split it.
- Prefer composition over configuration. Pass `children` and slot props instead of growing a prop list to switch internal layout.
- Function components only. No classes.
- Keep the body flat — extract event handlers and derived values to named consts above the `return`, not inline in JSX.
- Co-locate: component, its styles, and its component-specific hooks live in the same folder.
- No hardcoded colors, spacing, or sizes — pull them from theme tokens / the scale so a restyle is one edit, not a sweep ([[fe-ui-foundations]]).

```tsx
// ❌ config explosion
<Card hasHeader title="x" hasFooter footerText="y" bodyVariant="padded" />

// ✅ composition
<Card>
  <Card.Header>x</Card.Header>
  <Card.Body padded>…</Card.Body>
  <Card.Footer>y</Card.Footer>
</Card>
```

### Props API
- Kill the boolean trap. 3 booleans = 8 invalid combos. Use one `variant="primary"` union, not `isPrimary`/`isDanger`/`isGhost`.
- Make invalid states unrepresentable with discriminated unions in TS.
- Many required props → the component is doing too much. Split it.
- Don't spread `{...props}` blindly onto a DOM node — name what you pass.
- Accept `children` over a `content`/`items`-of-JSX prop.

```tsx
// ✅ discriminated union — TS rejects {status:'error'} without message
type Props =
  | { status: 'loading' }
  | { status: 'error'; message: string }
  | { status: 'ok'; data: Data }
```

### Hooks
- Top level only — never in conditions, loops, or nested functions. Same order every render.
- Custom hook the moment the same stateful logic appears in two components. Prefix `use`, one hook per file, return a stable shape.
- Components and hooks must be pure: same inputs → same JSX, no side effects during render, no mutation of props/state.

### Lists & forms
- `key` must be a stable id from the data — never the array index, never `Math.random()`.
- Inputs: default to controlled (`value` + `onChange`). Reach for uncontrolled (`defaultValue`/refs) only for simple or perf-sensitive forms. Real forms (validation, many fields) → [[fe-react-forms]].

### Server vs Client (RSC / Next.js App Router)
- Default to Server Components. They ship zero JS, fetch data directly, and keep secrets server-side.
- Add `'use client'` only on the component that needs interactivity, browser APIs, state/effects, or event handlers — and push it **as deep in the tree as possible**. Don't mark a whole page client because one button is interactive.
- Server Components can't use state/effects/handlers. Compose: server parent fetches, passes data to a small client leaf.
