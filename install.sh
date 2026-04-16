#!/usr/bin/env bash
set -euo pipefail

MARKER="$HOME/.claude/.creativity-maxxing-installed"
[ -f "$MARKER" ] && { echo "creativity-maxxing already installed. Run uninstall.sh to reinstall."; exit 0; }

command -v claude >/dev/null || { echo "Claude Code not found — run cli-maxxing first"; exit 1; }
[ -d "$HOME/.claude/skills" ] || { echo "\$HOME/.claude/skills missing — run cli-maxxing first"; exit 1; }

# Resolve repo root — works from local clone AND bash <(curl ...)
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ ! -f "$HERE/step-4/step-4-install.sh" ]; then
    _TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$_TMPDIR"' EXIT
    git clone --quiet --depth 1 https://github.com/lorecraft-io/creativity-maxxing.git "$_TMPDIR"
    HERE="$_TMPDIR"
fi

bash "$HERE/step-4/step-4-install.sh"
bash "$HERE/step-5/step-5-install.sh"
touch "$MARKER"
echo "creativity-maxxing install complete."
