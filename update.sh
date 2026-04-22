#!/usr/bin/env bash
set -euo pipefail
# creativity-maxxing — Update
# Clones the latest version and re-runs all idempotent modules.

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  creativity-maxxing — Update${NC}"
echo -e "${BLUE}  Pulling latest and re-running all idempotent modules${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Design module:"
echo "    UI/UX Pro Max skill · 8× Taste Skills · 21st.dev Magic MCP"
echo "    Canva MCP · Figma MCP · Excalidraw MCP · Gamma MCP · Playwright MCP"
echo ""
echo "  Media module:"
echo "    Remotion skill · 15× Higgsfield/Seedance skills"
echo "    YouTube Transcript MCP · yt-dlp (CLI + MCP)"
echo "    whisper-cpp · whisper-mcp · FFmpeg"
echo ""

_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$_TMPDIR"' EXIT
git clone --quiet --depth 1 https://github.com/lorecraft-io/creativity-maxxing.git "$_TMPDIR"

bash "$_TMPDIR/design/install.sh"
bash "$_TMPDIR/media/install.sh"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  creativity-maxxing update complete.${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
