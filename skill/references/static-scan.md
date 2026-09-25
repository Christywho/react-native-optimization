# Static scan

Use this in the no-symptom lane to decide **where to measure**. Every match is a *lead*, not a defect: many of these patterns are harmless on a short list, a rarely visited screen, or a small data set. Record each lead and let measurement decide.

Scan the app's own source (skip `node_modules`, build output, and generated native code). The search signals are starting points for grep or code search; read the surrounding code before recording a lead.

## Lead record

| # | File:line | Pattern | Lane | Journey affected | Notes |
| --- | --- | --- | --- | --- | --- |

## Rendering and lists

| Pattern | Search signal | Why it may matter | Lane | False positives |
| --- | --- | --- | --- | --- |
| `ScrollView` rendering a mapped collection | `<ScrollView` near `.map(` | Renders every item up front: slow first render, high memory on long or growing data | Input/lists | Short fixed lists (settings menus, < ~20 items) |
| List without stable keys | `FlatList`/`FlashList`/`SectionList` with no `keyExtractor` and items lacking `id`/`key`; `key={index}` | Rows remount or show stale state on insert/reorder | Input/lists | Static, never-reordered data |
| FlashList without size hints where the installed major version needs them | `FlashList` without `estimatedItemSize` (check FlashList version in Step 0; v2 removed the need) | Poor recycling and blank cells during fast scroll | Input/lists | FlashList v2+ |
| Heavy inline `renderItem` | `renderItem={({ item }) =>` with large JSX, inline formatting, or per-row data transforms | Recreated every parent render; row cost multiplies by visible count | Input/lists | Light rows |
| Context value rebuilt every render | `<*.Provider value={{` or `value={[` or a `value` from an un-memoized object in a component that re-renders often | Every consumer re-renders on any parent render | Input/lists | Providers at the root that rarely re-render |
| Broad store subscriptions | `useSelector(state => state)`, `useStore()` with no selector, selectors returning new objects/arrays | Components re-render on unrelated state changes | Input/lists | Stores that change rarely |
| Per-frame state updates for visuals | `setState`/`useState` setter inside `onScroll`, `PanResponder` move, `requestAnimationFrame`, or `Animated` listeners | Drives React renders at frame rate; JS-thread jank | Animation | Throttled handlers doing trivial work |
| `console.*` in hot paths without a production strip | `console.log` in render, list rows, scroll/gesture handlers; no `transform-remove-console` (or equivalent) in `babel.config.js` | Serialization cost in release builds | Input/lists | Strip plugin present |

## Startup

| Pattern | Search signal | Why it may matter | Lane | False positives |
| --- | --- | --- | --- | --- |
| Heavy synchronous work at module scope or in the root component | Top-level `JSON.parse` of large data, big `require`s, storage reads, SDK `init` calls in `index.js`/`App.tsx`/root layout | Blocks bundle evaluation or first render | Slow first screen | Work that the first screen truly needs |
| Eager loading of rarely used screens or SDKs | Root imports of analytics, maps, charts, PDF, video, or rich editors that the first screen does not use | Adds to evaluation and init time | Slow first screen | Libraries already lazily initialized |
| Awaiting non-critical work before hiding the splash | `SplashScreen.hideAsync`/`hide` placed after network calls, remote config, or analytics init | TTI waits on work users do not need yet | Slow first screen | Auth/session checks the first screen depends on |

## Memory

| Pattern | Search signal | Why it may matter | Lane | False positives |
| --- | --- | --- | --- | --- |
| Subscriptions without cleanup | `useEffect` containing `addEventListener`, `addListener`, `subscribe`, `setInterval`, `setTimeout`, `AppState`, `Keyboard`, `Dimensions`, `NetInfo`, `on(` with no returned cleanup function | Leaks listeners and retains screen state after unmount | Memory | Effects that return a cleanup |
| Module-level caches that only grow | Top-level `Map`/`Set`/object/array written to from screens and never pruned | Unbounded retained memory over a session | Memory | Bounded or LRU caches |
| Large images rendered small | Full-resolution remote/local images in thumbnails or list rows without resizing or a caching image component | Decoded bitmap memory far above displayed size | Memory | Images already sized by CDN params |

## Release size

| Pattern | Search signal | Why it may matter | Lane | False positives |
| --- | --- | --- | --- | --- |
| Whole-library or barrel imports of heavy packages | `import _ from 'lodash'`, `import * as` from icon/date/util libraries, app-internal `index.ts` barrels re-exporting large modules | Pulls unused modules into the bundle | Release size | Libraries with working per-module resolution in the project's bundler |
| Duplicate libraries for the same job | Two date libraries, two HTTP clients, two icon sets in `package.json` | Bundle and binary weight | Release size | Transitional migrations with a removal plan |
| Large uncompressed assets | Files > ~200 KB under `assets/`, `src/**/images` (PNG/JPG/GIF/MP4/Lottie JSON) | Download and installed size | Release size | Assets downloaded on demand |
| Android release shrinking off | `android/app/build.gradle`: `minifyEnabled false` / `enableProguardInReleaseBuilds = false`, no `shrinkResources true` | Larger APK/AAB | Release size | Expo managed projects where build properties configure this elsewhere — check `expo-build-properties` |
| Unused native dependencies | For each dependency with native code (has `android/` or `ios/` in `node_modules/<pkg>`, or is a known native library), grep `src/` and the entry file for imports. A reference only in `babel.config.js`, `app.json` plugins, or `metro.config.js` is **not** use: the native library is still autolinked into every ABI while no code calls it | Native `.so`/framework weight in every ABI, plus startup init from autolinking | Release size / startup | Peer dependencies of something you *do* import (e.g. `react-native-screens` and `react-native-safe-area-context` for React Navigation) are in use even with no direct import: check the importing library's `peerDependencies` before calling a package unused. Packages used only via Expo config plugins |

## After the scan

Group leads by journey, then offer the user 1–3 journeys to baseline (always including cold start). Do not edit code because of a lead alone.
