#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# creativity-maxxing — Media module
# Installs Remotion, Higgsfield/Seedance prompt skills, YouTube transcripts,
# IG/social transcription (yt-dlp + Whisper), and FFmpeg.
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()    { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }
soft_fail() { echo -e "${RED}[FAIL]${NC} $1 (non-critical, continuing...)"; ERRORS=$((ERRORS + 1)); }

# -----------------------------------------------------------------------------
# Detect OS
# -----------------------------------------------------------------------------
detect_os() {
    case "$(uname -s)" in
        Darwin)       OS="mac" ;;
        Linux)        OS="linux" ;;
        MINGW*|MSYS*|CYGWIN*) fail "Windows is not supported. This script is for macOS and Linux only." ;;
        *)            fail "Unsupported OS: $(uname -s). This script supports macOS and Linux only." ;;
    esac
    info "Detected OS: $OS"
}

# -----------------------------------------------------------------------------
# Verify prerequisites
# -----------------------------------------------------------------------------
verify_prerequisites() {
    if ! command -v node &>/dev/null; then
        fail "Node.js not found. Install cli-maxxing first."
    fi
    if ! command -v claude &>/dev/null; then
        fail "Claude Code not found. Install cli-maxxing first."
    fi
    success "Prerequisites verified"
}

# -----------------------------------------------------------------------------
# Install Remotion skills via the skills CLI
# -----------------------------------------------------------------------------
install_remotion_skills() {
    info "Installing Remotion skills for Claude Code..."

    if [ -d "$HOME/.claude/skills/remotion-best-practices" ] || [ -L "$HOME/.claude/skills/remotion-best-practices" ]; then
        success "Remotion skills already installed"
        return
    fi

    npx skills add remotion-dev/skills --yes --global 2>/dev/null

    if [ -d "$HOME/.claude/skills/remotion-best-practices" ] || [ -L "$HOME/.claude/skills/remotion-best-practices" ]; then
        success "Remotion skills installed for Claude Code"
    else
        npx skills add remotion-dev/skills --yes 2>/dev/null

        if [ -d "$HOME/.claude/skills/remotion-best-practices" ] || [ -L "$HOME/.claude/skills/remotion-best-practices" ]; then
            success "Remotion skills installed"
        else
            soft_fail "Remotion skills installation could not be verified"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Install Higgsfield / Seedance 2.0 prompt skills (15 skills)
# Upstream: beshuaxian/higgsfield-seedance2-jineng
# We clone the repo once into a temp dir and copy each skills/<n>/SKILL.md to
# ~/.claude/skills/<n>/SKILL.md. Idempotent per-skill.
# -----------------------------------------------------------------------------
install_higgsfield_skills() {
    info "Installing Higgsfield / Seedance 2.0 prompt skills (15)..."

    local SKILL_NAMES=(
        "01-cinematic"
        "02-3d-cgi"
        "03-cartoon"
        "04-comic-to-video"
        "05-fight-scenes"
        "06-motion-design-ad"
        "07-ecommerce-ad"
        "08-anime-action"
        "09-product-360"
        "10-music-video"
        "11-social-hook"
        "12-brand-story"
        "13-fashion-lookbook"
        "14-food-beverage"
        "15-real-estate"
    )

    local missing=0
    for s in "${SKILL_NAMES[@]}"; do
        if [ ! -f "$HOME/.claude/skills/$s/SKILL.md" ]; then
            missing=$((missing + 1))
        fi
    done

    if [ "$missing" -eq 0 ]; then
        success "Higgsfield / Seedance skills already installed (all 15)"
        return
    fi

    local _TMP
    _TMP="$(mktemp -d)"
    trap 'rm -rf "$_TMP"' RETURN

    if ! git clone --quiet --depth 1 https://github.com/beshuaxian/higgsfield-seedance2-jineng.git "$_TMP" 2>/dev/null; then
        soft_fail "Could not clone Higgsfield repo — skipping. Install manually: https://github.com/beshuaxian/higgsfield-seedance2-jineng"
        return
    fi

    local installed=0
    for s in "${SKILL_NAMES[@]}"; do
        local src="$_TMP/skills/$s/SKILL.md"
        local dest_dir="$HOME/.claude/skills/$s"
        local dest="$dest_dir/SKILL.md"

        if [ -f "$dest" ]; then
            continue
        fi
        if [ ! -f "$src" ]; then
            warn "Upstream missing skill: $s (skipping)"
            continue
        fi

        mkdir -p "$dest_dir"
        cp "$src" "$dest"
        installed=$((installed + 1))
    done

    if [ "$installed" -gt 0 ]; then
        success "Higgsfield / Seedance skills installed ($installed new, $((${#SKILL_NAMES[@]} - installed)) already present)"
    else
        success "Higgsfield / Seedance skills verified"
    fi
}

# -----------------------------------------------------------------------------
# Install YouTube Transcript MCP (free transcript extraction from YouTube)
# -----------------------------------------------------------------------------
install_youtube_transcript() {
    info "Installing YouTube Transcript MCP server..."

    if claude mcp list 2>/dev/null | grep -qE '^youtube-transcript:'; then
        success "YouTube Transcript MCP already installed"
        return
    fi

    claude mcp add --scope user youtube-transcript -- npx -y @kimtaeyoon83/mcp-server-youtube-transcript 2>/dev/null

    if claude mcp list 2>/dev/null | grep -qE '^youtube-transcript:'; then
        success "YouTube Transcript MCP installed"
    else
        soft_fail "YouTube Transcript MCP installation could not be verified"
    fi
}

# -----------------------------------------------------------------------------
# Install yt-dlp MCP (download audio/video from Instagram, TikTok, etc.)
# -----------------------------------------------------------------------------
install_ytdlp_mcp() {
    info "Installing yt-dlp MCP server..."

    if claude mcp list 2>/dev/null | grep -qE '^yt-dlp:'; then
        success "yt-dlp MCP already installed"
        return
    fi

    claude mcp add --scope user yt-dlp -- npx -y @kevinwatt/yt-dlp-mcp@latest 2>/dev/null

    if claude mcp list 2>/dev/null | grep -qE '^yt-dlp:'; then
        success "yt-dlp MCP installed"
    else
        soft_fail "yt-dlp MCP installation could not be verified"
    fi
}

# -----------------------------------------------------------------------------
# Install yt-dlp CLI (needed by yt-dlp MCP for actual downloads)
# -----------------------------------------------------------------------------
install_ytdlp_cli() {
    if command -v yt-dlp &>/dev/null; then
        success "yt-dlp CLI already installed ($(yt-dlp --version 2>/dev/null))"
        return
    fi

    info "Installing yt-dlp CLI..."
    if [ "$OS" = "mac" ]; then
        brew install yt-dlp 2>/dev/null || true
    else
        sudo apt-get install -y yt-dlp 2>/dev/null \
            || sudo dnf install -y yt-dlp 2>/dev/null \
            || python3 -m pip install yt-dlp 2>/dev/null \
            || true
    fi

    if command -v yt-dlp &>/dev/null; then
        success "yt-dlp CLI installed"
    else
        soft_fail "yt-dlp CLI installation failed (install manually: brew install yt-dlp)"
    fi
}

# -----------------------------------------------------------------------------
# Install whisper-cpp (local speech-to-text engine)
# -----------------------------------------------------------------------------
install_whisper_cpp() {
    if command -v whisper-cli &>/dev/null || command -v whisper-cpp &>/dev/null || command -v whisper &>/dev/null; then
        success "whisper-cpp already installed"
        return
    fi

    info "Installing whisper-cpp (local transcription engine)..."
    if [ "$OS" = "mac" ]; then
        brew install whisper-cpp || { soft_fail "whisper-cpp installation failed"; return; }
    else
        if command -v apt-get &>/dev/null; then
            sudo apt-get install -y -qq whisper-cpp 2>/dev/null || {
                info "whisper-cpp not in apt — building from source..."
                if command -v cmake &>/dev/null && command -v g++ &>/dev/null; then
                    if git clone https://github.com/ggerganov/whisper.cpp.git /tmp/whisper-cpp-build 2>/dev/null; then
                        if (cd /tmp/whisper-cpp-build && cmake -B build && cmake --build build --config Release && sudo cp build/bin/whisper-cli /usr/local/bin/whisper-cpp 2>/dev/null); then
                            rm -rf /tmp/whisper-cpp-build
                        else
                            rm -rf /tmp/whisper-cpp-build
                            soft_fail "whisper-cpp build failed"
                            return
                        fi
                    else
                        soft_fail "whisper-cpp clone failed"
                        return
                    fi
                else
                    soft_fail "whisper-cpp requires cmake and g++ to build from source"
                    return
                fi
            }
        else
            soft_fail "Could not install whisper-cpp — install manually"
            return
        fi
    fi

    if command -v whisper-cli &>/dev/null || command -v whisper-cpp &>/dev/null || command -v whisper &>/dev/null; then
        success "whisper-cpp installed"
    else
        soft_fail "whisper-cpp installation could not be verified"
    fi
}

# -----------------------------------------------------------------------------
# Install Whisper MCP (local speech-to-text transcription)
# -----------------------------------------------------------------------------
install_whisper_mcp() {
    info "Installing Whisper MCP server..."

    if claude mcp list 2>/dev/null | grep -qE '^whisper-mcp:'; then
        success "Whisper MCP already installed"
        return
    fi

    claude mcp add --scope user whisper-mcp -- npx -y whisper-mcp 2>/dev/null

    if claude mcp list 2>/dev/null | grep -qE '^whisper-mcp:'; then
        success "Whisper MCP installed"
    else
        soft_fail "Whisper MCP installation could not be verified"
    fi
}

# -----------------------------------------------------------------------------
# Install FFmpeg (needed for video processing features)
# -----------------------------------------------------------------------------
install_ffmpeg() {
    if command -v ffmpeg &>/dev/null; then
        success "FFmpeg already installed ($(ffmpeg -version 2>/dev/null | head -1 | awk '{print $3}'))"
        return
    fi

    info "Installing FFmpeg..."
    if [ "$OS" = "mac" ]; then
        brew install ffmpeg 2>/dev/null || true
    else
        sudo apt-get install -y ffmpeg 2>/dev/null \
            || sudo dnf install -y ffmpeg 2>/dev/null \
            || sudo pacman -S --noconfirm ffmpeg 2>/dev/null \
            || true
    fi

    if command -v ffmpeg &>/dev/null; then
        success "FFmpeg installed"
    else
        soft_fail "FFmpeg installation failed (install manually: brew install ffmpeg)"
    fi
}

# -----------------------------------------------------------------------------
# Self-test
# -----------------------------------------------------------------------------
run_self_test() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Running Self-Test${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    local TEST_PASS=0
    local TEST_FAIL=0

    # Remotion skills
    if [ -d "$HOME/.claude/skills/remotion-best-practices" ] || [ -L "$HOME/.claude/skills/remotion-best-practices" ]; then
        success "TEST: Remotion skills installed"
        TEST_PASS=$((TEST_PASS + 1))
    else
        soft_fail "TEST: Remotion skills not found"
        TEST_FAIL=$((TEST_FAIL + 1))
    fi

    # Higgsfield skills — count how many of 15 exist
    local HIGGS_COUNT=0
    for s in 01-cinematic 02-3d-cgi 03-cartoon 04-comic-to-video 05-fight-scenes \
             06-motion-design-ad 07-ecommerce-ad 08-anime-action 09-product-360 \
             10-music-video 11-social-hook 12-brand-story 13-fashion-lookbook \
             14-food-beverage 15-real-estate; do
        if [ -f "$HOME/.claude/skills/$s/SKILL.md" ]; then
            HIGGS_COUNT=$((HIGGS_COUNT + 1))
        fi
    done
    if [ "$HIGGS_COUNT" -eq 15 ]; then
        success "TEST: Higgsfield / Seedance skills installed (15/15)"
        TEST_PASS=$((TEST_PASS + 1))
    elif [ "$HIGGS_COUNT" -gt 0 ]; then
        warn "TEST: Higgsfield / Seedance skills partial ($HIGGS_COUNT/15)"
        TEST_PASS=$((TEST_PASS + 1))
    else
        soft_fail "TEST: Higgsfield / Seedance skills not found"
        TEST_FAIL=$((TEST_FAIL + 1))
    fi

    if claude mcp list 2>/dev/null | grep -qE '^youtube-transcript:'; then
        success "TEST: YouTube Transcript MCP registered"
        TEST_PASS=$((TEST_PASS + 1))
    else
        soft_fail "TEST: YouTube Transcript MCP not registered"
        TEST_FAIL=$((TEST_FAIL + 1))
    fi

    if claude mcp list 2>/dev/null | grep -qE '^yt-dlp:'; then
        success "TEST: yt-dlp MCP registered"
        TEST_PASS=$((TEST_PASS + 1))
    else
        soft_fail "TEST: yt-dlp MCP not registered"
        TEST_FAIL=$((TEST_FAIL + 1))
    fi

    if command -v yt-dlp &>/dev/null; then
        success "TEST: yt-dlp CLI available"
        TEST_PASS=$((TEST_PASS + 1))
    else
        soft_fail "TEST: yt-dlp CLI not available"
        TEST_FAIL=$((TEST_FAIL + 1))
    fi

    if command -v whisper-cli &>/dev/null || command -v whisper-cpp &>/dev/null || command -v whisper &>/dev/null; then
        success "TEST: whisper-cpp installed"
        TEST_PASS=$((TEST_PASS + 1))
    else
        soft_fail "TEST: whisper-cpp not found"
        TEST_FAIL=$((TEST_FAIL + 1))
    fi

    if claude mcp list 2>/dev/null | grep -qE '^whisper-mcp:'; then
        success "TEST: Whisper MCP registered"
        TEST_PASS=$((TEST_PASS + 1))
    else
        soft_fail "TEST: Whisper MCP not registered"
        TEST_FAIL=$((TEST_FAIL + 1))
    fi

    if command -v ffmpeg &>/dev/null; then
        success "TEST: FFmpeg available"
        TEST_PASS=$((TEST_PASS + 1))
    else
        soft_fail "TEST: FFmpeg not available"
        TEST_FAIL=$((TEST_FAIL + 1))
    fi

    if npx skills --version &>/dev/null 2>&1; then
        success "TEST: Skills CLI available"
        TEST_PASS=$((TEST_PASS + 1))
    else
        soft_fail "TEST: Skills CLI not available"
        TEST_FAIL=$((TEST_FAIL + 1))
    fi

    echo ""
    if [ "$TEST_FAIL" -eq 0 ]; then
        echo -e "  ${GREEN}All $TEST_PASS tests passed.${NC}"
    else
        echo -e "  ${GREEN}$TEST_PASS passed${NC}, ${RED}$TEST_FAIL failed${NC}."
        echo -e "  ${YELLOW}Scroll up to see what went wrong.${NC}"
    fi
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
print_summary() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Media Module — Ready${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Remotion, Higgsfield/Seedance prompt skills, YouTube Transcripts,"
    echo "  Instagram/social transcription (yt-dlp + Whisper), and FFmpeg"
    echo "  are now available in Claude Code."
    echo ""
    echo "  What you can do now:"
    echo "    - Generate Seedance 2.0 prompts in 15 distinct video styles"
    echo "    - Create videos programmatically with Remotion + React"
    echo "    - Pull transcripts from any YouTube video"
    echo "    - Transcribe Instagram Reels, TikToks, and other social media locally"
    echo "    - Process audio/video with FFmpeg"
    echo ""
    echo "  Try it: ask Claude to 'make me a cinematic Seedance prompt for a"
    echo "  coffee-shop launch video,' paste an IG Reel URL for a transcript,"
    echo "  or start a new Remotion project."
    echo ""
    if [ "$ERRORS" -gt 0 ]; then
        echo -e "  ${YELLOW}Warnings: $ERRORS issue(s) detected.${NC}"
        echo -e "  ${YELLOW}Scroll up to see details.${NC}"
        echo ""
    fi
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Media Module${NC}"
    echo -e "${BLUE}  Remotion + Higgsfield + Transcription • macOS + Linux${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    detect_os
    verify_prerequisites
    install_remotion_skills
    install_higgsfield_skills
    install_youtube_transcript
    install_ytdlp_cli
    install_ytdlp_mcp
    install_whisper_cpp
    install_whisper_mcp
    install_ffmpeg
    run_self_test
    print_summary
}

main "$@"
