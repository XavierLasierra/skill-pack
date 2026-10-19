---
name: fe-react-effects
description: Decide if code belongs in useEffect, an event handler, or render. Use for adding/removing a useEffect, derived state, state desync, fetch in useEffect, race condition, or whether to useMemo/useCallback/memo. Slow app or profiling → fe-react-performance.
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
- Expensive recompute → `useMemo`, not an Effect that writes state — but only if measured; see Performance below.

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
- Memoization rule lives here. With React Compiler enabled (opt-in `babel-plugin-react-compiler`, not part of React 19 itself), it auto-memoizes — do **not** hand-write `useMemo`/`useCallback`/`memo`. Without it, add them only to fix a re-render the Profiler shows ([[fe-react-performance]]).
- Premature memoization is clutter; treat it as code to justify, not a default.
