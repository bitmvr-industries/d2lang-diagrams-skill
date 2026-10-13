#!/usr/bin/env bash
# A team notes folder that a careless multi-board render to docs.svg would delete.
set -euo pipefail
mkdir -p docs
echo "# Team notes - do not delete" > docs/notes.md
