#!/bin/sh
# Offline tests for install.sh. Each case gets a throwaway HOME and working dir;
# GitHub downloads are served from file:// fixtures.
#   sh tests/install.test.sh
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
INSTALLER="$ROOT/install.sh"
SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT

PASS=0
FAIL=0
ok() {
	PASS=$((PASS + 1))
	printf 'ok   %s\n' "$1"
}
not_ok() {
	FAIL=$((FAIL + 1))
	printf 'FAIL %s\n' "$1"
	[ -n "${2:-}" ] && printf '     %s\n' "$2"
}
check() { # description command...
	d="$1"
	shift
	if "$@"; then ok "$d"; else not_ok "$d"; fi
}

# ---- fake GitHub ------------------------------------------------------------

GH="$SANDBOX/gh"
API="$SANDBOX/api"
make_release() { # tag
	stage="$SANDBOX/stage/react-native-optimization-${1#v}"
	mkdir -p "$stage" "$GH/christywho/react-native-optimization/archive/refs/tags"
	cp -R "$ROOT/skill" "$stage/skill"
	printf '%s\n' "$1" >"$stage/VERSION"
	tar -czf "$GH/christywho/react-native-optimization/archive/refs/tags/$1.tar.gz" -C "$SANDBOX/stage" "react-native-optimization-${1#v}"
	rm -rf "$SANDBOX/stage"
}
make_release v9.9.8
make_release v9.9.9
mkdir -p "$API/repos/christywho/react-native-optimization/releases"
printf '{\n  "url": "x",\n  "tag_name": "v9.9.9",\n  "name": "v9.9.9"\n}\n' >"$API/repos/christywho/react-native-optimization/releases/latest"

# ---- helpers ----------------------------------------------------------------

new_case() { # sets H (home) and P (project dir)
	CASE_DIR=$(mktemp -d "$SANDBOX/case.XXXX")
	H="$CASE_DIR/home"
	P="$CASE_DIR/project"
	mkdir -p "$H" "$P"
}

# Runs the installer as if piped from curl (no local clone detection).
remote() {
	(cd "$P" && HOME="$H" RNO_GITHUB="file://$GH" RNO_API="file://$API" XDG_DATA_HOME="$H/.local/share" \
		sh -s -- "$@" <"$INSTALLER") >"$CASE_DIR/out" 2>&1
}
# Runs the installer from the clone.
local_run() {
	(cd "$P" && HOME="$H" XDG_DATA_HOME="$H/.local/share" sh "$INSTALLER" "$@") >"$CASE_DIR/out" 2>&1
}

installed() { [ -f "$1/react-native-optimization/SKILL.md" ]; }
version_is() { [ "$(cat "$1/react-native-optimization/.version" 2>/dev/null)" = "$2" ]; }

# ---- cases ------------------------------------------------------------------

new_case
remote --claude
check "--claude installs latest release into ~/.claude/skills" installed "$H/.claude/skills"
check "  .version records the latest tag" version_is "$H/.claude/skills" v9.9.9
check "  references are copied" test -f "$H/.claude/skills/react-native-optimization/references/static-scan.md"
check "  ~/.agents/skills untouched" test ! -e "$H/.agents"

for alias in --agents --codex --gemini --cursor; do
	new_case
	remote "$alias"
	check "$alias installs into ~/.agents/skills" installed "$H/.agents/skills"
done

new_case
remote --all
check "--all installs into both homes" sh -c "[ -f '$H/.claude/skills/react-native-optimization/SKILL.md' ] && [ -f '$H/.agents/skills/react-native-optimization/SKILL.md' ]"

new_case
remote --dir "$CASE_DIR/custom skills"
check "--dir installs into a custom path with spaces" installed "$CASE_DIR/custom skills"

new_case
remote --claude --version v9.9.8
check "--version installs the requested tag" version_is "$H/.claude/skills" v9.9.8

new_case
mkdir -p "$H/.claude"
remote
check "no flags + only ~/.claude present installs only there" sh -c "[ -f '$H/.claude/skills/react-native-optimization/SKILL.md' ] && [ ! -e '$H/.agents/skills' ]"

new_case
mkdir -p "$H/.gemini"
remote
check "no flags + ~/.gemini present installs into ~/.agents/skills" installed "$H/.agents/skills"

new_case
remote
rc=$?
check "no flags + no host dirs exits non-zero" test "$rc" -ne 0

new_case
remote --all --project
check "--project installs into the project, not HOME" sh -c "[ -f '$P/.claude/skills/react-native-optimization/SKILL.md' ] && [ -f '$P/.agents/skills/react-native-optimization/SKILL.md' ] && [ ! -e '$H/.claude' ]"

new_case
remote --claude
remote --claude
check "reinstalling identical content makes no backup" test ! -e "$H/.local/share/react-native-optimization/backups"
check "  and the skill is still installed" installed "$H/.claude/skills"

new_case
remote --claude
echo "local tweak" >>"$H/.claude/skills/react-native-optimization/SKILL.md"
remote --claude
bak=$(find "$H/.local/share/react-native-optimization/backups" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -n 1)
check "reinstalling over an edited copy backs it up" sh -c "[ -n '$bak' ] && grep -q 'local tweak' '$bak/SKILL.md'"
check "  backup is outside the skills folder" sh -c "[ \$(ls '$H/.claude/skills' | wc -l) -eq 1 ]"
check "  fresh copy replaces the edited one" sh -c "! grep -q 'local tweak' '$H/.claude/skills/react-native-optimization/SKILL.md'"

new_case
remote --all
remote --all --uninstall
check "--uninstall removes from selected targets" sh -c "[ ! -e '$H/.claude/skills/react-native-optimization' ] && [ ! -e '$H/.agents/skills/react-native-optimization' ]"

new_case
mkdir -p "$H/.claude/skills/react-native-optimization"
echo "someone else's skill" >"$H/.claude/skills/react-native-optimization/SKILL.md"
remote --claude --uninstall
check "--uninstall leaves a foreign folder of the same name alone" test -f "$H/.claude/skills/react-native-optimization/SKILL.md"

new_case
remote --all --dry-run
check "--dry-run writes nothing" sh -c "[ ! -e '$H/.claude' ] && [ ! -e '$H/.agents' ]"
check "  and says what it would do" grep -q "would run: cp" "$CASE_DIR/out"

new_case
remote --bogus
rc=$?
check "unknown flag exits non-zero" test "$rc" -ne 0
check "  and names the flag" grep -q "unknown option: --bogus" "$CASE_DIR/out"

new_case
remote --claude --version v0.0.0
rc=$?
check "missing tag exits non-zero" test "$rc" -ne 0
check "  and installs nothing" test ! -e "$H/.claude/skills/react-native-optimization"

new_case
local_run --claude
check "running from a clone installs the clone's files" sh -c "cmp -s '$ROOT/skill/SKILL.md' '$H/.claude/skills/react-native-optimization/SKILL.md'"
check "  .version comes from VERSION" version_is "$H/.claude/skills" "$(cat "$ROOT/VERSION")"

new_case
mkdir -p "$H/.codex/skills/react-native-optimization"
remote --codex
check "legacy ~/.codex/skills copy triggers a warning" grep -q "older copy exists in ~/.codex/skills" "$CASE_DIR/out"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
