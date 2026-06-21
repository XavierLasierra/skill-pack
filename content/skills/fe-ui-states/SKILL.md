---
name: fe-ui-states
description: Design the loading, empty, error, and success states of a UI. Use when building data-driven screens, adding skeletons/spinners, designing empty states, error/retry UI, or handling the states beyond the happy path. The UX side of fe-react-data-fetching.
targets: [all]
---
## UI States

Every screen that loads data has four states, not one. The happy path is the easy 25% — empty, loading, and error are what AI and rushed builds skip. This is the *UX* of those states; the *data* wiring lives in [[fe-react-data-fetching]].

### Loading — skeleton, not spinner
- Use a **skeleton** (low-fidelity outline of the incoming content) for containers/lists/cards/tables. It sets expectations, cuts perceived wait ~30%, and prevents layout shift when real content lands.
- Skeleton must match the real content's shape and size so nothing jumps on arrival.
- A spinner is fine only for short, indeterminate, in-place waits (a button submitting). **Don't** skeletonize buttons, toggles, toasts, menus, or modals.
- Show loading only after a short delay (~200–300ms) so fast responses don't flash.

### Empty — never a blank box
- Say why it's empty and give the next action: "No invoices yet" + a **Create invoice** button.
- Distinguish *empty* (no data yet — invite action) from *no results* (filter/search matched nothing — offer to clear/adjust). They need different copy.

### Error — explain and offer a way out
- Plain-language message + a **Retry** action. Include an error code when one exists — it helps support.
- Don't dump stack traces or raw 500s at users. Keep partial UI usable; scope the error to the failed region, don't blank the whole page.
- Validation/inline errors tie to their field — see [[fe-a11y]] and [[fe-react-forms]].

### General
- Build these as reusable, separated components, not inline ternaries copied per screen — standardize them once.
- Don't shift layout between states: reserve space so loading → loaded → error swaps don't jump.
- Announce async state changes to assistive tech (live region, [[fe-a11y]]).
