# Measurement and triage

## Stable measurement conditions

Use the same release or production-like build, device/emulator profile, app data, network fixture, and interaction script for before-and-after runs. Disable development-only behavior while measuring. Prefer a representative lower-end real device for Android coverage when available; do not generalize from one simulator or flagship device.

Keep this compact ledger in the task notes or handoff:

| Journey | Platform/device/build | Metric and baseline | Evidence | Hypothesis/change | Result | Decision |
| --- | --- | --- | --- | --- | --- | --- |

The ledger matters more than a tool screenshot: it lets a later engineer reproduce the claim and prevents unrelated changes from being credited with an improvement.

## Rendering, JavaScript, and animation

- Use React Native DevTools’ React Profiler for excessive commits and expensive components. Turn on render-reason recording; inspect the flame graph for scope and the ranked view for cost.
- Use the JavaScript profiler for long tasks and hot call stacks. A busy JS thread can leave native controls visually responsive while delaying the application’s response, so correlate the trace with the interaction.
- Use React Native’s performance monitor for a quick split between JS and UI/main-thread FPS. Use an Android reporting tool such as Flashlight when available to save comparable interaction reports; do not make that tool a requirement.
- For a janky animation or gesture, determine which thread is missing its budget before changing animation code. A JS-derived value updated every frame through React is a different failure from expensive layout or mounting on the UI thread.

## Native CPU, memory, and hangs

- On iOS, use Xcode Instruments—Time Profiler and Hangs for execution, allocation/leak instruments for memory—and correlate the UI and JavaScript threads.
- On Android, use Android Studio Profiler for CPU, memory, network, and battery. Export a trace to Perfetto when the timeline or thread relationship needs deeper inspection.
- Profile the actual platform that exhibits the regression. Android hardware varies widely; an iOS-only trace does not clear Android, and vice versa.
- Test memory with a repeated, realistic use cycle: open the feature, interact, leave it, and repeat. A transient allocation spike is not a leak; retained growth after the feature should be collectible is the signal to investigate.

## Time to Interactive

Measure cold launches only. Warm, hot, and operating-system-prewarmed launches belong in separate metrics because mixing them makes a startup regression unreadable.

Instrument a timeline that can isolate at least these boundaries:

1. Native process initialization.
2. Native application initialization.
3. JavaScript bundle load.
4. React Native root content appearing.
5. The initial screen becoming meaningfully interactive.

The final marker is app-specific. Put it where a person can actually use the initial content—not merely where a root component mounted or a placeholder appeared. Filter prewarm/background cases explicitly and compare the same launch classification before and after a change.

## Release-size evidence

- Analyze a production JavaScript bundle with source maps or the app stack’s equivalent visualizer. Attribute JavaScript modules, not package-directory sizes.
- Analyze the final Android AAB/APK and iOS IPA/thinning report separately. A React Native dependency can look small in JavaScript yet add a large native binary, resource set, or architecture slice.
- Keep download and installed-size metrics distinct. Use device-specific artifacts when the distribution system produces them.
- Record the build flags used for the comparison; debug bundles and ad-hoc archives are not release-size baselines.
