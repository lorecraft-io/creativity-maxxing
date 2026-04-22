#!/usr/bin/env bash
# tests/test_uninstall.sh
# Verifies uninstall.sh reverses every install step added by the design +
# media modules. Specifically includes remove_playwright_mcp — the Playwright
# MCP is the newest design-module addition and its uninstall path MUST be
# symmetric to its install path.
#
# Strategy: mostly static coverage (function presence, tool naming, main()
# pipeline), with one behavioral probe that runs uninstall.sh against a
# mocked claude + fake ~/.claude/skills tree and confirms the marker file,
# Playwright MCP registration, and all 15 Higgsfield skill directories are
# all removed.

set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
# shellcheck source=./lib/assertions.sh
source "$HERE/lib/assertions.sh"

assert_reset "test_uninstall"

UNINSTALL_SH="$REPO_ROOT/uninstall.sh"
if [[ ! -f "$UNINSTALL_SH" ]]; then
  printf "%sSKIP%s test_uninstall (uninstall.sh not present)\n" \
    "${_C_YELLOW:-}" "${_C_RESET:-}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Static contract: every remove_* helper exists and is wired in main().
# ---------------------------------------------------------------------------
REMOVE_FNS=(
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
)
for fn in "${REMOVE_FNS[@]}"; do
  assert_contains "$UNINSTALL_SH" "re:^${fn}\(\)" "function defined: $fn"
  assert_contains "$UNINSTALL_SH" "re:^[[:space:]]+${fn}(\$|[[:space:]])" \
    "main() calls $fn"
done

# remove_playwright_mcp explicitly calls `claude mcp remove playwright`.
assert_contains "$UNINSTALL_SH" 're:claude mcp remove playwright' \
  "remove_playwright_mcp calls 'claude mcp remove playwright'"

# 15 Higgsfield skills listed in remove_higgsfield_skills.
for s in 01-cinematic 02-3d-cgi 03-cartoon 04-comic-to-video 05-fight-scenes \
         06-motion-design-ad 07-ecommerce-ad 08-anime-action 09-product-360 \
         10-music-video 11-social-hook 12-brand-story 13-fashion-lookbook \
         14-food-beverage 15-real-estate; do
  assert_contains "$UNINSTALL_SH" "\"$s\"" \
    "Higgsfield skill listed for removal: $s"
done

# All 8 taste-skill variants listed for removal.
for v in design-taste-frontend high-end-visual-design full-output-enforcement \
         redesign-existing-projects stitch-design-taste minimalist-ui \
         industrial-brutalist-ui gpt-taste; do
  assert_contains "$UNINSTALL_SH" "\"$v\"" \
    "taste variant listed for removal: $v"
done

# Marker file is removed.
assert_contains "$UNINSTALL_SH" ".creativity-maxxing-installed" \
  "uninstall.sh removes the install marker"
assert_contains "$UNINSTALL_SH" "re:rm -f[[:space:]].*\\.creativity-maxxing-installed" \
  "marker removal uses 'rm -f' (not destructive 'rm -rf')"

# ffmpeg prompt is interactive (prompt-before-remove).
assert_contains "$UNINSTALL_SH" "re:read -r -p" \
  "remove_ffmpeg_prompt uses 'read -r -p' to ask before touching system ffmpeg"

# Hygiene.
assert_contains "$UNINSTALL_SH" 're:^set -euo pipefail' \
  "uninstall.sh uses strict mode (set -euo pipefail)"

# ---------------------------------------------------------------------------
# Behavioral probe: run uninstall.sh against a fake claude + fake
# ~/.claude/skills tree.
# ---------------------------------------------------------------------------
TMPROOT="$(mktemp -d -t cm-uninstall-XXXXXX)"
cleanup() {
  if [[ -n "${TMPROOT:-}" && ( "$TMPROOT" == /tmp/* || "$TMPROOT" == /var/folders/* ) ]]; then
    rm -rf "$TMPROOT"
  fi
}
trap cleanup EXIT

FAKE_HOME="$TMPROOT/home"
mkdir -p "$FAKE_HOME/.claude/skills"

# Seed every skill dir uninstall.sh is supposed to remove.
for v in design-taste-frontend high-end-visual-design full-output-enforcement \
         redesign-existing-projects stitch-design-taste minimalist-ui \
         industrial-brutalist-ui gpt-taste ui-ux-pro-max remotion-best-practices \
         01-cinematic 02-3d-cgi 03-cartoon 04-comic-to-video 05-fight-scenes \
         06-motion-design-ad 07-ecommerce-ad 08-anime-action 09-product-360 \
         10-music-video 11-social-hook 12-brand-story 13-fashion-lookbook \
         14-food-beverage 15-real-estate; do
  mkdir -p "$FAKE_HOME/.claude/skills/$v"
  touch "$FAKE_HOME/.claude/skills/$v/SKILL.md"
done

# Install marker.
touch "$FAKE_HOME/.claude/.creativity-maxxing-installed"

MOCK_BIN="$TMPROOT/mock-bin"
CALL_LOG="$TMPROOT/claude-calls.log"
MCP_STATE="$TMPROOT/mcp-state"
mkdir -p "$MOCK_BIN"
: > "$CALL_LOG"

# Pre-register every MCP uninstall.sh will try to remove, so each `mcp list`
# returns the expected row.
cat > "$MCP_STATE" <<'STATE'
magic: npx -y @21st-dev/magic@latest
canva: https://mcp.canva.com/mcp
figma: https://mcp.figma.com/mcp
excalidraw: https://mcp.excalidraw.com/mcp
gamma: https://mcp.gamma.app/mcp
playwright: npx -y @playwright/mcp@latest
youtube-transcript: npx -y @kimtaeyoon83/mcp-server-youtube-transcript
yt-dlp: npx -y @kevinwatt/yt-dlp-mcp@latest
whisper-mcp: npx -y whisper-mcp
STATE

cat > "$MOCK_BIN/claude" <<SHIM
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$CALL_LOG"
case "\$1" in
  --version) echo "2.1.0 (Claude Code)"; exit 0 ;;
  mcp)
    case "\$2" in
      list)   cat "$MCP_STATE"; exit 0 ;;
      remove) grep -v "^\$3:" "$MCP_STATE" > "$MCP_STATE.tmp" || true
              mv "$MCP_STATE.tmp" "$MCP_STATE"; exit 0 ;;
    esac ;;
esac
exit 0
SHIM
chmod +x "$MOCK_BIN/claude"

# Stub `brew` to always report "not installed" so we don't actually try to
# uninstall system packages. Answer "N" to the ffmpeg prompt via stdin.
cat > "$MOCK_BIN/brew" <<'SHIM'
#!/usr/bin/env bash
# Minimal brew stub — reports no packages installed.
exit 1
SHIM
chmod +x "$MOCK_BIN/brew"

set +e
UNINST_OUT="$(PATH="$MOCK_BIN:$PATH" HOME="$FAKE_HOME" \
  bash "$UNINSTALL_SH" <<<'N' 2>&1)"
UNINST_RC=$?
set -e 2>/dev/null || true

assert_eq "$UNINST_RC" "0" "uninstall.sh exits 0 against mocked environment"

# Marker gone.
if [[ ! -f "$FAKE_HOME/.claude/.creativity-maxxing-installed" ]]; then
  _pass "install marker removed"
else
  _fail "install marker still present after uninstall"
fi

# All 15 Higgsfield skill dirs removed.
HIGGS_LEFT=0
for s in 01-cinematic 02-3d-cgi 03-cartoon 04-comic-to-video 05-fight-scenes \
         06-motion-design-ad 07-ecommerce-ad 08-anime-action 09-product-360 \
         10-music-video 11-social-hook 12-brand-story 13-fashion-lookbook \
         14-food-beverage 15-real-estate; do
  [[ -d "$FAKE_HOME/.claude/skills/$s" ]] && HIGGS_LEFT=$((HIGGS_LEFT + 1))
done
assert_eq "$HIGGS_LEFT" "0" "all 15 Higgsfield skill dirs removed"

# All 8 taste-skill variants removed.
TASTE_LEFT=0
for v in design-taste-frontend high-end-visual-design full-output-enforcement \
         redesign-existing-projects stitch-design-taste minimalist-ui \
         industrial-brutalist-ui gpt-taste; do
  [[ -d "$FAKE_HOME/.claude/skills/$v" ]] && TASTE_LEFT=$((TASTE_LEFT + 1))
done
assert_eq "$TASTE_LEFT" "0" "all 8 taste-skill variants removed"

# UI/UX Pro Max + Remotion skill dirs removed.
if [[ ! -d "$FAKE_HOME/.claude/skills/ui-ux-pro-max" ]]; then
  _pass "ui-ux-pro-max skill dir removed"
else
  _fail "ui-ux-pro-max skill dir still present"
fi
if [[ ! -d "$FAKE_HOME/.claude/skills/remotion-best-practices" ]]; then
  _pass "remotion-best-practices skill dir removed"
else
  _fail "remotion-best-practices skill dir still present"
fi

# Playwright explicitly removed from the mocked MCP state.
if grep -q '^playwright:' "$MCP_STATE"; then
  _fail "playwright MCP still in mocked state — remove_playwright_mcp did not fire"
  sed 's/^/    /' "$MCP_STATE" 1>&2
else
  _pass "remove_playwright_mcp removed playwright from mocked MCP state"
fi
# Every other MCP also gone.
for name in magic canva figma excalidraw gamma youtube-transcript yt-dlp whisper-mcp; do
  if grep -q "^${name}:" "$MCP_STATE"; then
    _fail "$name MCP still in mocked state after uninstall"
  else
    _pass "$name MCP removed from mocked state"
  fi
done

# Uninstall output contains the 'uninstall complete' banner.
if echo "$UNINST_OUT" | grep -qi 'uninstall complete'; then
  _pass "uninstall.sh prints 'uninstall complete' banner"
else
  _fail "uninstall.sh missing 'uninstall complete' banner"
fi

assert_report
