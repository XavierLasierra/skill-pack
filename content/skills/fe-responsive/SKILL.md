---
name: fe-responsive
description: Make a UI responsive across viewports. Use when asked to make a layout responsive, fix mobile/tablet/desktop layout, set breakpoints, build a fluid grid, scale typography, or stop horizontal scroll. Web-focused; for touch sizing see fe-touch, for native RN see fe-react-native-component.
targets: [all]
---
## Responsive Layout

One layout that adapts — not separate mobile and desktop builds. Mobile-first: write the small-screen styles, then add complexity upward. Pairs with [[fe-touch]] (interaction sizing) and [[fe-ui-foundations]] (the scale).

### Mobile-first, content-driven breakpoints
- Author base styles for the smallest screen; enhance up with `min-width` media/container queries. Never start desktop and patch downward.
- Put breakpoints where *the content* breaks — when a line gets too long or a grid cramps — not at device pixel widths. ~480 / 768 / 1024 / 1280 / 1536px are starting references, not targets.
- Test the three real shapes: phone portrait, tablet, desktop — plus one in between.

### Fluid over fixed
- Layout in fractions, not pixels: CSS Grid `repeat(auto-fit, minmax(min, 1fr))`, flexbox, `%`. Avoid fixed widths that force horizontal scroll.
- **Fluid type** with `clamp(min, preferred-vw, max)` — scales smoothly, kills most typography breakpoints.
- `gap` for spacing between tracks; cap line length (`max-width: 65ch`) for readability.

```css
.grid { display: grid; gap: 1rem; grid-template-columns: repeat(auto-fit, minmax(16rem, 1fr)); }
h1 { font-size: clamp(1.5rem, 1rem + 2.5vw, 3rem); }
```

### Container queries for reusable components
A component should respond to *its container*, not the viewport — so it works in a hero and a sidebar unchanged. Use `@container` (production-ready, ~93%+ support) for component-level breakpoints; reserve viewport media queries for page-level layout.

```css
.card-wrap { container-type: inline-size; }
@container (min-width: 28rem) { .card { grid-template-columns: auto 1fr; } }
```

### Media & overflow
- Images: `max-width: 100%`, `height: auto`, set `aspect-ratio` to reserve space; `srcset`/`sizes` to ship the right resolution per screen.
- Wide content (tables, code, diagrams) scrolls inside its own `overflow-x: auto` container — the page body must never scroll horizontally.
- Respect `prefers-reduced-motion` and the safe-area insets ([[fe-touch]]).
