---
name: fe-react-native-component
description: Write or refactor a clean React Native component. Use when building or fixing RN/Expo screens or components, choosing RN primitives, styling with StyleSheet, rendering long lists, or handling platform differences. Covers only what differs from web React — shared rules live in fe-react-component and fe-react-effects.
targets: [all]
---
## React Native Component

Composition, props API, hooks rules, state/effect discipline, and memoization are identical to web — apply [[fe-react-component]] and [[fe-react-effects]] unchanged. [[fe-touch]] (target sizes, safe areas) and [[fe-ui-foundations]] (spacing/type scale, tokens) apply too. Below is only what RN does differently.

### Primitives
- No DOM. Use `View`/`Text`/`Pressable`/`Image`/`ScrollView`, not `div`/`span`/`button`.
- All text must sit inside `<Text>` — bare strings under a `View` crash.
- `Pressable` over the older `TouchableOpacity`/`TouchableHighlight` for new code.
- No `'use client'` / Server Components — RN is all client. Ignore that section of [[fe-react-component]].

### Styling
- `StyleSheet.create({...})` defined once at module scope, not inline object literals re-created every render.
- No CSS cascade, no units (numbers are density-independent pixels), Flexbox only and `flexDirection` defaults to `column`.
- Compose with arrays for conditional styles: `style={[styles.base, isActive && styles.active]}`.
- No hardcoded colors/sizes — pull from a shared theme/token module, not literals scattered per file ([[fe-ui-foundations]]).

### Lists
- Long/unbounded data → `FlatList`/`SectionList`, never `.map()` inside a `ScrollView` (renders everything, leaks memory).
- `keyExtractor` returns a stable id — same rule as web `key`, no index.
- Give `FlatList` a `renderItem` that points to a memoized row component.

### Platform & layout
- Branch with `Platform.OS === 'ios'` / `Platform.select({ ios, android })`; split bigger divergences into `.ios.tsx` / `.android.tsx` files.
- Wrap screens in `SafeAreaView` (or insets) so content clears notches and system bars.
