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
- Modal/dialog: prefer native `<dialog>` + `showModal()` (built-in focus trap, Esc, focus restore, inert background). Otherwise mark the background `inert` and move/restore focus manually.
- **2.4.11 Focus Not Obscured**: sticky headers/footers must not cover the focused element — use `scroll-padding-top/bottom` ≥ their height.
- **2.5.7 Dragging Movements**: every drag (sliders, reorder, drag-drop) has a single-pointer alternative (buttons, tap-to-place).
- Don't add `tabIndex` > 0 (breaks natural order).
- Target size (WCAG 2.5.8) and thumb reach: see [[fe-touch]].

### ARIA — only when no native element fits
- First rule of ARIA: don't use ARIA if a native element does the job. Wrong ARIA is worse than none.
- Announce dynamic changes (toasts, async results, errors) via a live region (`aria-live="polite"`) so screen readers don't miss them.
- Tie field errors to inputs with `aria-describedby` + `aria-invalid`.

### Forms & authentication (WCAG 2.2)
- **3.3.8 Accessible Authentication**: never block paste or password managers; no cognitive-function tests (puzzles, transcribing characters) without an alternative.
- **3.3.7 Redundant Entry**: don't make users re-enter info already given in the same flow — prefill or offer a select. See [[fe-react-forms]].

### Color & motion
- Text contrast ≥ 4.5:1 (≥ 3:1 for large text ≥ 24px / 18.66px bold). Don't encode meaning with color alone — add text or icon.
- **1.4.11 Non-text contrast** ≥ 3:1 for control boundaries, icons that carry meaning, and focus indicators.
- Honor `prefers-reduced-motion`: drop parallax/large transitions/autoplay under `@media (prefers-reduced-motion: reduce)`.

### React Native deltas
- Set `accessible`, `role`, `aria-label`, and `aria-disabled`/`aria-selected`/`aria-checked`/`aria-expanded`/`aria-busy` on custom controls (RN 0.71+). Fall back to legacy `accessibilityRole`/`accessibilityState` only where a prop has no `aria-*`/`role` equivalent. `Pressable`/`Button` carry roles; bare `View`/`Text` don't.
- Test with VoiceOver and TalkBack, not just linters.
