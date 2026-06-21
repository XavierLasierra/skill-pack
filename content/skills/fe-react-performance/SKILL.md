---
name: fe-react-performance
description: Diagnose and fix React performance problems. Use when the app is slow, components re-render too often, interactions lag, or the bundle is too big. A measure-first debugging workflow. For the "don't pre-memoize" rule see fe-react-effects.
targets: [all]
---
## React Performance

Measure before you optimize. Most "optimizations" added blind are clutter that fixes nothing. This is a debugging workflow; the standing memoization rule lives in [[fe-react-effects]].

### 1. Measure first
- React DevTools **Profiler**: record the slow interaction, sort by render duration, find components rendering frequently or > 16ms.
- Enable **"Record why each component rendered"** in Profiler settings — it names the culprit prop/state.
- `why-did-you-render` flags re-renders caused by unstable prop identity.
- Never optimize a component you haven't measured. Confirm the bottleneck is render (vs. network/data — that's [[fe-react-data-fetching]]).

### 2. Fix unnecessary re-renders (in order)
- **Keep state close to where it's used.** Lifting state too high re-renders whole subtrees. Move it down or split the component.
- **Don't pass fresh objects/arrays/functions as props** to memoized children — that defeats the memo. Stabilize the value, or stop memoizing.
- **Stable `key`s** from data, never index — index keys cause wrong reconciliation and extra work.
- On React 19's compiler, auto-memoization handles most of this — measure before adding manual memo. Off the compiler: `memo` a pure child, `useMemo` a >16ms calc, `useCallback` a handler passed to a memoized child. Only after the Profiler points there.

### 3. Cut bundle size
- **Route-based code splitting first** — `React.lazy` + `Suspense` per route. Biggest win for least effort.
- Run a bundle analyzer; lazy-load heavy leaf components (editors, charts, maps).
- Server Components (App Router) ship zero JS for static parts — see [[fe-react-component]].

### React Native deltas
- Long lists: `FlatList`/`SectionList` with `keyExtractor` and a memoized `renderItem` — never `.map()` in a `ScrollView`. See [[fe-react-native-component]].
- Confirm Hermes is enabled; profile with the RN/Flipper profiler.
