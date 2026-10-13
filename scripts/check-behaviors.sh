#!/usr/bin/env bash
# Re-verify the d2 CLI behaviors that SKILL.md states as facts.
# A failure means d2 changed: update SKILL.md (and the matching reference) before shipping.
#
# Usage: bash scripts/check-behaviors.sh
set -uo pipefail

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cd "$work"

echo "d2 $(d2 --version)"
pass=0
fail=0

check() { # check <description> <command...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    pass=$((pass + 1))
  else
    echo "CHANGED: $desc"
    fail=$((fail + 1))
  fi
}

printf 'a -> b\nlayers: { x: { c -> d } }\n' > multi.d2

# Output safety: multi-board renders delete a same-named directory.
fresh_dir() { rm -rf "$1" "$1".*; mkdir "$1"; echo keep > "$1/keep"; }
bundle_deletes()   { fresh_dir out; d2 multi.d2 out.svg; [ ! -e out/keep ]; }
animated_deletes() { fresh_dir out; d2 --animate-interval=1000 multi.d2 out.svg; [ ! -e out ]; }
pdf_keeps()        { fresh_dir out; d2 multi.d2 out.pdf; [ -e out/keep ]; }
txt_fails_deletes() { fresh_dir out; ! d2 multi.d2 out.txt && [ ! -e out ]; }
check "multi-board SVG bundle replaces an existing same-named dir" bundle_deletes
check "animated multi-board SVG deletes an existing same-named dir" animated_deletes
check "PDF export leaves a same-named dir alone" pdf_keeps
check "multi-board .txt export fails and deletes the dir" txt_fails_deletes

# validate only parses.
printf 'a.shape: bogus\n' > bogus.d2
validate_weak() { d2 validate bogus.d2 && ! d2 bogus.d2 bogus.svg; }
check "d2 validate passes an unknown shape that render rejects" validate_weak

# Reserved keywords as names.
printf 'box: {\n  top: Signups\n}\n' > top.d2
printf 'box: {\n  "top": Signups\n}\n' > top-quoted.d2
top_breaks()  { ! d2 top.d2 top.svg; }
quoted_works() { d2 top-quoted.d2 tq.svg && grep -q 'Signups' tq.svg; }
check "unquoted 'top' as a child key fails to render" top_breaks
check "quoted '\"top\"' works as a child key" quoted_works

# '#' in an unquoted label starts a comment.
printf 'a: C# lang\n' > hash.d2
hash_truncates() { d2 hash.d2 hash.svg && ! grep -q 'C# lang' hash.svg; }
check "unquoted label 'C# lang' is truncated at #" hash_truncates

# Grid: grid-columns alone fills column by column (a c e / b d f).
printf 'grid-columns: 3\na;b;c;d;e;f\n' > grid.d2
column_major() { d2 grid.d2 grid.txt && sed -n 2p grid.txt | grep -q 'a.*c.*e'; }
check "grid-columns alone fills column by column" column_major

# Globs: ** reaches steps but not layers.
printf '(** -> **)[*].style.animated: true\na -> b\nsteps: { 1: { c -> d } }\nlayers: { l: { e -> f } }\n' > glob.d2
glob_reach() {
  rm -rf g; d2 glob.d2 g.svg &&
  grep -q dashdraw g/steps/1.svg && ! grep -q dashdraw g/layers/l.svg
}
check "** glob reaches steps but not layers" glob_reach

# Boards: shorthand layer titles drop inherited classes; direction and legends are per board.
printf 'classes: {c: {style.fill: "#ABCDEF"}}\nlayers: {\n  short: Short title {n: N {class: c}}\n  long: {label: Long title; n: N {class: c}}\n}\n' > board.d2
shorthand_drops() { rm -rf b; d2 board.d2 b.svg && ! grep -qi abcdef b/short.svg && grep -qi abcdef b/long.svg; }
check "layer titled in shorthand drops inherited classes; label: keeps them" shorthand_drops
printf 'direction: right\na -> b\nlayers: {x: {a -> b}}\n' > dir.d2
dir_not_inherited() {
  d2 --target='' dir.d2 root.txt && d2 --target='layers.x' dir.d2 layer.txt &&
  [ "$(grep -c '[ab] ' root.txt)" -lt "$(grep -c '[ab] ' layer.txt)" ]
}
check "layers do not inherit direction" dir_not_inherited
printf 'vars: {d2-legend: {k: Key entry}}\na\nlayers: {x: {b}}\n' > legend.d2
legend_per_board() { rm -rf l; d2 legend.d2 l.svg && grep -q 'Key entry' l/index.svg && ! grep -q 'Key entry' l/x.svg; }
check "d2-legend renders only on the board that declares it" legend_per_board

# CLI flags.
h_is_host() { ! d2 -h; }
check "d2 -h means --host (needs an argument), not help" h_is_host

echo "$pass unchanged, $fail changed"
[ "$fail" -eq 0 ]
