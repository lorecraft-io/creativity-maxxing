#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# creativity-maxxing — Root installer
# Installs the design + media modules.
#
# Design module:  UI/UX Pro Max skill · 8× Taste Skills · 21st.dev Magic MCP
#                 Canva MCP · Figma MCP · Excalidraw MCP · Gamma MCP
# Media module:   Remotion skill · 15× Higgsfield/Seedance skills
#                 YouTube Transcript MCP · yt-dlp (CLI + MCP) · whisper-cpp
#                 whisper-mcp · FFmpeg
# =============================================================================

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

MARKER="$HOME/.claude/.creativity-maxxing-installed"
[ -f "$MARKER" ] && { echo "creativity-maxxing already installed. Run uninstall.sh to reinstall."; exit 0; }

command -v claude >/dev/null || { echo "Claude Code not found — run cli-maxxing first"; exit 1; }
[ -d "$HOME/.claude/skills" ] || { echo "\$HOME/.claude/skills missing — run cli-maxxing first"; exit 1; }

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  creativity-maxxing — Install${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Design module:"
echo "    UI/UX Pro Max skill · 8× Taste Skills · 21st.dev Magic MCP"
echo "    Canva MCP · Figma MCP · Excalidraw MCP · Gamma MCP"
echo ""
echo "  Media module:"
echo "    Remotion skill · 15× Higgsfield/Seedance skills"
echo "    YouTube Transcript MCP · yt-dlp (CLI + MCP)"
echo "    whisper-cpp · whisper-mcp · FFmpeg"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Resolve repo root — works from local clone AND bash <(curl ...)
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ ! -f "$HERE/design/install.sh" ]; then
    _TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$_TMPDIR"' EXIT
    git clone --quiet --depth 1 https://github.com/lorecraft-io/creativity-maxxing.git "$_TMPDIR"
    HERE="$_TMPDIR"
fi

bash "$HERE/design/install.sh"
bash "$HERE/media/install.sh"
touch "$MARKER"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  creativity-maxxing install complete.${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
