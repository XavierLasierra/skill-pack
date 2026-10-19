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

### New Architecture
- Fabric + TurboModules are the default since RN 0.76 (Expo SDK 52+). Before adding a native-module library, check it supports the New Architecture (react-native-directory flags it); prefer maintained alternatives over abandoned ones.
- Don't write new code against the legacy bridge (`NativeModules`, old `requireNativeComponent` patterns).

### Styling
- `StyleSheet.create({...})` defined once at module scope. It buys organization and type-checking, not a meaningful perf win — still avoid giant inline literals in hot list rows.
- No CSS cascade, no units (numbers are density-independent pixels), Flexbox only and `flexDirection` defaults to `column`.
- Compose with arrays for conditional styles: `style={[styles.base, isActive && styles.active]}`.
- No hardcoded colors/sizes — pull from a shared theme/token module, not literals scattered per file ([[fe-ui-foundations]]).
- Read screen size with the `useWindowDimensions` hook (reactive to rotation/split-screen), not `Dimensions.get`.

### Lists
- Long/unbounded data → `FlatList`/`SectionList`, never `.map()` inside a `ScrollView` (renders everything, leaks memory).
- `FlatList` is the baseline. For long or heterogeneous lists, use `FlashList` (`@shopify/flash-list`) — cell recycling, much less blank-scroll. Give it `estimatedItemSize` where required by your version, and `getItemType` for mixed rows.
- `keyExtractor` returns a stable id — same rule as web `key`, no index.
- `renderItem` points to a memoized row component; keep rows cheap and images sized.

### Images, animation, navigation
- Images: `expo-image` for disk/memory caching, placeholders (blurhash), and transitions; always set explicit `width`/`height`.
- Animation: Reanimated for UI-thread animations and gestures (with `react-native-gesture-handler`). Core `Animated` with `useNativeDriver` is fine for trivial fades. Never animate by `setState` per frame.
- Navigation: Expo Router (file-based, on React Navigation) for Expo apps, React Navigation otherwise. Don't hand-roll screen stacks.

### Platform & layout
- Branch with `Platform.OS === 'ios'` / `Platform.select({ ios, android })`; split bigger divergences into `.ios.tsx` / `.android.tsx` files.
- Core `SafeAreaView` is deprecated. Use `react-native-safe-area-context`: one `SafeAreaProvider` at the root, then its `SafeAreaView` or `useSafeAreaInsets()` per screen so content clears notches and system bars.

```tsx
const insets = useSafeAreaInsets();
<View style={{ paddingTop: insets.top, paddingBottom: insets.bottom }}>
```

### Accessibility
- Roles, labels, and state props live in [[fe-a11y]] (prefer `role` / `aria-*` props).
