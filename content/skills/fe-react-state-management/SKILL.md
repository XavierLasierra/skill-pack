---
name: fe-react-state-management
description: Choose where React state should live. Use when deciding between local state, Context, Zustand, Jotai, Redux, or a server-cache, fixing global-state re-render problems, or asked "do I need Redux/Zustand/a store". A decision guide, not a library tutorial.
targets: [all]
---
## React State Management

Pick the smallest tool that solves the actual problem. Most apps need far less global state than they reach for. Pairs with [[fe-react-effects]] and [[fe-react-data-fetching]].

### First, classify the state
- **Derived** — computable from props/state → not state at all. Compute in render ([[fe-react-effects]]).
- **Server** — fetched from an API → not client state. Use [[fe-react-data-fetching]] (TanStack Query), not a global store.
- **Local UI** — used by one subtree → `useState`/`useReducer`, kept close.
- **Shared client** — genuinely cross-tree client state → see the ladder below.

Half of "global state" problems disappear once server data moves to a query cache.

### The ladder — stop at the first rung that holds
1. **Lift state** to the nearest common parent. Pass props. Done for most cases.
2. **Context** — for low-frequency, rarely-changing shared values: theme, locale, auth user, feature flags. Not for high-frequency state: every consumer re-renders on any change, so a cart/dashboard in Context lags.
3. **Zustand** — the default external store when Context re-renders hurt. Simple, fast, selector-based subscriptions; good for ~90% of shared-state needs.
4. **Jotai** — when you need fine-grained, atom-level reactivity and derived graphs; only the components reading a changed atom re-render.
5. **Redux Toolkit** — large teams needing enforced patterns, middleware for complex side effects, or time-travel debugging. Most apps no longer need it; if you reach here, use RTK, never legacy Redux.

### Rules
- Don't add a store "to be safe." Adding one is reversible; the complexity tax is not. Justify the rung.
- Never duplicate server data into a client store — invalidate the query cache instead.
- Context performance fix is splitting providers or moving to a selector store, not memo bandaids.
