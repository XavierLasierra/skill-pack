---
name: fe-ui-foundations
description: Apply systematic UI consistency — spacing scale, type scale, design tokens, radius/elevation, dark mode. Use when values look arbitrary, spacing/sizing is inconsistent, setting up design tokens or a type scale, or adding dark mode. The standards layer; for bespoke visual identity use artifact-design.
targets: [all]
---
## UI Foundations

Consistency is what separates clean UI from amateur UI: a small set of repeated values, never arbitrary ones. This is the systematic *standards* layer — the spacing/type/token rules. The bespoke palette and visual identity belong to `artifact-design`; this makes whatever identity you pick consistent.

### Spacing — one scale, no magic numbers
- All margin/padding/gap come from an **8pt scale**: 4, 8, 12, 16, 24, 32, 48, 64. Pick from the scale; never `padding: 13px`.
- 4px is the smallest step (icon nudges, tight pairs); 8 and up for everything else.
- Internal padding ≤ surrounding margin so grouped things read as grouped (proximity).

### Type scale
- A fixed set of sizes (e.g. 12/14/16/20/24/32/48), not one-off `font-size`s. 16px base body.
- Line-height ~1.5 for body, tighter (~1.1–1.25) for headings; line length capped (~65ch).
- Weight and size establish hierarchy — don't rely on color alone ([[fe-a11y]]).

### Design tokens — semantic, not raw
- Reference tokens by **role**, not value: `--color-bg`, `--color-text`, `--color-danger`, `--space-4`, `--radius-md`. Components never hard-code `#1a1a1a` or `13px`.
- One source of truth; changing a token restyles everywhere. This is what makes dark mode and theming a config change, not a rewrite.

### Radius & elevation
- A small radius set (e.g. 4/8/16/full) applied by role; one element, one radius language.
- Convey depth with a defined shadow scale, not random `box-shadow`s; don't stack many heavy shadows.

### Dark mode
- Build it on semantic tokens from the start — swap token values, don't fork components.
- Dark ≠ pure black on white inverted: use near-black surfaces, slightly dimmed text, and re-check contrast (≥ 4.5:1, [[fe-a11y]]) in both themes.
- Respect `prefers-color-scheme`; let users override.
