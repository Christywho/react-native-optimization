# Report template

Use this structure for every outcome report, including inconclusive ones and scan-only runs. Omit a section only by writing "None" under it, so readers can tell nothing was skipped silently.

```markdown
# React Native performance report: <app or journey>

## Project facts
- React Native <x>, React <x>, Expo SDK <x or "not Expo">
- JS engine: <Hermes | JSC | unknown — why>
- New Architecture: <on | off | unknown — why>
- Lists / animation / state / navigation: <libraries>
- React Compiler: <on | off>
- Android release shrinking: <on | off | unknown>

## Scope
- Request: <user's words>
- Lane: <lane from the SKILL.md table, or "no-symptom">
- Platforms and devices: <e.g. Android Pixel 6a (release), iOS iPhone 12 (release)>
- Build: <exact command / variant>

## Journeys and budgets
| Journey | Script (fixed steps) | Metric | Budget | Source of budget |
| --- | --- | --- | --- | --- |

## Ledger
| Journey | Platform/device/build | Metric and baseline | Evidence | Hypothesis/change | Result | Decision |
| --- | --- | --- | --- | --- | --- | --- |

## Verified causes
- <cause> — evidence: <trace/profile/artifact reference>

## Changes
| Change | Files | Before | After | Neighboring risk checked |
| --- | --- | --- | --- | --- |

## Unmeasured leads
| File:line | Pattern | Lane | Why not measured |
| --- | --- | --- | --- |

## Measurement limits
- <what could not be measured, on which platform, and why>

## Next step
- <one recommended next measurement or change>
```

Guidance:

- Numbers in "Before"/"After" must come from the same journey script, build variant, and device. Write "not measured" rather than estimating.
- When measurements came from the user, say so ("reported by user from Flashlight run").
- For scan-only runs (no baseline yet), the Ledger and Changes sections are "None" and the Next step names the journeys to baseline.
