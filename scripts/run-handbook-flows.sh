#!/usr/bin/env bash
#
# Run every Maestro flow tagged with `handbook` and move the captured
# screenshots into docs/handbook/screenshots/. Required:
#   * iOS Simulator booted with Runner.app installed
#   * maestro CLI on PATH (or ~/.maestro/bin/maestro)
#
# Usage:  scripts/run-handbook-flows.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAESTRO="${MAESTRO:-$HOME/.maestro/bin/maestro}"

mkdir -p "$REPO_ROOT/docs/handbook/screenshots"

cd "$REPO_ROOT/.maestro"
"$MAESTRO" test --include-tags handbook .

# Maestro writes relative to CWD into ./screenshots/*.png. Move into
# the canonical handbook screenshots dir.
if [ -d "$REPO_ROOT/.maestro/screenshots" ]; then
  mv "$REPO_ROOT/.maestro/screenshots"/*.png "$REPO_ROOT/docs/handbook/screenshots/"
  rmdir "$REPO_ROOT/.maestro/screenshots"
fi

echo
echo "Screenshots:"
ls -1 "$REPO_ROOT/docs/handbook/screenshots/"
