#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

branch="${1:-main}"
export GIT_TERMINAL_PROMPT=0

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ ${ROOT} is not a git repository." >&2
  exit 1
fi

echo "⬇️  ${ROOT} ← origin/${branch}"
git pull --ff-only origin "$branch"
echo "✅ $(git rev-parse --short HEAD) $(git log -1 --format=%s)"
