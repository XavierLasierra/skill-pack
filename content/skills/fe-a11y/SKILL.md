---
name: fe-a11y
description: Make a React/React Native UI accessible. Use when asked to fix accessibility/a11y, add ARIA, support keyboard or screen-reader users, manage focus, check color contrast, or audit a component for WCAG. Covers web and React Native.
targets: [all]
---
## Accessibility (a11y)

The biggest quality lever most teams skip. Most issues are missing semantics, broken focus, unlabeled controls, and silent dynamic updates. Pairs with [[fe-react-component]].

### Semantic element first — the rule that prevents most bugs
- Use the real element: `<button>`, `<a href>`, `<nav>`, `<label>`, `<h1>`–`<h6>`. They ship focus, keyboard, and role for free.
- A `<div onClick>` is not a button. If you truly must, add `role`, `tabIndex={0}`, and key handlers — but first ask why not a `<button>`.
- One `<h1>` per page; don't skip heading levels for styling.

### Labels
- Every input has a programmatic label (`<label htmlFor>` or wrapping). Placeholder is not a label.
- Icon-only buttons need an accessible name: visually-hidden text or `aria-label`.
- Images: meaningful `alt`; decorative → `alt=""`.

### Keyboard & focus
- Everything interactive is reachable and operable by keyboard (Tab/Enter/Space/Esc). Visible focus ring — never `outline: none` without a replacement.
- Modal/dialog: move focus in on open, trap it, restore it to the trigger on close.
- Don't add `tabIndex` > 0 (breaks natural order).
- Touch target size is WCAG 2.5.8 (≥ 24×24 px floor) — sizing and thumb reach live in [[fe-touch]].

### ARIA — only when no native element fits
- First rule of ARIA: don't use ARIA if a native element does the job. Wrong ARIA is worse than none.
- Announce dynamic changes (toasts, async results, errors) via a live region (`aria-live="polite"`) so screen readers don't miss them.
- Tie field errors to inputs with `aria-describedby` + `aria-invalid`.

### Color
- Text contrast ≥ 4.5:1 (≥ 3:1 for large text ≥ 24px / 18.66px bold). Don't encode meaning with color alone — add text or icon.

### React Native deltas
- Set `accessible`, `accessibilityRole`, `accessibilityLabel`, `accessibilityState` on custom controls. `Pressable`/`Button` carry roles; bare `View`/`Text` don't.
