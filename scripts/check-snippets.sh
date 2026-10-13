#!/usr/bin/env bash
# Render every ```d2 block in the skill's reference files with the installed d2.
# A block whose comments contain "INVALID" must fail; every other block must render.
# Run after upgrading d2 to find reference content that has drifted.
#
# Usage: bash scripts/check-snippets.sh [reference.md ...]
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
fixtures="$repo/tests/fixtures/imports"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

if [ "$#" -gt 0 ]; then
  files=("$@")
else
  files=("$repo"/skills/d2-diagrams/references/*.md)
fi

echo "d2 $(d2 --version)"

pass=0
fail=0
for md in "${files[@]}"; do
  name="$(basename "$md" .md)"
  # Split each ```d2 block into its own file: <name>-<n>.d2 with the start line recorded.
  awk -v dir="$work" -v name="$name" '
    /^```d2[[:space:]]*$/ { n++; f = sprintf("%s/%s-%02d.d2", dir, name, n); print "# line " NR > f; inblock = 1; next }
    /^```/ && inblock     { inblock = 0; close(f); next }
    inblock               { print > f }
  ' "$md"
done

for snippet in "$work"/*.d2; do
  [ -e "$snippet" ] || continue
  label="$(basename "$snippet" .d2) ($(head -1 "$snippet" | sed 's/^# //'))"
  # Each snippet renders in its own directory alongside the import fixtures.
  dir="$work/run-$(basename "$snippet" .d2)"
  mkdir -p "$dir"
  cp -R "$fixtures"/. "$dir"/
  # Snippets importing "@../x" are written as if they live one directory below the fixtures.
  if grep -q '@\.\./' "$snippet"; then
    dir="$dir/sub"
    mkdir -p "$dir"
  fi
  cp "$snippet" "$dir/snippet.d2"

  if grep -q 'INVALID' "$snippet"; then
    if (cd "$dir" && d2 snippet.d2 out.svg >/dev/null 2>&1); then
      echo "FAIL $label: marked INVALID but rendered"
      fail=$((fail + 1))
    else
      pass=$((pass + 1))
    fi
  else
    if err="$(cd "$dir" && d2 snippet.d2 out.svg 2>&1 >/dev/null)"; then
      pass=$((pass + 1))
    else
      echo "FAIL $label: $(echo "$err" | grep -m1 'err' | sed 's/.*snippet\.d2:/snippet.d2:/')"
      fail=$((fail + 1))
    fi
  fi
done

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
