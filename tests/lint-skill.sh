#!/bin/sh
# Checks the skill's frontmatter and that every referenced file exists.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
MD="$ROOT/skill/SKILL.md"
fail() { printf 'FAIL %s\n' "$*"; exit 1; }

[ "$(sed -n 1p "$MD")" = "---" ] || fail "SKILL.md must start with a --- frontmatter line"
name=$(sed -n 's/^name: //p' "$MD" | head -n 1)
[ "$name" = "react-native-optimization" ] || fail "name is '$name', expected react-native-optimization"
desc=$(sed -n 's/^description: //p' "$MD" | head -n 1)
[ -n "$desc" ] || fail "description is missing"
len=$(printf '%s' "$desc" | wc -m)
[ "$len" -le 1024 ] || fail "description is $len characters (max 1024)"

grep -o '](references/[^)]*)' "$MD" | sed 's/^](//; s/)$//' | sort -u | while IFS= read -r ref; do
	[ -f "$ROOT/skill/$ref" ] || fail "SKILL.md links to missing $ref"
done
for f in "$ROOT"/skill/references/*.md; do
	grep -q "references/$(basename "$f")" "$MD" || fail "$(basename "$f") is not linked from SKILL.md"
done
printf 'ok   skill lint (description %s chars)\n' "$len"
