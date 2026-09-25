---
name: react-native-optimization
description: Diagnose and improve a React Native or Expo app's responsiveness, startup time, memory use, battery cost, or release size — measure first, then make the smallest safe fix. Use for jank, dropped frames, slow lists, laggy input, excess re-renders, slow Time to Interactive or cold start, memory-pressure crashes, and Android/iOS/JavaScript bundle-size regressions. Also use when someone asks for a general React Native performance review, audit, or "why does my app feel slow" with no specific symptom — the skill scans for risks, has the user pick journeys, and baselines them before changing any code.
---

# React Native Optimization

Use this skill to make a **measured, targeted** improvement to a React Native mobile app: profile first, locate the responsible execution domain, make the smallest safe change, then prove the result in a production-like build. The approach is inspired by Callstack's *The Ultimate Guide to React Native Optimization*; this skill is independent and not endorsed by Callstack.

## Operating rules

- Do not optimize from code inspection alone. Establish a reproducible user journey and a baseline before editing, unless measurement is genuinely unavailable; in that case, state the assumption and limit the change to a clearly evidenced defect. Code inspection is still useful for *finding* where to measure — see the no-symptom lane below.
- Match the measurement to the user-visible problem. A smooth UI-thread FPS with low JS FPS, for example, is a different problem from a main-thread hang; package size in `node_modules` is not the installed app size.
- Measure release or production-like builds with development instrumentation disabled. Keep device, build variant, app state, network fixture, and interaction sequence comparable. Repeat noisy measurements and compare a representative result, not the best run.
- Prefer a narrowly scoped fix to a framework, state-management, navigation, or bundler migration. Treat migrations, remote code loading, and microfrontend architecture as last-resort options that need evidence beyond a single metric.
- Preserve behavior, accessibility, error handling, offline behavior, and platform parity. Do not trade a visible regression for a prettier benchmark.
- The New Architecture is current React Native's baseline; do not diagnose present code in terms of the legacy bridge unless the project facts (Step 0) prove it relevant.
- Use whichever repository, device, profiler, and task-tracking tools the host exposes. Do not assume a tool that only one agent host provides.
- You usually cannot drive a physical device or profiler yourself. Never invent a measurement; when one needs a human, give them the exact build command, journey script, and the number to report back. What you do while waiting depends on what they asked for — see "When you can't measure yet" below.
- Describe your own changes exactly. Before reporting, re-read your diff and make sure every claim ("removed X", "memoized Y") is true of it; an inaccurate change summary costs more trust than a missing optimization.

## Step 0: Record the project facts

Version-sensitive advice given blind is wrong more often than right, so read these before recommending anything, and cite them when advice depends on them:

| Fact | Where to look |
| --- | --- |
| React Native, React, Expo SDK versions | `package.json`, then the lockfile for the resolved version |
| Hermes vs JSC | `android/gradle.properties` (`hermesEnabled`), `ios/Podfile.properties.json` (`expo.jsEngine`), `app.json` / `app.config.*` (`jsEngine`); Hermes is the default on current versions |
| New Architecture on/off | `android/gradle.properties` (`newArchEnabled`), `ios/Podfile.properties.json` (`newArchEnabled`), `app.json` (`newArchEnabled`); RN ≥ 0.76 and Expo SDK ≥ 52 default to on |
| Lists, animation, state, navigation | `package.json` dependencies (FlatList vs FlashList/Legend List, Reanimated, Gesture Handler, Redux/Zustand/Jotai/MobX, React Navigation/Expo Router) |
| React Compiler | `babel.config.js` (`babel-plugin-react-compiler`), `app.json` `experiments.reactCompiler` |
| Release shrinking | `android/app/build.gradle` (`minifyEnabled`, `shrinkResources`, `enableProguardInReleaseBuilds`) |

If a fact cannot be determined (e.g., an Expo managed app with no native folders), say so and do not assume a default.

## Start with a performance brief

Inspect the workspace before asking for information already recorded there. Capture or confirm only what is needed to make the next decision:

1. The affected journey and user-facing failure: e.g., typing in search, opening the first usable screen, scrolling a feed, returning from background, or downloading the release. **If there is no specific complaint, use the no-symptom lane below.**
2. The target platform(s), device class, build type, refresh-rate target, and app state. Startup work must distinguish cold start from warm, hot, and OS-prewarmed launches.
3. A success threshold and a fixed reproduction sequence. When no threshold exists, propose one based on the team's existing regression budget rather than inventing a universal number.
4. A baseline report: JS and UI FPS or frame time, commit/CPU trace, TTI markers, retained-memory growth, or release-artifact size, as appropriate.

Use [measurement and triage](references/measurement-and-triage.md) for the metric definitions, tool choices, and a result ledger.

## Choose one investigation lane

| Symptom | Establish first | Likely focus |
| --- | --- | --- |
| Input delay, slow state changes, extra commits, sluggish lists | React Profiler and JavaScript CPU profile | render scope, expensive JS, list virtualization, state subscriptions |
| Animation or gesture jank | Separate JS and UI/main-thread frame behavior | thread ownership, layout/mount work, high-frequency React updates |
| Slow first useful screen | cold-start TTI timeline with meaningful interactivity marker | native initialization, bundle load, root render, blocking app work |
| Steadily rising memory, memory-pressure termination | repeatable navigation/use cycle and heap/native allocation evidence | retained JS references, subscriptions/timers, image/native ownership, cycles |
| Large download or installed app | release JS bundle *and* AAB/APK/IPA breakdown | dependencies, imports, native binaries (run the *Release size* checks in [the static scan](references/static-scan.md), especially unused native dependencies), assets, release shrink settings |
| CPU, battery, or a native-side hang | platform trace correlated with the journey | UI/main thread, native module work, view hierarchy, network/disk churn |
| **No specific symptom** ("review performance", "audit", "feels slow") | static scan → user-chosen journeys → baseline | whichever lane the measured journeys point to |

Do not bundle unrelated lanes into one "performance pass." Address the lane that dominates the reported user problem, record adjacent findings, and leave them for a later, separately measured change.

## No-symptom lane: scan, choose, measure

A general review is the most common request and the easiest to get wrong: a batch of "best practice" edits applied from reading code looks productive but usually changes nothing a user can feel, and sometimes makes things worse. The scan exists to decide *where to measure*, not what to change.

1. **Scan.** Work through [the static scan](references/static-scan.md) against the app's source. Each hit is a **lead**: record file:line, the pattern, the lane it points to, and which user journey it would affect. Do not edit code during the scan.
2. **Choose journeys with the user.** Group leads by journey and propose 1–3 journeys to measure, ranked by how many users touch them and how many leads converge there. Always offer cold start. Let the user pick; they know which screens matter.
3. **Baseline.** Measure each chosen journey under the rules in [measurement and triage](references/measurement-and-triage.md) and record it in the ledger. When the user must run the device or profiler, give them the exact steps and wait for their numbers.
4. **Only then investigate.** A journey that meets its budget is done — report its leads as unmeasured risks, not defects. A journey that misses its budget enters the loop below. Propose each code change and get the user's agreement before making it.

## When you can't measure yet

Measuring first protects users from speculative churn; it is not a reason to hand back nothing when someone asked for a fix. Decide by what the user asked for and how strong the code evidence is:

- **They asked for a fix, and the code shows a cost that clearly lies on the reported journey** (e.g., a per-keystroke quadratic lookup, thousands of rows rendered un-virtualized on the screen they named): make the smallest change that removes that cost, keep behavior identical, and label it plainly as *unmeasured*. Give one fixed measurement script they can run on the commit before and after your change, and say what result would mean it worked or didn't. Leave everything else as listed leads.
- **They asked for a fix, but the evidence is ambiguous** (several plausible causes, or the cost may lie off the journey): don't guess. Explain the candidates, give the measurement that would decide between them, and ask.
- **They asked for a review or diagnosis, not a fix**: change nothing; report leads and the measurement plan.

Keep the change scoped to the reported journey. "While I'm here" fixes elsewhere make the before/after impossible to attribute and hide which change broke something; list them as leads instead.

## Investigate, change, verify

1. Reproduce the journey in a production-like build. For a 60 Hz target, a frame has about 16.7 ms; for 120 Hz, about 8.3 ms. Use those as diagnostic budgets, not as an excuse to optimize work that is not on a critical frame.
2. Attribute the cost with the relevant profiler. Follow the expensive commit, call stack, allocation path, or artifact contributor to source. For React, enable render-reason information and inspect both flame and ranked views before adding memoization.
3. Form one falsifiable hypothesis: "this subscription redraws all visible rows," not "the screen needs optimization." Make the smallest change that tests it.
4. Re-run exactly the baseline sequence and compare the same metric. Also check the neighboring risk: a rendering fix may increase memory, a startup change may defer necessary content, and a shrinker change may break release-only code.
5. Keep the change only when the intended metric improves without an unacceptable regression. Otherwise explain the result, revert the speculative change, and move to the next evidenced cause.

When changing code, use [the remediation catalog](references/remediation-catalog.md) for evidence-first options and their guardrails. It is a chooser, not a checklist of mandatory refactors.

## Report the outcome

Use [the report template](references/report-template.md) so results are comparable across runs and teams. It covers project facts, journeys and budgets, the ledger, verified causes, changes with before/after numbers, unmeasured leads, and measurement limits. Include every affected platform. If the result is inconclusive, say so plainly and recommend the next measurement rather than presenting an unverified optimization as complete.
