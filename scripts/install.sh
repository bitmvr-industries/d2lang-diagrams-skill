#!/usr/bin/env bash
# Install the d2-diagrams skill into an agent's skills directory.
#
# Usage: bash scripts/install.sh [--link] [skills-dir ...]
#   skills-dir  defaults to ~/.agents/skills (the cross-agent location).
#               Others: ~/.claude/skills, ~/.codex/skills, .github/skills, ...
#   --link      symlink instead of copy, so edits in this repo are live (development only).
#
# Claude Code users: prefer the plugin install in README.md, which updates with the repo.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
src="$repo/skills/d2-diagrams"
mode=copy

targets=()
for arg in "$@"; do
  case "$arg" in
    --link) mode=link ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) targets+=("$arg") ;;
  esac
done
[ "${#targets[@]}" -gt 0 ] || targets=("$HOME/.agents/skills")

command -v d2 >/dev/null || echo "warning: d2 is not on PATH; the skill needs the d2 CLI (https://d2lang.com/tour/install)" >&2

for dir in "${targets[@]}"; do
  dest="$dir/d2-diagrams"
  mkdir -p "$dir"
  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    # Replace an earlier install, but only one that looks like this skill.
    grep -q '^name: d2-diagrams$' "$dest/SKILL.md" 2>/dev/null || { echo "refusing to replace $dest: not a d2-diagrams install" >&2; exit 1; }
    rm -rf "$dest"
  fi
  if [ "$mode" = link ]; then
    ln -s "$src" "$dest"
  else
    cp -R "$src" "$dest"
  fi
  echo "$mode: $dest"
done
