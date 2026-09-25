#!/bin/sh
# Install the react-native-optimization agent skill.
# https://github.com/christywho/react-native-optimization
#
#   curl -fsSL https://raw.githubusercontent.com/christywho/react-native-optimization/main/install.sh | sh
#   curl -fsSL .../install.sh | sh -s -- --claude --version v1.0.0
#   ./install.sh --all            (from a clone)
#
# Run with --help for all options.

set -eu

REPO="christywho/react-native-optimization"
SKILL_NAME="react-native-optimization"

# Overridable for testing and mirrors.
RNO_GITHUB="${RNO_GITHUB:-https://github.com}"
RNO_API="${RNO_API:-https://api.github.com}"
RNO_BACKUP_DIR="${RNO_BACKUP_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/$SKILL_NAME/backups}"

usage() {
	cat <<'EOF'
Usage: install.sh [targets] [options]

Targets (default: every host whose home folder already exists):
  --claude          Claude Code          ~/.claude/skills
  --agents          Codex, Gemini CLI,   ~/.agents/skills
                    Cursor, and other agents that read .agents/skills
  --codex           alias for --agents
  --gemini          alias for --agents
  --cursor          alias for --agents
  --dir <path>      any other skills folder (repeatable)
  --all             --claude and --agents

Options:
  --project         install into the current project (./.claude/skills,
                    ./.agents/skills) instead of your home folder
  --version <tag>   release to install, e.g. v1.0.0 (default: latest release;
                    from a clone without --version: the clone's files)
  --uninstall       remove the skill from the selected targets
  --dry-run         print what would happen, change nothing
  -h, --help        show this help
EOF
}

say() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() {
	printf 'error: %s\n' "$*" >&2
	exit 1
}

DRY_RUN=0
run() {
	if [ "$DRY_RUN" -eq 1 ]; then
		say "would run: $*"
	else
		"$@"
	fi
}

# ---- arguments --------------------------------------------------------------

WANT_CLAUDE=0
WANT_AGENTS=0
EXTRA_DIRS=""
PROJECT=0
VERSION=""
UNINSTALL=0

while [ $# -gt 0 ]; do
	case "$1" in
	--claude) WANT_CLAUDE=1 ;;
	--agents | --codex | --gemini | --cursor) WANT_AGENTS=1 ;;
	--all)
		WANT_CLAUDE=1
		WANT_AGENTS=1
		;;
	--dir)
		[ $# -ge 2 ] || die "--dir needs a path"
		EXTRA_DIRS="$EXTRA_DIRS
$2"
		shift
		;;
	--project) PROJECT=1 ;;
	--version)
		[ $# -ge 2 ] || die "--version needs a tag, e.g. v1.0.0"
		VERSION="$2"
		shift
		;;
	--uninstall) UNINSTALL=1 ;;
	--dry-run) DRY_RUN=1 ;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		usage >&2
		die "unknown option: $1"
		;;
	esac
	shift
done

# ---- targets ----------------------------------------------------------------

if [ "$PROJECT" -eq 1 ]; then BASE="$PWD"; else BASE="$HOME"; fi

if [ "$WANT_CLAUDE" -eq 0 ] && [ "$WANT_AGENTS" -eq 0 ] && [ -z "$EXTRA_DIRS" ]; then
	[ -d "$HOME/.claude" ] && WANT_CLAUDE=1
	for d in .agents .codex .gemini .cursor; do
		[ -d "$HOME/$d" ] && WANT_AGENTS=1
	done
	if [ "$WANT_CLAUDE" -eq 0 ] && [ "$WANT_AGENTS" -eq 0 ]; then
		usage >&2
		die "no agent host found in $HOME; pick a target such as --claude or --agents"
	fi
fi

TARGETS=""
[ "$WANT_CLAUDE" -eq 1 ] && TARGETS="$BASE/.claude/skills"
[ "$WANT_AGENTS" -eq 1 ] && TARGETS="$TARGETS
$BASE/.agents/skills"
TARGETS="$TARGETS$EXTRA_DIRS"

# ---- uninstall --------------------------------------------------------------

is_our_skill() {
	[ -f "$1/SKILL.md" ] && grep -q "^name: $SKILL_NAME\$" "$1/SKILL.md"
}

if [ "$UNINSTALL" -eq 1 ]; then
	echo "$TARGETS" | while IFS= read -r t; do
		[ -n "$t" ] || continue
		dest="$t/$SKILL_NAME"
		if is_our_skill "$dest"; then
			run rm -rf "$dest"
			say "removed $dest"
		elif [ -e "$dest" ]; then
			warn "$dest is not this skill; left in place"
		else
			say "not installed in $t"
		fi
	done
	exit 0
fi

# ---- source -----------------------------------------------------------------

TMP=""
cleanup() { [ -n "$TMP" ] && rm -rf "$TMP"; }
trap cleanup EXIT INT TERM

fetch() { # url -> stdout
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL "$1"
	elif command -v wget >/dev/null 2>&1; then
		wget -qO- "$1"
	else
		die "need curl or wget to download"
	fi
}

SCRIPT_DIR=""
case "$0" in
*/install.sh | install.sh) SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd) ;;
esac

if [ -z "$VERSION" ] && [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/skill/SKILL.md" ]; then
	SRC="$SCRIPT_DIR/skill"
	VERSION="$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo local)"
	say "installing $SKILL_NAME $VERSION from $SCRIPT_DIR"
else
	if [ -z "$VERSION" ]; then
		VERSION=$(fetch "$RNO_API/repos/$REPO/releases/latest" |
			sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1) ||
			die "could not look up the latest release of $REPO"
		[ -n "$VERSION" ] || die "no published release found for $REPO"
	fi
	TMP=$(mktemp -d)
	url="$RNO_GITHUB/$REPO/archive/refs/tags/$VERSION.tar.gz"
	say "downloading $SKILL_NAME $VERSION"
	fetch "$url" >"$TMP/src.tar.gz" || die "download failed: $url (does tag $VERSION exist?)"
	tar -xzf "$TMP/src.tar.gz" -C "$TMP" || die "could not unpack $url"
	SRC=$(find "$TMP" -mindepth 2 -maxdepth 2 -type d -name skill | head -n 1)
	if [ -z "$SRC" ] || [ ! -f "$SRC/SKILL.md" ]; then
		die "release $VERSION has no skill/ folder"
	fi
fi

# ---- install ----------------------------------------------------------------

STAMP=$(date +%Y%m%d%H%M%S)

same_content() { # installed incoming
	diff -r -x .version "$1" "$2" >/dev/null 2>&1
}

echo "$TARGETS" | while IFS= read -r t; do
	[ -n "$t" ] || continue
	dest="$t/$SKILL_NAME"
	if [ -e "$dest" ]; then
		if same_content "$dest" "$SRC"; then
			run rm -rf "$dest"
		else
			# Backups live outside the skills folder so hosts don't load them as a second copy.
			bak="$RNO_BACKUP_DIR/$SKILL_NAME-$STAMP-$(printf '%s' "$t" | tr '/ ' '__')"
			run mkdir -p "$RNO_BACKUP_DIR"
			run mv "$dest" "$bak"
			say "existing copy differed; backed up to $bak"
		fi
	fi
	run mkdir -p "$t"
	run cp -R "$SRC" "$dest"
	if [ "$DRY_RUN" -eq 1 ]; then
		say "would write $dest/.version ($VERSION)"
	else
		printf '%s\n' "$VERSION" >"$dest/.version"
	fi
	say "installed $SKILL_NAME $VERSION -> $dest"
done

if [ "$PROJECT" -eq 0 ] && [ -d "$HOME/.codex/skills/$SKILL_NAME" ]; then
	warn "an older copy exists in ~/.codex/skills; current Codex reads ~/.agents/skills. Remove the old copy to avoid running a stale version."
fi
