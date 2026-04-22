#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# creativity-maxxing — uninstall
# Removes every tool installed by the design + media modules, in reverse order.
# ffmpeg is prompted separately because it is frequently system-shared.
# =============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REMOVED=0
SKIPPED=0

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Track a removed item
removed_one() { REMOVED=$((REMOVED + 1)); success "$1"; }
# Track a skipped item (not present)
skipped_one() { SKIPPED=$((SKIPPED + 1)); info "$1"; }

# -----------------------------------------------------------------------------
# Remove UI/UX Pro Max skill
# -----------------------------------------------------------------------------
remove_uiux_skill() {
    local SKILL_DIR="$HOME/.claude/skills/ui-ux-pro-max"
    if [ -d "$SKILL_DIR" ] || [ -L "$SKILL_DIR" ]; then
        rm -rf "$SKILL_DIR"
        removed_one "Removed UI/UX Pro Max skill"
    else
        skipped_one "UI/UX Pro Max skill not present"
    fi
}

# -----------------------------------------------------------------------------
# Remove all 8 Taste Skill variants
# -----------------------------------------------------------------------------
remove_taste_skills() {
    local variants=(
        "design-taste-frontend"
        "redesign-existing-projects"
        "high-end-visual-design"
        "full-output-enforcement"
        "minimalist-ui"
        "industrial-brutalist-ui"
        "stitch-design-taste"
        "gpt-taste"
    )
    local r=0 s=0
    for v in "${variants[@]}"; do
        local dir="$HOME/.claude/skills/$v"
        if [ -d "$dir" ] || [ -L "$dir" ]; then
            rm -rf "$dir"
            r=$((r + 1))
        else
            s=$((s + 1))
        fi
    done
    REMOVED=$((REMOVED + r))
    SKIPPED=$((SKIPPED + s))
    success "Taste Skills: removed $r, skipped $s (already absent)"
}

# -----------------------------------------------------------------------------
# Remove 21st.dev Magic MCP
# -----------------------------------------------------------------------------
remove_magic_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -qE '^magic:'; then
            claude mcp remove magic 2>/dev/null || true
            removed_one "Removed 21st.dev Magic MCP"
        else
            skipped_one "21st.dev Magic MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove Canva MCP
# -----------------------------------------------------------------------------
remove_canva_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -qE '^canva:'; then
            claude mcp remove canva 2>/dev/null || true
            removed_one "Removed Canva MCP"
        else
            skipped_one "Canva MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove Figma MCP
# -----------------------------------------------------------------------------
remove_figma_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -qE '^figma:'; then
            claude mcp remove figma 2>/dev/null || true
            removed_one "Removed Figma MCP"
        else
            skipped_one "Figma MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove Excalidraw MCP
# -----------------------------------------------------------------------------
remove_excalidraw_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -qE '^excalidraw:'; then
            claude mcp remove excalidraw 2>/dev/null || true
            removed_one "Removed Excalidraw MCP"
        else
            skipped_one "Excalidraw MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove Gamma MCP
# -----------------------------------------------------------------------------
remove_gamma_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -qE '^gamma:'; then
            claude mcp remove gamma 2>/dev/null || true
            removed_one "Removed Gamma MCP"
        else
            skipped_one "Gamma MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove Playwright MCP
# -----------------------------------------------------------------------------
remove_playwright_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -qE '^playwright:'; then
            claude mcp remove playwright 2>/dev/null || true
            removed_one "Removed Playwright MCP"
        else
            skipped_one "Playwright MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove Higgsfield / Seedance 2.0 prompt skills
# -----------------------------------------------------------------------------
remove_higgsfield_skills() {
    local skills=(
        "01-cinematic" "02-3d-cgi" "03-cartoon" "04-comic-to-video"
        "05-fight-scenes" "06-motion-design-ad" "07-ecommerce-ad"
        "08-anime-action" "09-product-360" "10-music-video"
        "11-social-hook" "12-brand-story" "13-fashion-lookbook"
        "14-food-beverage" "15-real-estate"
    )
    local r=0 s=0
    for sk in "${skills[@]}"; do
        local dir="$HOME/.claude/skills/$sk"
        if [ -d "$dir" ] || [ -L "$dir" ]; then
            rm -rf "$dir"
            r=$((r + 1))
        else
            s=$((s + 1))
        fi
    done
    REMOVED=$((REMOVED + r))
    SKIPPED=$((SKIPPED + s))
    success "Higgsfield/Seedance skills: removed $r, skipped $s (already absent)"
}

# -----------------------------------------------------------------------------
# Remove Remotion skills
# -----------------------------------------------------------------------------
remove_remotion_skills() {
    local SKILL_DIR="$HOME/.claude/skills/remotion-best-practices"
    if [ -d "$SKILL_DIR" ] || [ -L "$SKILL_DIR" ]; then
        rm -rf "$SKILL_DIR"
        removed_one "Removed Remotion skills"
    else
        skipped_one "Remotion skills not present"
    fi
}

# -----------------------------------------------------------------------------
# Remove YouTube Transcript MCP
# -----------------------------------------------------------------------------
remove_youtube_transcript_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -qE '^youtube-transcript:'; then
            claude mcp remove youtube-transcript 2>/dev/null || true
            removed_one "Removed YouTube Transcript MCP"
        else
            skipped_one "YouTube Transcript MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove yt-dlp MCP
# -----------------------------------------------------------------------------
remove_ytdlp_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -qE '^yt-dlp:'; then
            claude mcp remove yt-dlp 2>/dev/null || true
            removed_one "Removed yt-dlp MCP"
        else
            skipped_one "yt-dlp MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove yt-dlp CLI via Homebrew
# -----------------------------------------------------------------------------
remove_ytdlp_cli() {
    if command -v brew >/dev/null 2>&1 && brew list yt-dlp >/dev/null 2>&1; then
        brew uninstall yt-dlp || warn "brew uninstall yt-dlp returned non-zero"
        removed_one "Removed yt-dlp CLI"
    else
        skipped_one "yt-dlp CLI not installed via Homebrew"
    fi
}

# -----------------------------------------------------------------------------
# Remove whisper-cpp
# -----------------------------------------------------------------------------
remove_whisper_cpp() {
    if command -v brew >/dev/null 2>&1 && brew list whisper-cpp >/dev/null 2>&1; then
        brew uninstall whisper-cpp || warn "brew uninstall whisper-cpp returned non-zero"
        removed_one "Removed whisper-cpp"
    else
        skipped_one "whisper-cpp not installed via Homebrew"
    fi
}

# -----------------------------------------------------------------------------
# Remove whisper-mcp
# -----------------------------------------------------------------------------
remove_whisper_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -qE '^whisper-mcp:'; then
            claude mcp remove whisper-mcp 2>/dev/null || true
            removed_one "Removed whisper-mcp"
        else
            skipped_one "whisper-mcp not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# ffmpeg — prompt before touching (system-shared)
# -----------------------------------------------------------------------------
remove_ffmpeg_prompt() {
    if command -v brew >/dev/null 2>&1 && brew list ffmpeg >/dev/null 2>&1; then
        read -r -p "ffmpeg is system-shared. Uninstall it? [y/N] " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            brew uninstall ffmpeg
            removed_one "Removed ffmpeg"
        else
            echo "Leaving ffmpeg in place."
            skipped_one "ffmpeg left in place (user declined)"
        fi
    else
        skipped_one "ffmpeg not installed via Homebrew"
    fi
}

print_summary() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  creativity-maxxing uninstall complete${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Removed : $REMOVED item(s)"
    echo "  Skipped : $SKIPPED item(s) (already absent or user declined)"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

main() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  creativity-maxxing — Uninstall${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    info "Uninstalling creativity-maxxing..."
    remove_uiux_skill
    remove_taste_skills
    remove_magic_mcp
    remove_canva_mcp
    remove_figma_mcp
    remove_excalidraw_mcp
    remove_gamma_mcp
    remove_playwright_mcp
    remove_higgsfield_skills
    remove_remotion_skills
    remove_youtube_transcript_mcp
    remove_ytdlp_mcp
    remove_ytdlp_cli
    remove_whisper_cpp
    remove_whisper_mcp
    remove_ffmpeg_prompt
    rm -f "$HOME/.claude/.creativity-maxxing-installed"
    print_summary
}

main "$@"
