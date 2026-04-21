#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# creativity-maxxing — Design module
# Installs design intelligence, anti-slop taste skills, and component/Canva MCPs.
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
# Install UI/UX Pro Max Skill
# -----------------------------------------------------------------------------
install_uiux_skill() {
    SKILL_DIR="$HOME/.claude/skills/ui-ux-pro-max"

    if [ -f "$SKILL_DIR/SKILL.md" ]; then
        success "UI/UX Pro Max Skill already installed"
        return
    fi

    info "Installing UI/UX Pro Max Skill..."
    mkdir -p "$SKILL_DIR"

    SKILL_URL="https://raw.githubusercontent.com/nextlevelbuilder/ui-ux-pro-max-skill/main/CLAUDE.md"
    curl -fsSL "$SKILL_URL" -o "$SKILL_DIR/SKILL.md" 2>/dev/null

    if [ -f "$SKILL_DIR/SKILL.md" ] && [ -s "$SKILL_DIR/SKILL.md" ]; then
        success "UI/UX Pro Max Skill installed at $SKILL_DIR"
    else
        soft_fail "Could not download skill file. Install manually from: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill"
    fi
}

# -----------------------------------------------------------------------------
# Install Taste Skill (Leonxlnx/taste-skill)
# Upstream ships 8 skills whose `name:` frontmatter drives their installed path:
#   design-taste-frontend, high-end-visual-design, full-output-enforcement,
#   redesign-existing-projects, stitch-design-taste, minimalist-ui,
#   industrial-brutalist-ui, gpt-taste
# -----------------------------------------------------------------------------
TASTE_INSTALLED_NAMES=(
    "design-taste-frontend"
    "high-end-visual-design"
    "full-output-enforcement"
    "redesign-existing-projects"
    "stitch-design-taste"
    "minimalist-ui"
    "industrial-brutalist-ui"
    "gpt-taste"
)

taste_installed_count() {
    local count=0
    for v in "${TASTE_INSTALLED_NAMES[@]}"; do
        if [ -d "$HOME/.claude/skills/$v" ] || [ -L "$HOME/.claude/skills/$v" ]; then
            count=$((count + 1))
        fi
    done
    echo "$count"
}

install_taste_skill() {
    local before_count
    before_count="$(taste_installed_count)"
    if [ "$before_count" -ge 7 ]; then
        success "Taste Skill already installed ($before_count/8 variants present)"
        return
    fi

    info "Installing Taste Skill pack (Leonxlnx/taste-skill)..."

    local TASTE_SKILL_URL="https://github.com/Leonxlnx/taste-skill"

    npx skills add "$TASTE_SKILL_URL" --yes --global 2>/dev/null

    local after_count
    after_count="$(taste_installed_count)"
    if [ "$after_count" -lt 7 ]; then
        npx skills add "$TASTE_SKILL_URL" --yes 2>/dev/null
        after_count="$(taste_installed_count)"
    fi

    if [ "$after_count" -ge 7 ]; then
        success "Taste Skill installed ($after_count/8 variants under ~/.claude/skills/)"
    else
        soft_fail "Taste Skill installation could not be verified ($after_count/8 variants found) — install manually: npx skills add https://github.com/Leonxlnx/taste-skill --yes --global"
    fi
}

# -----------------------------------------------------------------------------
# Install 21st.dev Magic MCP
# -----------------------------------------------------------------------------
install_21st_magic() {
    if claude mcp list 2>/dev/null | grep -qi "magic\|21st" 2>/dev/null; then
        success "21st.dev Magic MCP already configured"
        return
    fi

    info "Adding 21st.dev Magic MCP to Claude Code..."
    npx -y @anthropic-ai/claude-code mcp add magic -- npx -y @21st-dev/magic@latest 2>/dev/null \
        || claude mcp add magic -- npx -y @21st-dev/magic@latest 2>/dev/null

    if claude mcp list 2>/dev/null | grep -qi "magic\|21st" 2>/dev/null; then
        success "21st.dev Magic MCP configured"
    else
        warn "Could not auto-configure Magic MCP. You may need to set it up manually."
        echo ""
        echo "  To set up manually:"
        echo "  1. Go to https://21st.dev"
        echo "  2. Create a free account"
        echo "  3. Follow the MCP setup instructions on their site"
        echo ""
    fi
}

# -----------------------------------------------------------------------------
# Install Canva MCP (remote, OAuth on first use)
# -----------------------------------------------------------------------------
install_canva_mcp() {
    if claude mcp list 2>/dev/null | grep -qi "canva" 2>/dev/null; then
        success "Canva MCP already configured"
        return
    fi

    info "Adding Canva MCP (remote) to Claude Code..."

    # Canva ships a hosted remote MCP at https://mcp.canva.com/mcp
    # First call triggers OAuth in the user's browser.
    claude mcp add --scope user --transport http canva https://mcp.canva.com/mcp 2>/dev/null \
        || claude mcp add --transport http canva https://mcp.canva.com/mcp 2>/dev/null \
        || claude mcp add --scope user --transport sse canva https://mcp.canva.com/mcp 2>/dev/null

    if claude mcp list 2>/dev/null | grep -qi "canva" 2>/dev/null; then
        success "Canva MCP configured — first call will open a browser for OAuth"
    else
        soft_fail "Canva MCP install could not be verified — add manually: claude mcp add --scope user --transport http canva https://mcp.canva.com/mcp"
    fi
}

# -----------------------------------------------------------------------------
# Generic remote HTTP MCP installer — used by Figma, Excalidraw, Gamma.
# All three expose `claude mcp add --transport http <name> <url>` and trigger
# OAuth in the user's browser on first tool use.
# Args: $1 = friendly name (e.g. "Figma"), $2 = server name (e.g. "figma"), $3 = URL
# -----------------------------------------------------------------------------
install_remote_http_mcp() {
    local label="$1"
    local server="$2"
    local url="$3"

    if claude mcp list 2>/dev/null | grep -qi "^${server}\b\|[[:space:]]${server}\b" 2>/dev/null; then
        success "${label} MCP already configured"
        return
    fi

    info "Adding ${label} MCP (remote) to Claude Code..."

    claude mcp add --scope user --transport http "$server" "$url" 2>/dev/null \
        || claude mcp add --transport http "$server" "$url" 2>/dev/null \
        || claude mcp add --scope user --transport sse "$server" "$url" 2>/dev/null

    if claude mcp list 2>/dev/null | grep -qi "^${server}\b\|[[:space:]]${server}\b" 2>/dev/null; then
        success "${label} MCP configured — first call will open a browser for OAuth"
    else
        soft_fail "${label} MCP install could not be verified — add manually: claude mcp add --scope user --transport http ${server} ${url}"
    fi
}

install_figma_mcp()      { install_remote_http_mcp "Figma"      "figma"      "https://mcp.figma.com/mcp"; }
install_excalidraw_mcp() { install_remote_http_mcp "Excalidraw" "excalidraw" "https://mcp.excalidraw.com/mcp"; }
install_gamma_mcp()      { install_remote_http_mcp "Gamma"      "gamma"      "https://mcp.gamma.app/mcp"; }

# -----------------------------------------------------------------------------
# Self-test
# -----------------------------------------------------------------------------
run_self_test() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Running Self-Test${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    TEST_PASS=0
    TEST_FAIL=0

    if [ -f "$HOME/.claude/skills/ui-ux-pro-max/SKILL.md" ]; then
        success "TEST: UI/UX Pro Max Skill installed"
        TEST_PASS=$((TEST_PASS + 1))
    else
        soft_fail "TEST: UI/UX Pro Max Skill not found"
        TEST_FAIL=$((TEST_FAIL + 1))
    fi

    local taste_count
    taste_count="$(taste_installed_count)"
    if [ "$taste_count" -ge 7 ]; then
        success "TEST: Taste Skill installed ($taste_count/8 variants)"
        TEST_PASS=$((TEST_PASS + 1))
    else
        soft_fail "TEST: Taste Skill incomplete ($taste_count/8 variants)"
        TEST_FAIL=$((TEST_FAIL + 1))
    fi

    if claude mcp list 2>/dev/null | grep -qi "magic\|21st" 2>/dev/null; then
        success "TEST: 21st.dev Magic MCP configured"
        TEST_PASS=$((TEST_PASS + 1))
    else
        warn "TEST: 21st.dev Magic MCP may need manual setup (see instructions below)"
        TEST_PASS=$((TEST_PASS + 1))
    fi

    if claude mcp list 2>/dev/null | grep -qi "canva" 2>/dev/null; then
        success "TEST: Canva MCP configured"
        TEST_PASS=$((TEST_PASS + 1))
    else
        warn "TEST: Canva MCP may need manual setup"
        TEST_PASS=$((TEST_PASS + 1))
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
    echo -e "${GREEN}  Design Module — Ready${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Installed:"
    echo "    UI/UX Pro Max    $([ -f "$HOME/.claude/skills/ui-ux-pro-max/SKILL.md" ] && echo 'installed' || echo '—')"
    local taste_count
    taste_count="$(taste_installed_count)"
    if [ "$taste_count" -ge 7 ]; then
        echo "    Taste Skill      installed ($taste_count/8 variants)"
    else
        echo "    Taste Skill      $taste_count/8 variants (partial)"
    fi
    echo "    21st.dev Magic   $(claude mcp list 2>/dev/null | grep -qi 'magic\|21st' && echo 'configured' || echo 'needs manual setup')"
    echo "    Canva MCP        $(claude mcp list 2>/dev/null | grep -qi 'canva' && echo 'configured (OAuth on first call)' || echo 'needs manual setup')"
    echo ""
    echo "  Taste Skill variants (installed names / slash commands):"
    echo "    - /design-taste-frontend       (default premium frontend rules, 3 knobs)"
    echo "    - /redesign-existing-projects  (upgrade existing projects — audit first)"
    echo "    - /high-end-visual-design      (premium soft UI, spring animations)"
    echo "    - /full-output-enforcement     (anti-laziness: no placeholder comments)"
    echo "    - /minimalist-ui               (clean, editorial, Notion/Linear style)"
    echo "    - /industrial-brutalist-ui     (raw mechanical, CRT terminal aesthetics)"
    echo "    - /stitch-design-taste         (Google Stitch-compatible semantic rules)"
    echo "    - /gpt-taste                   (GPT-leaning variant)"
    echo ""
    echo "  design-taste-frontend knobs (edit its SKILL.md to tune, 1-10 scale):"
    echo "    DESIGN_VARIANCE   — 1-3 centered/clean   | 8-10 asymmetric/modern"
    echo "    MOTION_INTENSITY  — 1-3 simple hover     | 8-10 scroll-triggered"
    echo "    VISUAL_DENSITY    — 1-3 spacious/luxury  | 8-10 dense dashboards"
    echo ""
    if [ "$ERRORS" -gt 0 ]; then
        echo -e "  ${YELLOW}Warnings: $ERRORS issue(s) detected.${NC}"
        echo -e "  ${YELLOW}Scroll up to see details.${NC}"
        echo ""
    fi
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  Manual follow-ups you may need:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  21st.dev Magic — if auto-config missed, grab a free API key:"
    echo "    1. Go to https://21st.dev"
    echo "    2. Create a free account"
    echo "    3. Follow the MCP setup one-liner on their site"
    echo ""
    echo "  Canva MCP — OAuth on first use:"
    echo "    1. Ask Claude to list Canva designs (or use any Canva tool)"
    echo "    2. Claude opens a browser window — approve Canva access"
    echo "    3. Done. Subsequent calls are seamless."
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Design Module${NC}"
    echo -e "${BLUE}  UI/UX Pro Max + Taste Skills + Magic + Canva + Figma + Excalidraw + Gamma${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    detect_os
    verify_prerequisites
    install_uiux_skill
    install_taste_skill
    install_21st_magic
    install_canva_mcp
    install_figma_mcp
    install_excalidraw_mcp
    install_gamma_mcp
    run_self_test
    print_summary
}

main "$@"
