# Tests

## Automated

| Script | Checks |
| --- | --- |
| `lint-skill.sh` | `name` matches, `description` ≤ 1024 chars, every `references/` link exists and every reference is linked |
| `install.test.sh` | `install.sh` targets, aliases, `--project`, `--version`, upgrade/backup, `--uninstall`, `--dry-run`, error paths, all offline with a throwaway `HOME` |
| `install.Tests.ps1` | `install.ps1` core paths under Pester (Windows CI) |

## Skill behaviour (manual, per host)

`fixture-app/` is a fake React Native 0.78 app (Hermes and New Architecture on) with these problems planted in it:

| Planted issue | Where |
| --- | --- |
| 2,500 products rendered by `ScrollView` + `.map` | `src/screens/HomeScreen.tsx` |
| `_.find` inside the search filter (quadratic per keystroke) | `src/screens/HomeScreen.tsx` |
| `Dimensions` listener without cleanup | `src/screens/HomeScreen.tsx` |
| Cart context `value` rebuilt every render | `src/context/CartContext.tsx` |
| `console.log` in every card, no production strip | `src/components/ProductCard.tsx`, `babel.config.js` |
| Search index built at module scope before first render | `src/App.tsx` |
| ~700 KB JSON catalog bundled | `src/data/catalog.json` |
| `setState` on every scroll event (`scrollEventThrottle={1}`) | `src/screens/ProductScreen.tsx` |
| R8/ProGuard off; all four ABIs built | `android/app/build.gradle`, `android/gradle.properties` |
| moment + date-fns + whole lodash | `package.json` |

**Decoy:** `src/screens/OrdersScreen.tsx` cleans up its interval and uses FlashList with keys. A correct run doesn't flag it as a leak.

To check a host, install the skill, copy `fixture-app/` somewhere writable, open the agent there, and send each prompt from `../evals/evals.json`. A run passes when it meets that prompt's `assertions`. For the general review, it must also **not edit any files**.

| Host | Last checked | Result |
| --- | --- | --- |
| Claude Code | 2026-09-25 (v1.0.0) | all eval assertions pass (3 iterations) |
| Codex | — | not yet run |
| Gemini CLI | — | not yet run |
| Cursor | — | not yet run |
