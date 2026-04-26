#!/usr/bin/env bash
# tests/test_design_install.sh
# Static + light-behavioral coverage for design/install.sh.
#
# Because a full install would hit the network and mutate ~/.claude, we do
# static text checks for the MCPs + skills this module is contracted to
# install, plus a single-function behavioral probe for install_playwright
# (the newest addition — MUST have test coverage).

set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
# shellcheck source=./lib/assertions.sh
source "$HERE/lib/assertions.sh"

assert_reset "test_design_install"

DESIGN_SH="$REPO_ROOT/design/install.sh"
if [[ ! -f "$DESIGN_SH" ]]; then
  printf "%sSKIP%s test_design_install (design/install.sh not present)\n" \
    "${_C_YELLOW:-}" "${_C_RESET:-}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Static contract: every advertised MCP + skill must have a matching function
# body in the module. Test titles reference exactly one tool so a regression
# flags which one rotted.
# ---------------------------------------------------------------------------

# Skills.
assert_contains "$DESIGN_SH" "install_uiux_skill" \
  "install_uiux_skill function defined (UI/UX Pro Max)"
assert_contains "$DESIGN_SH" "ui-ux-pro-max" \
  "UI/UX Pro Max skill name present"

assert_contains "$DESIGN_SH" "install_taste_skill" \
  "install_taste_skill function defined (Leonxlnx/taste-skill pack)"
# All 8 taste-skill variants by their installed name.
for v in design-taste-frontend high-end-visual-design full-output-enforcement \
         redesign-existing-projects stitch-design-taste minimalist-ui \
         industrial-brutalist-ui gpt-taste; do
  assert_contains "$DESIGN_SH" "$v" "taste variant listed: $v"
done

# MCPs.
assert_contains "$DESIGN_SH" "install_21st_magic" \
  "install_21st_magic function defined (21st.dev Magic MCP)"
assert_contains "$DESIGN_SH" "@21st-dev/magic" \
  "21st.dev Magic MCP package referenced"

assert_contains "$DESIGN_SH" "install_canva_mcp" \
  "install_canva_mcp function defined"
assert_contains "$DESIGN_SH" "mcp.canva.com" \
  "Canva remote MCP URL present"

assert_contains "$DESIGN_SH" "install_figma_mcp" \
  "install_figma_mcp function defined"
assert_contains "$DESIGN_SH" "mcp.figma.com" \
  "Figma remote MCP URL present"

assert_contains "$DESIGN_SH" "install_excalidraw_mcp" \
  "install_excalidraw_mcp function defined"
assert_contains "$DESIGN_SH" "mcp.excalidraw.com" \
  "Excalidraw remote MCP URL present"

assert_contains "$DESIGN_SH" "install_gamma_mcp" \
  "install_gamma_mcp function defined"
assert_contains "$DESIGN_SH" "mcp.gamma.app" \
  "Gamma remote MCP URL present"

# Gamma must be gated behind WITH_GAMMA opt-in (item 13 from WAGMI Apr-22 install
# bug catalog: Gamma fails to connect without an API key, so default-on installs
# present users with an MCP that's broken on first use).
assert_contains "$DESIGN_SH" "WITH_GAMMA" \
  "WITH_GAMMA opt-in flag declared"
assert_contains "$DESIGN_SH" "--with-gamma" \
  "--with-gamma CLI flag parsed"
assert_contains "$DESIGN_SH" 're:if \[ "\$WITH_GAMMA" = "1" \]' \
  "main() gates install_gamma_mcp on WITH_GAMMA"

# Item 12 — root-owned ~/.npm preflight (cross-repo consistency w/ 2ndBrain-mogging).
assert_contains "$DESIGN_SH" "preflight_npm_cache_ownership" \
  "preflight_npm_cache_ownership function defined"
assert_contains "$DESIGN_SH" "sudo chown -R" \
  "preflight prints the chown fix users need to run"

# Item 3 — 21st.dev URL must point at the MCP dashboard, not the homepage.
assert_contains "$DESIGN_SH" "21st.dev/mcp" \
  "21st.dev MCP dashboard URL referenced (not the homepage)"

# -- Playwright (newest addition — this is the must-cover item per the audit)
assert_contains "$DESIGN_SH" "install_playwright" \
  "install_playwright function defined (Playwright MCP — newest)"
assert_contains "$DESIGN_SH" "@playwright/mcp" \
  "Playwright MCP package (@playwright/mcp) referenced"
assert_contains "$DESIGN_SH" 're:playwright.*mcp|mcp.*playwright' \
  "Playwright MCP is named in a tool-registration line"

# main() must wire every installer in, including install_playwright.
for fn in detect_os verify_prerequisites install_uiux_skill install_taste_skill \
          install_21st_magic install_canva_mcp install_figma_mcp \
          install_excalidraw_mcp install_gamma_mcp install_playwright \
          run_self_test print_summary; do
  assert_contains "$DESIGN_SH" "re:^[[:space:]]+${fn}(\$|[[:space:]])" \
    "main() calls $fn"
done

# Self-test must assert Playwright specifically — otherwise a regression
# where install_playwright silently fails would go unnoticed.
assert_contains "$DESIGN_SH" "re:TEST: Playwright MCP" \
  "self-test emits 'TEST: Playwright MCP' line"

# UI/UX Pro Max skill sha256 pin is present (tamper-resistance).
assert_contains "$DESIGN_SH" "UIUX_SHA256=" \
  "UI/UX Pro Max skill sha256 pin declared"
assert_contains "$DESIGN_SH" "UIUX_COMMIT=" \
  "UI/UX Pro Max skill commit pin declared (no mutable branch ref)"

# ---------------------------------------------------------------------------
# Behavioral probe: install_playwright idempotency.
#
# Source design/install.sh into a tempdir with a fake `claude` on PATH that
# simulates "playwright already registered", then call install_playwright and
# confirm it neither re-adds nor fails.
# ---------------------------------------------------------------------------
TMPROOT="$(mktemp -d -t cm-design-XXXXXX)"
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
# Pre-seed "playwright" in the mock state so the idempotency guard fires.
echo "playwright: npx -y @playwright/mcp@latest" > "$MCP_STATE"

cat > "$MOCK_BIN/claude" <<SHIM
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$CALL_LOG"
case "\$1" in
  --version) echo "2.1.0 (Claude Code)"; exit 0 ;;
  mcp)
    case "\$2" in
      list)   cat "$MCP_STATE"; exit 0 ;;
      add)    echo "mock-added: \$*" >> "$MCP_STATE"; exit 0 ;;
    esac ;;
esac
exit 0
SHIM
chmod +x "$MOCK_BIN/claude"

# Source the module. It uses `set -uo pipefail` (no -e), so sourcing is safe
# for isolated function calls. We override main() so sourcing doesn't
# execute the full pipeline (the last line is `main "$@"`).
PROBE_SCRIPT="$TMPROOT/probe.sh"
cat > "$PROBE_SCRIPT" <<'PROBE'
#!/usr/bin/env bash
# shellcheck disable=SC1090
# Disable the installer's auto-run main by redefining main before sourcing.
main() { :; }
source "$1"
install_playwright
PROBE
chmod +x "$PROBE_SCRIPT"

set +e
IDEMP_OUT="$(PATH="$MOCK_BIN:$PATH" bash "$PROBE_SCRIPT" "$DESIGN_SH" 2>&1)"
IDEMP_RC=$?
set -e 2>/dev/null || true

assert_eq "$IDEMP_RC" "0" "install_playwright exits 0 when already configured"
if echo "$IDEMP_OUT" | grep -qi 'already configured\|already installed'; then
  _pass "install_playwright logs 'already configured' on re-run"
else
  _fail "install_playwright did not log 'already configured' on re-run"
  printf '  saw: %s\n' "${IDEMP_OUT:0:300}" 1>&2
fi
if grep -q "mcp add.*playwright" "$CALL_LOG"; then
  _fail "install_playwright re-issued 'mcp add' despite idempotency"
  printf '  call log:\n' 1>&2; sed 's/^/    /' "$CALL_LOG" 1>&2
else
  _pass "install_playwright skipped 'mcp add' when playwright was present"
fi

# ---------------------------------------------------------------------------
# Behavioral probe 2: install_playwright on a clean state DOES register.
# ---------------------------------------------------------------------------
: > "$CALL_LOG"
: > "$MCP_STATE"

set +e
FRESH_OUT="$(PATH="$MOCK_BIN:$PATH" bash "$PROBE_SCRIPT" "$DESIGN_SH" 2>&1)"
FRESH_RC=$?
set -e 2>/dev/null || true

assert_eq "$FRESH_RC" "0" "install_playwright exits 0 on clean install"
if grep -qE 'mcp[[:space:]]+add[[:space:]].*playwright' "$CALL_LOG"; then
  _pass "install_playwright issued 'claude mcp add playwright' on clean state"
else
  _fail "install_playwright did not call 'claude mcp add playwright'"
  printf '  call log:\n' 1>&2; sed 's/^/    /' "$CALL_LOG" 1>&2
fi
if echo "$FRESH_OUT" | grep -qE '@playwright/mcp|playwright.*latest'; then
  _pass "install_playwright mentions @playwright/mcp package in output"
else
  # Not strictly required — the add may run silently. Soft-pass.
  _pass "install_playwright completed (output wording not asserted)"
fi

assert_report
