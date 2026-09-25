# react-native-optimization

An agent skill that makes React Native and Expo apps faster **by measuring first**. You get a baseline, the actual cause, the smallest safe fix, and before/after numbers, instead of a pile of `useMemo`s.

It works with any agent that reads `SKILL.md` skills: **Claude Code, Codex, Gemini CLI, Cursor**, and others.

## What it does

- **Specific problems:** laggy input, janky scroll or animation, slow cold start, memory growth or crashes, APK/IPA/JS bundle size, CPU or battery drain. The agent picks one investigation lane, tells you what to measure and how, traces the cost back to source, and makes one change it can test.
- **General reviews** ("make it faster before launch"): the agent reads your project facts (React Native/Expo version, Hermes, New Architecture), scans the code for risk patterns, and lists them as *leads*. You then choose 1–3 user journeys, and it baselines them before touching any code.
- **Reports** in a fixed format: project facts, journeys and budgets, a measurement ledger, verified causes, changes with before/after numbers, and leads that weren't measured.

What it won't do: rewrite your navigation, switch state libraries, or make "best practice" edits across the codebase without evidence. When a measurement needs a real device, the agent gives you exact steps and waits for your numbers rather than making them up.

## Install

### macOS, Linux, WSL

```sh
curl -fsSL https://raw.githubusercontent.com/christywho/react-native-optimization/main/install.sh | sh
```

With no options, this installs into every agent host already on your machine. To choose:

```sh
# Claude Code only
curl -fsSL https://raw.githubusercontent.com/christywho/react-native-optimization/main/install.sh | sh -s -- --claude

# Codex, Gemini CLI, Cursor (they share ~/.agents/skills)
curl -fsSL https://raw.githubusercontent.com/christywho/react-native-optimization/main/install.sh | sh -s -- --agents

# Just this project (commit it so your team gets it too)
curl -fsSL https://raw.githubusercontent.com/christywho/react-native-optimization/main/install.sh | sh -s -- --all --project

# A specific version
curl -fsSL https://raw.githubusercontent.com/christywho/react-native-optimization/main/install.sh | sh -s -- --claude --version v1.0.0
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/christywho/react-native-optimization/main/install.ps1 | iex
```

With options:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/christywho/react-native-optimization/main/install.ps1))) -Claude -Version v1.0.0
```

### Where it goes

| Host | Global | Per project | Flag |
| --- | --- | --- | --- |
| Claude Code | `~/.claude/skills/` | `.claude/skills/` | `--claude` |
| Codex | `~/.agents/skills/` | `.agents/skills/` | `--agents` (or `--codex`) |
| Gemini CLI | `~/.agents/skills/` | `.agents/skills/` | `--agents` (or `--gemini`) |
| Cursor | `~/.agents/skills/` | `.agents/skills/` | `--agents` (or `--cursor`) |
| Anything else | your path | your path | `--dir <path>` |

### Options

| Option | Effect |
| --- | --- |
| `--all` | `--claude` and `--agents` |
| `--project` | Install into the current project, not your home folder |
| `--version <tag>` | Install a specific release (default: latest release) |
| `--uninstall` | Remove from the selected targets |
| `--dry-run` | Show what would happen without changing anything |

The installer only downloads **tagged releases**, never unreleased changes. It doesn't need `sudo` and only writes to the skills folders you pick. Re-running it upgrades in place. If you edited your installed copy, that copy is backed up to `~/.local/share/react-native-optimization/backups/` first (on Windows, `%LOCALAPPDATA%\react-native-optimization\backups`).

### Manual install

Download a release, then copy its `skill/` folder into your agent's skills folder as `react-native-optimization/`:

```sh
cp -R skill ~/.claude/skills/react-native-optimization
```

## Using it

Open your agent in your React Native project and describe the problem:

> typing in the search box is laggy on our cheap Android test phone

> our release APK grew from 38 MB to 61 MB, what's bloating it?

> can you do a performance review before the holiday sale? nothing specific is broken

Most agents pick the skill up automatically from requests like these. To call it explicitly, use `/react-native-optimization` in Claude Code or `$react-native-optimization` in Codex.

Expect questions about your target devices and build, and requests to run a release build and profiler. That's by design: the fix gets chosen from numbers, not guesses.

## Contents

```
skill/
  SKILL.md                              workflow, lanes, no-symptom mode
  references/measurement-and-triage.md  metrics, tools, the ledger
  references/remediation-catalog.md     evidence → fix options → guardrails
  references/static-scan.md             risk patterns for general reviews
  references/report-template.md         the outcome report format
  agents/openai.yaml                    Codex display metadata
```

## Development

```sh
sh tests/lint-skill.sh        # frontmatter and link checks
sh tests/install.test.sh      # installer tests (offline, throwaway HOME)
```

`tests/fixture-app/` is a small fake React Native app with known performance problems planted in it. It's used to check the skill's behaviour (see `tests/README.md`), and `evals/evals.json` holds the prompts and checks used for that.

## Credits

The approach is inspired by Callstack's [*The Ultimate Guide to React Native Optimization*](https://www.callstack.com/ebooks/the-ultimate-guide-to-react-native-optimization). This project is independent and not affiliated with or endorsed by Callstack.

## License

[MIT](LICENSE)
