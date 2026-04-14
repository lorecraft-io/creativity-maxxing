#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

MARKER="$HOME/.claude/.creativity-maxxing-installed"
[ -f "$MARKER" ] && { echo "creativity-maxxing already installed. Run uninstall.sh to reinstall."; exit 0; }

command -v claude >/dev/null || { echo "Claude Code not found — run cli-maxxing first"; exit 1; }
[ -d "$HOME/.claude/skills" ] || { echo "~/.claude/skills missing — run cli-maxxing first"; exit 1; }

bash "$HERE/step-4/step-4-install.sh"
bash "$HERE/step-5/step-5-install.sh"
touch "$MARKER"
echo "creativity-maxxing install complete."
