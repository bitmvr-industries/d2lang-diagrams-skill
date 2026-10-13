#!/usr/bin/env bash
# Run the eval suite with Claude Code (`claude plugin eval`), with-skill vs without-skill.
# Extra arguments pass through, e.g.: --case grid-reserved-keys --runs 1
#
# Reports stay local (--no-publish). The agent gets Bash, Write and Edit inside the
# eval sandbox so it can run the d2 CLI; output-trap's setup.sh needs --scaffold.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo"

command -v d2 >/dev/null || { echo "d2 is not on PATH" >&2; exit 1; }

exec claude plugin eval . \
  --no-publish \
  --trust-plugin \
  --scaffold \
  --allow-tools Bash Write Edit \
  "$@"
