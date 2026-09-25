# react-native-optimization: public packaging and no-symptom mode

Date: 2026-09-25
Status: approved; implemented with the changes listed below

## Goal

Publish the existing `react-native-optimization` skill (today at `~/.claude/skills/react-native-optimization`) as a public, versioned repo that other people install globally or per project, and then run inside their own React Native repos, from Claude Code, Codex, Gemini CLI, Cursor, or any agent that reads a skills folder.

Along the way, give the skill a path for its most common real-world invocation: "review my app's performance" with no specific complaint.

## Decisions (agreed)

| Topic | Decision |
| --- | --- |
| Hosts | Claude Code, Codex, Gemini CLI, Cursor/other (plain skills folder) |
| Distribution | Plain folder + install scripts (no plugin manifests or marketplace) |
| Hosting | Public GitHub repo `christywho/react-native-optimization` |
| License | MIT |
| Source credit | "Inspired by Callstack's *The Ultimate Guide to React Native Optimization*", with a link; explicitly not endorsed by Callstack; no guide wording copied |
| No-symptom behaviour | Static scan first, then a guided baseline of 1–3 user-chosen journeys; code changes only for measured misses and only with user approval |
| Versioning | SemVer git tags; installer fetches a tagged release, never `main` |
| Working copy | `~/react-native-optimization` (outside the frappe-bench repo). The existing installed copy is left untouched. |

## Non-goals

- Claude Code plugin/marketplace manifests, Gemini extension manifest (can be added later without moving the skill).
- Changing the measure-first rules, the lane table, or the remediation guardrails.
- Automated device profiling; the skill guides the human/agent through existing profilers.

## 1. Repo layout

```
react-native-optimization/
  skill/
    SKILL.md
    agents/openai.yaml
    references/
      measurement-and-triage.md
      remediation-catalog.md
      static-scan.md          # new
      report-template.md      # new
  install.sh                  # POSIX sh (macOS, Linux, WSL)
  install.ps1                 # Windows PowerShell
  tests/
    install.test.sh           # uses bats if present, else plain sh runner
    fixture-app/              # tiny fake RN project with seeded issues
    README.md                 # skill acceptance checklist
  .github/workflows/ci.yml
  docs/specs/                 # this file
  README.md  LICENSE  CHANGELOG.md  VERSION
```

`skill/` is the only copy of the skill. The installer copies it as a folder named `react-native-optimization`.

## 2. Installers

### install.sh

Invocation: `curl -fsSL https://raw.githubusercontent.com/christywho/react-native-optimization/main/install.sh | sh -s -- [flags]` or `./install.sh [flags]` from a clone.

| Flag | Effect |
| --- | --- |
| `--claude` | `~/.claude/skills/react-native-optimization` |
| `--codex` | Codex user skills directory |
| `--gemini` | Gemini CLI user skills directory |
| `--cursor` | `.cursor/skills/` in the current project (Cursor has no global skills folder we rely on) |
| `--dir <path>` | Any other agent's skills directory |
| `--all` | Every known target |
| (none) | Every known target whose host home directory already exists; if none exist, print usage and exit 1 |
| `--project` | Use the project-scoped equivalent of each target under the current directory (`./.claude/skills`, `./.codex/skills`, …) |
| `--version <tag>` | Release to install; default: latest release tag |
| `--uninstall` | Remove from the selected targets |
| `--dry-run` | Print actions, write nothing |
| `-h`, `--help` | Usage |

Codex and Gemini directory paths are verified against current docs during planning and recorded in the README; they are not assumed.

Behaviour:

- Source: when run from a clone, copy the local `skill/`, else download the release tarball for the resolved tag from GitHub and extract `skill/` to a temp dir (cleaned on exit).
- Writes `.version` (the tag) inside the installed folder.
- Upgrade: if the target exists and differs from the incoming copy (ignoring `.version`), move it to `react-native-optimization.bak-YYYYMMDDHHMMSS` before writing. Identical content is replaced silently.
- Never uses `sudo`; never writes outside the selected target directories and the temp dir.
- Exits non-zero on unknown flags, a failed download, or a missing tag; prints what was installed where.
- Requires only `sh`, `curl` or `wget`, `tar`, `mktemp`.

### install.ps1

Same flags as PowerShell parameters (`-Claude`, `-Codex`, `-Gemini`, `-Cursor`, `-Dir`, `-All`, `-Project`, `-Version`, `-Uninstall`, `-DryRun`), same behaviour, using `$HOME` and `Invoke-WebRequest`/`tar`.

## 3. Skill content changes

### 3.1 Frontmatter description

Remove "not for speculative cleanup without a measurable performance goal". Add that the skill also covers a general performance review, which scans for risks and then measures before changing code. The skill stays at or under 1024 characters.

### 3.2 Step 0: detect the project

Before any version-sensitive advice, record:

| Fact | Source |
| --- | --- |
| React Native, React, Expo SDK versions | `package.json`, lockfile |
| Hermes vs JSC; New Architecture on or off | `android/gradle.properties` (`hermesEnabled`, `newArchEnabled`), `ios/Podfile.properties.json`; for Expo, `app.json` / `app.config.*` |
| List, animation, state, navigation libraries | `package.json` dependencies |
| React Compiler | `babel.config.js` / Expo config |

Advice that depends on a version or engine must cite this record. If a fact cannot be determined, say so and do not assume a default.

### 3.3 New lane: no specific symptom

Added as a row in the lane table and a short section:

1. **Static scan** using `references/static-scan.md`. Output: a list of *leads*, each with file:line, the pattern, the lane it points to, and the journey it would affect. Leads are never presented as fixes.
2. **Choose journeys** with the user: offer 1–3 journeys ranked by user reach of the leads; always offer cold start.
3. **Guided baseline** for each chosen journey under the existing measurement rules, recorded in the ledger.
4. Only journeys that miss their budget enter the existing investigate → change → verify loop, and every code change needs user approval.

### 3.4 references/static-scan.md

A table of risk patterns: pattern, how to find it (search signal), why it may matter, which lane, false-positive notes. Initial set:

- `ScrollView` rendering `.map` over dynamic/long data
- `FlatList`/`FlashList` without stable `keyExtractor`/keys; FlashList without size hints where the installed version needs them
- Context provider `value` built inline (new object/array/function each render)
- Barrel or whole-library imports of known heavy packages
- `useEffect` adding listeners, subscriptions, intervals or timeouts without cleanup
- Heavy synchronous work at module scope or in the root component / app entry
- Large uncompressed image assets in the source tree
- Android release build without R8/resource shrinking
- Inline animated values driven by `setState` per frame
- `console.log` in hot paths without a production strip (Babel plugin or equivalent)

Each entry states that a match is a lead that needs measurement.

### 3.5 references/report-template.md

A fixed report shape: project facts (Step 0), journeys and budgets, ledger, confirmed causes, changes with before/after numbers, unmeasured leads, measurement limits. SKILL.md's "Report the outcome" section links to it.

### 3.6 Host neutrality

- SKILL.md keeps using no tool names that belong to one host.
- `agents/openai.yaml` gains a `default_prompt`.
- Existing reference files get only the credit/wording touch-ups needed for public release.

## 4. README

- What the skill does and when it triggers
- Install one-liners per host (global and `--project`), manual copy fallback, upgrade, uninstall
- Usage examples: a specific symptom ("typing in search lags on Android") and a general review
- Credit: inspired by Callstack's guide (link); not affiliated with or endorsed by Callstack
- License: MIT

## 5. Testing

### Installers

- `shellcheck install.sh`, which must be clean.
- `PSScriptAnalyzer` on `install.ps1` if `pwsh` is available; otherwise report that it was not run.
- `tests/install.test.sh`, each case with a throwaway `HOME` and working directory, using a local tarball in place of the GitHub download:
  - fresh install to each target and `--dir`
  - `--project` scope
  - no flags with only `~/.claude` present, which installs only there
  - reinstall with identical content, which leaves no backup
  - reinstall over an edited copy, which creates a `.bak-*` backup
  - `--uninstall`
  - `--dry-run`, which writes nothing
  - an unknown flag, which exits non-zero
  - `--version` choosing the tarball URL

### Skill behaviour

- `tests/fixture-app/` contains `package.json` (pinned RN/React versions), `android/gradle.properties`, `babel.config.js`, and a few `.tsx` files seeded with: ScrollView+map, an uncleaned listener, an inline context value, a barrel import.
- `tests/README.md` acceptance checklist for a no-symptom run in the fixture:
  - reports every seeded lead with the correct lane
  - reads versions and the Hermes/New Architecture flags correctly
  - proposes journeys, including cold start
  - modifies no files
- The Claude Code run is done and recorded by the implementer; the Codex and Gemini runs are listed as manual checks for the owner.

### CI

`.github/workflows/ci.yml` runs on ubuntu-latest and macos-latest: shellcheck, the install tests, and a frontmatter lint (`name` equals `react-native-optimization`, `description` ≤ 1024 characters).

## 6. Release

1. Commit history with no Claude/AI/Anthropic credit lines.
2. **Git target gate:** before `gh repo create christywho/react-native-optimization --public`, `git push`, or tagging, stop and show the active `gh` account (must be `christywho`), the SSH host/alias used for that account, the `origin` URL (must be SSH, not HTTPS), and visibility (public). Proceed only on explicit confirmation; any mismatch aborts.
3. Tag `v1.0.0`, create the GitHub release (tarball attached), and set `VERSION` and `CHANGELOG.md` to match.
4. Verify the README one-liner against the published release in a throwaway `HOME`.

## Changes made during implementation

- **Install targets.** Current docs show that Codex, Gemini CLI, and Cursor all read `~/.agents/skills` (project: `.agents/skills`), while Claude Code reads `~/.claude/skills`. So the installer has two real targets, `--claude` and `--agents`, and `--codex`, `--gemini`, `--cursor` are aliases for `--agents`. This replaces the per-host directories and the project-only Cursor target above. The old `~/.codex/skills` location triggers a warning, and the installer never touches it.
- **Backups.** Backups go to `${XDG_DATA_HOME:-~/.local/share}/react-native-optimization/backups/` (Windows: `%LOCALAPPDATA%`), not `react-native-optimization.bak-*` beside the skill, because agent hosts would load a backup in the skills folder as a second copy of the skill.
- **Fix-when-asked.** Round 1 of the evals showed the no-symptom caution spilling into explicit "fix it" requests. SKILL.md gained a "When you can't measure yet" section (narrow, clearly evidenced fix labelled unmeasured, with a before/after script) and a rule that the change summary must match the diff.
- **Test hooks.** `RNO_GITHUB`, `RNO_API`, `RNO_BACKUP_DIR`, and `RNO_HOME` (PowerShell only) env overrides exist so the installers can be tested offline.

## Open items resolved during planning

- Codex/Gemini/Cursor skills directories: resolved (see above).
- The SSH alias for the `christywho` account in `~/.ssh/config` (checked at the gate, not assumed).
