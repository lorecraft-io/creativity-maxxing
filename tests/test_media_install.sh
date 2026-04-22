#!/usr/bin/env bash
# tests/test_media_install.sh
# Static + light-behavioral coverage for media/install.sh.
# Verifies every advertised tool is wired:
#   - Remotion skill (remotion-best-practices)
#   - 15 Higgsfield / Seedance 2.0 prompt skills (01-cinematic … 15-real-estate)
#   - YouTube Transcript MCP (kimtaeyoon83)
#   - yt-dlp MCP (kevinwatt) + yt-dlp CLI
#   - whisper-cpp + whisper-mcp
#   - FFmpeg

set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
# shellcheck source=./lib/assertions.sh
source "$HERE/lib/assertions.sh"

assert_reset "test_media_install"

MEDIA_SH="$REPO_ROOT/media/install.sh"
if [[ ! -f "$MEDIA_SH" ]]; then
  printf "%sSKIP%s test_media_install (media/install.sh not present)\n" \
    "${_C_YELLOW:-}" "${_C_RESET:-}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Function definitions.
# ---------------------------------------------------------------------------
for fn in detect_os verify_prerequisites install_remotion_skills \
          install_higgsfield_skills install_youtube_transcript \
          install_ytdlp_mcp install_ytdlp_cli install_whisper_cpp \
          install_whisper_mcp install_ffmpeg run_self_test print_summary; do
  assert_contains "$MEDIA_SH" "re:^${fn}\(\)" \
    "function defined: $fn"
done

# ---------------------------------------------------------------------------
# Main() pipeline — every installer is wired in the right order.
# ---------------------------------------------------------------------------
for fn in install_remotion_skills install_higgsfield_skills \
          install_youtube_transcript install_ytdlp_cli install_ytdlp_mcp \
          install_whisper_cpp install_whisper_mcp install_ffmpeg; do
  assert_contains "$MEDIA_SH" "re:^[[:space:]]+${fn}(\$|[[:space:]])" \
    "main() calls $fn"
done

# ---------------------------------------------------------------------------
# All 15 Higgsfield/Seedance prompt skills listed in the installer.
# Audit checklist: "All 15 Higgsfield skills".
# ---------------------------------------------------------------------------
HIGGSFIELD_SKILLS=(
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
for s in "${HIGGSFIELD_SKILLS[@]}"; do
  assert_contains "$MEDIA_SH" "\"$s\"" \
    "higgsfield skill listed in installer array: $s"
done

# Upstream repo URL for Higgsfield skills (avoid rug-pull via wrong fork).
assert_contains "$MEDIA_SH" "beshuaxian/higgsfield-seedance2-jineng" \
  "Higgsfield skills point at beshuaxian/higgsfield-seedance2-jineng upstream"

# Self-test loop counts 15 skills.
assert_contains "$MEDIA_SH" "15/15" \
  "self-test reports 15/15 when all Higgsfield skills land"

# ---------------------------------------------------------------------------
# Tool-specific identifiers (catches a silent rename).
# ---------------------------------------------------------------------------
assert_contains "$MEDIA_SH" "@kimtaeyoon83/mcp-server-youtube-transcript" \
  "YouTube Transcript MCP npm package referenced"
assert_contains "$MEDIA_SH" "@kevinwatt/yt-dlp-mcp" \
  "yt-dlp MCP npm package referenced"
assert_contains "$MEDIA_SH" "whisper-mcp" \
  "whisper-mcp name referenced"
assert_contains "$MEDIA_SH" "remotion-dev/skills" \
  "Remotion skills upstream (remotion-dev/skills) referenced"
assert_contains "$MEDIA_SH" "remotion-best-practices" \
  "Remotion installed-skill dir name referenced"

# ---------------------------------------------------------------------------
# Safety invariants on the whisper-cpp build-from-source branch.
# The Linux branch shells out to cmake + g++ and clones into /tmp. Regressions
# there have historically orphaned build dirs; guard against both.
# ---------------------------------------------------------------------------
assert_contains "$MEDIA_SH" "ggerganov/whisper.cpp" \
  "whisper-cpp upstream referenced"
assert_contains "$MEDIA_SH" 're:rm -rf[[:space:]]+/tmp/whisper-cpp-build' \
  "whisper-cpp build tempdir cleaned up after build"

# ---------------------------------------------------------------------------
# Fail-safe shell hygiene.
# ---------------------------------------------------------------------------
assert_contains "$MEDIA_SH" 're:^set -euo pipefail' \
  "media/install.sh uses strict mode (set -euo pipefail)"
assert_contains "$MEDIA_SH" "soft_fail" \
  "media/install.sh defines soft_fail helper (non-fatal warnings)"

# ---------------------------------------------------------------------------
# Behavioral probe: install_youtube_transcript idempotency.
# ---------------------------------------------------------------------------
TMPROOT="$(mktemp -d -t cm-media-XXXXXX)"
cleanup() {
  if [[ -n "${TMPROOT:-}" && ( "$TMPROOT" == /tmp/* || "$TMPROOT" == /var/folders/* ) ]]; then
    rm -rf "$TMPROOT"
  fi
}
trap cleanup EXIT

MOCK_BIN="$TMPROOT/mock-bin"
CALL_LOG="$TMPROOT/claude-calls.log"
MCP_STATE="$TMPROOT/mcp-state"
mkdir -p "$MOCK_BIN"
: > "$CALL_LOG"
echo "youtube-transcript: npx -y @kimtaeyoon83/mcp-server-youtube-transcript" > "$MCP_STATE"

cat > "$MOCK_BIN/claude" <<SHIM
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$CALL_LOG"
case "\$1" in
  --version) echo "2.1.0 (Claude Code)"; exit 0 ;;
  mcp)
    case "\$2" in
      list) cat "$MCP_STATE"; exit 0 ;;
      add)  echo "added: \$*" >> "$MCP_STATE"; exit 0 ;;
    esac ;;
esac
exit 0
SHIM
chmod +x "$MOCK_BIN/claude"

PROBE="$TMPROOT/probe.sh"
cat > "$PROBE" <<'P'
#!/usr/bin/env bash
# shellcheck disable=SC1090
main() { :; }
# media/install.sh uses `set -euo pipefail`; we need to allow the function
# to return from sourcing without triggering -e on the `main` no-op above.
set +e
source "$1"
install_youtube_transcript
P
chmod +x "$PROBE"

set +e
OUT="$(PATH="$MOCK_BIN:$PATH" bash "$PROBE" "$MEDIA_SH" 2>&1)"
RC=$?
set -e 2>/dev/null || true

assert_eq "$RC" "0" "install_youtube_transcript exits 0 when already configured"
if grep -q "mcp add.*youtube-transcript" "$CALL_LOG"; then
  _fail "install_youtube_transcript re-added despite idempotency guard"
else
  _pass "install_youtube_transcript skipped 'mcp add' when present"
fi
if echo "$OUT" | grep -qi 'already installed\|already configured'; then
  _pass "install_youtube_transcript logs 'already installed'"
else
  _fail "install_youtube_transcript missing 'already installed' log"
fi

assert_report
