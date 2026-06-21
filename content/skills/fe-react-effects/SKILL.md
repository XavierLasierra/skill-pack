---
name: fe-react-effects
description: Decide whether code belongs in useEffect, an event handler, or render, and avoid useEffect overuse. Use when adding/removing a useEffect, handling derived state, fixing extra re-renders or state desync, or deciding on useMemo/useCallback/memo. Pairs with fe-react-component.
targets: [all]
---
## React State & Effects

State and effect discipline for React components. Most `useEffect` is a mistake. Pairs with [[fe-react-component]].

### The golden rule
Ask "why does this code run?"
- **"Because I can compute it from props/state"** → calculate during render. Never mirror props into state.
- **"Because the user did X"** → event handler.
- **"Because the component appeared / syncs an external system"** → `useEffect`.

```tsx
// ❌ derived state in an Effect — extra render pass, can desync
const [fullName, setFullName] = useState('')
useEffect(() => { setFullName(`${first} ${last}`) }, [first, last])

// ✅ just compute it
const fullName = `${first} ${last}`
```

### Effect-removal cheatsheet
- Resetting all state when a prop changes → give the component a `key={id}`, don't reset in an Effect.
- Adjusting state on prop change → store an id, derive the object: `const sel = items.find(i => i.id === selId) ?? null`.
- Notifying the parent → call `onChange` in the same handler that set the state, not in an Effect watching it.
- Chained `setState` Effects → do it all in one event handler.
- Expensive recompute → `useMemo`, not an Effect that writes state.

### When useEffect IS right
Data fetching, subscriptions/event listeners, analytics-on-mount, driving non-React widgets.
- Always return cleanup when you subscribe.
- Fetch with an `ignore` flag to kill races:
```tsx
useEffect(() => {
  let ignore = false
  fetch(url).then(r => r.json()).then(d => { if (!ignore) setData(d) })
  return () => { ignore = true }
}, [url])
```
- For external stores prefer `useSyncExternalStore` over a manual subscribe Effect.

### Performance
- React 19's compiler auto-memoizes — do **not** preemptively wrap everything in `useMemo`/`useCallback`/`memo`. Add them only to fix a measured re-render, or when not on the compiler.
- Premature memoization is clutter; treat it as code to justify, not a default.
