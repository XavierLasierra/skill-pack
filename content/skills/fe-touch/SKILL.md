---
name: fe-touch
description: Make a UI work for touch on mobile and tablet. Use when designing for phones/tablets, sizing tap targets, spacing buttons, placing primary actions, handling hover-only interactions, or fixing notch/safe-area issues. Covers web touch and React Native.
targets: [all]
---
## Touch & Mobile Interaction

Fingers are not cursors. A layout can be responsive ([[fe-responsive]]) and still fail on touch if targets are tiny, cramped, or out of thumb reach.

### Target size
- Minimum **44×44pt** (iOS HIG) / **48×48dp** (Android Material). WCAG 2.5.8 floor is 24×24 CSS px — treat that as the never-go-below, not the goal. See [[fe-a11y]].
- The *hit area* must meet the minimum even if the visual is smaller — pad the target, don't shrink the finger. Icon buttons especially.
- **≥ 8px** between adjacent targets to prevent mis-taps.

### Reach & placement
- Primary actions in the **bottom third** (thumb zone) on phones; top corners are the hardest one-handed reach. Put destructive/rare actions away from the easy zone.
- Tablets are used two-handed and in both orientations — don't assume a single thumb origin; keep primary actions reachable in landscape and portrait.

### Touch-first interaction
- Never gate functionality behind `:hover` or right-click — touch has neither. Hover is enhancement only; the action must work on tap.
- Use real controls (`<button>`, `<a>`, RN `Pressable`) so you get tap, focus, and a11y for free — not `onClick` on a `div`.
- Give visible press feedback (active/pressed state); avoid 300ms tap delay (`touch-action: manipulation`).
- Make swipe/long-press shortcuts, never the only way to do something.

### Viewport & safe areas
- `<meta name="viewport" content="width=device-width, initial-scale=1">`; never disable zoom.
- Keep content clear of notches, rounded corners, and home indicators: `env(safe-area-inset-*)` on web, `SafeAreaView`/insets in RN ([[fe-react-native-component]]).
- Inputs ≥ 16px font on iOS or the browser force-zooms on focus.
