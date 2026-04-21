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
        if claude mcp list 2>/dev/null | grep -q "magic"; then
            claude mcp remove magic 2>/dev/null || true
            success "Removed 21st.dev Magic MCP"
        else
            info "21st.dev Magic MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove Canva MCP
# -----------------------------------------------------------------------------
remove_canva_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -qi "canva"; then
            claude mcp remove canva 2>/dev/null || true
            success "Removed Canva MCP"
        else
            info "Canva MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove Figma MCP
# -----------------------------------------------------------------------------
remove_figma_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -qi "figma"; then
            claude mcp remove figma 2>/dev/null || true
            success "Removed Figma MCP"
        else
            info "Figma MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove Excalidraw MCP
# -----------------------------------------------------------------------------
remove_excalidraw_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -qi "excalidraw"; then
            claude mcp remove excalidraw 2>/dev/null || true
            success "Removed Excalidraw MCP"
        else
            info "Excalidraw MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove Gamma MCP
# -----------------------------------------------------------------------------
remove_gamma_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -qi "gamma"; then
            claude mcp remove gamma 2>/dev/null || true
            success "Removed Gamma MCP"
        else
            info "Gamma MCP not registered"
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
    local removed=0
    for s in "${skills[@]}"; do
        local dir="$HOME/.claude/skills/$s"
        if [ -d "$dir" ] || [ -L "$dir" ]; then
            rm -rf "$dir"
            removed=$((removed + 1))
        fi
    done
    success "Removed $removed Higgsfield/Seedance skill(s)"
}

# -----------------------------------------------------------------------------
# Remove Remotion skills
# -----------------------------------------------------------------------------
remove_remotion_skills() {
    local SKILL_DIR="$HOME/.claude/skills/remotion-best-practices"
    if [ -d "$SKILL_DIR" ] || [ -L "$SKILL_DIR" ]; then
        rm -rf "$SKILL_DIR"
        success "Removed Remotion skills"
    else
        info "Remotion skills not present"
    fi
}

# -----------------------------------------------------------------------------
# Remove YouTube Transcript MCP
# -----------------------------------------------------------------------------
remove_youtube_transcript_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -q "youtube-transcript"; then
            claude mcp remove youtube-transcript 2>/dev/null || true
            success "Removed YouTube Transcript MCP"
        else
            info "YouTube Transcript MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove yt-dlp MCP
# -----------------------------------------------------------------------------
remove_ytdlp_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -q "yt-dlp"; then
            claude mcp remove yt-dlp 2>/dev/null || true
            success "Removed yt-dlp MCP"
        else
            info "yt-dlp MCP not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Remove yt-dlp CLI via Homebrew
# -----------------------------------------------------------------------------
remove_ytdlp_cli() {
    if command -v brew >/dev/null 2>&1 && brew list yt-dlp >/dev/null 2>&1; then
        brew uninstall yt-dlp || warn "brew uninstall yt-dlp returned non-zero"
        success "Removed yt-dlp CLI"
    else
        info "yt-dlp CLI not installed via Homebrew"
    fi
}

# -----------------------------------------------------------------------------
# Remove whisper-cpp
# -----------------------------------------------------------------------------
remove_whisper_cpp() {
    if command -v brew >/dev/null 2>&1 && brew list whisper-cpp >/dev/null 2>&1; then
        brew uninstall whisper-cpp || warn "brew uninstall whisper-cpp returned non-zero"
        success "Removed whisper-cpp"
    else
        info "whisper-cpp not installed via Homebrew"
    fi
}

# -----------------------------------------------------------------------------
# Remove whisper-mcp
# -----------------------------------------------------------------------------
remove_whisper_mcp() {
    if command -v claude >/dev/null 2>&1; then
        if claude mcp list 2>/dev/null | grep -q "whisper"; then
            claude mcp remove whisper-mcp 2>/dev/null || claude mcp remove whisper 2>/dev/null || true
            success "Removed whisper-mcp"
        else
            info "whisper-mcp not registered"
        fi
    fi
}

# -----------------------------------------------------------------------------
# ffmpeg — prompt before touching (system-shared)
# -----------------------------------------------------------------------------
remove_ffmpeg_prompt() {
    if command -v brew >/dev/null 2>&1 && brew list ffmpeg >/dev/null 2>&1; then
        read -r -p "ffmpeg is system-shared. Uninstall it? [y/N] " ans
        [[ "$ans" =~ ^[Yy]$ ]] && brew uninstall ffmpeg || echo "Leaving ffmpeg in place."
    else
        info "ffmpeg not installed via Homebrew"
    fi
}

main() {
    info "Uninstalling creativity-maxxing..."
    remove_uiux_skill
    remove_taste_skills
    remove_magic_mcp
    remove_canva_mcp
    remove_figma_mcp
    remove_excalidraw_mcp
    remove_gamma_mcp
    remove_higgsfield_skills
    remove_remotion_skills
    remove_youtube_transcript_mcp
    remove_ytdlp_mcp
    remove_ytdlp_cli
    remove_whisper_cpp
    remove_whisper_mcp
    remove_ffmpeg_prompt
    rm -f "$HOME/.claude/.creativity-maxxing-installed"
    success "creativity-maxxing uninstall complete."
}

main "$@"
