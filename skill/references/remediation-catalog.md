# Remediation catalog

Choose an option only after evidence points to the relevant cost. Re-profile after every change.

## Render scope and JavaScript work

| Evidence | Consider | Guardrail |
| --- | --- | --- |
| A state update re-renders unrelated expensive children | Move state closer to consumers, use focused/atomic subscriptions, or memoize a demonstrated expensive boundary | Do not add `memo`, `useMemo`, or `useCallback` everywhere; shallow-reference churn can erase the benefit and obscure code. |
| A component’s own computation dominates a commit | Cache or defer the expensive derived work, or reduce its input/work | Confirm the cache is invalidated correctly and does not retain a large data graph. |
| Input is fast but derived results block it | Keep the urgent input update immediate; use `useDeferredValue` for a costly dependent value or a transition for a broader non-urgent update | Preserve an honest pending/stale state so the UI does not imply results are current. |
| Very large or variable-height list cost | Virtualize and tune the existing list implementation; render only the visible window | Verify scroll position, accessibility, empty/loading states, item keys, and data refresh behavior. |
| React Compiler is present or proposed | Check React rules/compiler diagnostics and enable or expand it incrementally | Do not assume it optimizes class components or code that violates React’s rules. Validate its effect with the profiler before deleting manual safeguards. |

## Animation, view hierarchy, and native work

| Evidence | Consider | Guardrail |
| --- | --- | --- |
| JS thread misses frames during a high-frequency visual update | Keep per-frame visual work off React’s render loop when the installed animation/gesture stack supports it | Do not introduce a new animation framework solely on folklore; retain gesture interruption and accessibility behavior. |
| UI/main thread or mount/layout dominates | Reduce unnecessary mounted views, avoid needless layout changes, and inspect view flattening eligibility | Do not flatten or remove a wrapper that carries visual, event, accessibility, clipping, or test behavior. |
| A native module or SDK is a hotspot | Profile its platform implementation and use a mobile-native integration where that is the measured better fit | Account for platform differences, native binary size, and release configuration. A web SDK is not automatically wrong. |
| Startup trace pinpoints blocking initialization | Delay non-critical work until after meaningful interactivity or remove redundant initialization | Never defer authentication, security, navigation, or data needed for an honest interactive first screen without product approval. |

## Memory

- Remove listeners, subscriptions, timers, observers, and native callbacks when their owning screen or feature ends.
- Avoid closures that unintentionally retain large objects; capture the smallest needed value or establish a shorter lifetime.
- For native code, inspect the platform’s ownership model: retain cycles and strong references on iOS, long-lived contexts/listeners on Android, and shared C++/native objects can survive independently of JavaScript GC.
- Prove that retained allocations disappear after the owner is gone. Do not force garbage collection or rely on a snapshot alone as proof of a fix.

## Bundle, binary, and asset size

| Evidence | Consider | Guardrail |
| --- | --- | --- |
| A JS module or dependency dominates the production bundle | Replace/remove it, import the needed submodule directly, or eliminate a demonstrated barrel-import path | Check behavior and the final bundle. Package-size websites measure JavaScript only and cannot establish native binary cost. |
| Unused exports are retained | Use the project’s supported tree-shaking path and direct `Platform` imports where the setup supports platform elimination | Tree shaking and platform-shaking are build-configuration sensitive. Treat them as experiments and compare release outputs. |
| Android release code/resources dominate | Enable and validate the project’s R8/resource shrinking release path | Exercise the complete release build; reflection- or name-sensitive libraries may require narrowly justified keep rules. |
| Assets dominate an app artifact | Compress assets and provide density variants; evaluate native asset catalogs where the platform/build setup supports them | Verify visual quality and actual store/device artifact sizes, not only source asset bytes. |
| Initial loading is constrained after simpler options are exhausted | Evaluate remote loading or code splitting only with engine, offline, cache, and operational requirements in view | Hermes often gains little from code splitting due to memory mapping. Do not choose Module Federation merely to reduce bundle size. |
