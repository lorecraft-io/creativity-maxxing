#!/usr/bin/env bash
# tests/test_root_install.sh
# Verifies the root install.sh correctly delegates to design/ and media/
# and honors the $MARKER file for idempotency.
#
# Strategy:
#   - Replace the child module installers with no-op shims that record a
#     call tag in a log file.
#   - Run install.sh with HOME pointing at a tempdir so $MARKER lives there.
#   - Confirm both shims got called, $MARKER got written, and a second run
#     short-circuits.

set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
# shellcheck source=./lib/assertions.sh
source "$HERE/lib/assertions.sh"

assert_reset "test_root_install"

TMPROOT="$(mktemp -d -t cm-root-install-XXXXXX)"
cleanup() {
  if [[ -n "${TMPROOT:-}" && ( "$TMPROOT" == /tmp/* || "$TMPROOT" == /var/folders/* ) ]]; then
    rm -rf "$TMPROOT"
  fi
}
trap cleanup EXIT

ROOT_INSTALL="$REPO_ROOT/install.sh"
if [[ ! -f "$ROOT_INSTALL" ]]; then
  printf "%sSKIP%s test_root_install (install.sh not present)\n" \
    "${_C_YELLOW:-}" "${_C_RESET:-}"
  exit 0
fi

# Copy the full repo to a sandbox so we can safely stub design/install.sh and
# media/install.sh without touching the user's tree.
SANDBOX="$TMPROOT/repo"
mkdir -p "$SANDBOX"
cp -R "$REPO_ROOT/install.sh" "$SANDBOX/install.sh"
mkdir -p "$SANDBOX/design" "$SANDBOX/media"

CALL_LOG="$TMPROOT/calls.log"
: > "$CALL_LOG"

cat > "$SANDBOX/design/install.sh" <<SHIM
#!/usr/bin/env bash
echo "design-shim: \$*" >> "$CALL_LOG"
exit 0
SHIM
cat > "$SANDBOX/media/install.sh" <<SHIM
#!/usr/bin/env bash
echo "media-shim: \$*" >> "$CALL_LOG"
exit 0
SHIM
chmod +x "$SANDBOX/design/install.sh" "$SANDBOX/media/install.sh"

FAKE_HOME="$TMPROOT/home"
mkdir -p "$FAKE_HOME/.claude/skills"

# Stub `claude` in PATH so the prerequisites check passes deterministically.
MOCK_BIN="$TMPROOT/mock-bin"
mkdir -p "$MOCK_BIN"
cat > "$MOCK_BIN/claude" <<'SHIM'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
  echo "2.1.0 (Claude Code)"
fi
exit 0
SHIM
chmod +x "$MOCK_BIN/claude"

run_root() {
  PATH="$MOCK_BIN:$PATH" HOME="$FAKE_HOME" \
    bash "$SANDBOX/install.sh" 2>&1
}

# ---------------------------------------------------------------------------
# Case 1: first run calls both modules and writes the marker.
# ---------------------------------------------------------------------------
FIRST_OUT="$(run_root || true)"
FIRST_RC=$?
assert_eq "$FIRST_RC" "0" "root install.sh exits 0 on first run"

if grep -q '^design-shim:' "$CALL_LOG"; then
  _pass "root install.sh delegated to design/install.sh"
else
  _fail "root install.sh did not call design/install.sh"
  printf '  call log:\n' 1>&2; sed 's/^/    /' "$CALL_LOG" 1>&2
fi
if grep -q '^media-shim:' "$CALL_LOG"; then
  _pass "root install.sh delegated to media/install.sh"
else
  _fail "root install.sh did not call media/install.sh"
fi

MARKER="$FAKE_HOME/.claude/.creativity-maxxing-installed"
assert_file "$MARKER" "marker file written at \$HOME/.claude/.creativity-maxxing-installed"

# Banner text sanity.
if echo "$FIRST_OUT" | grep -q 'creativity-maxxing'; then
  _pass "root install.sh prints 'creativity-maxxing' banner"
else
  _fail "root install.sh banner missing 'creativity-maxxing' branding"
fi
if echo "$FIRST_OUT" | grep -qi 'playwright'; then
  _pass "root install.sh banner lists Playwright (newest design MCP)"
else
  _fail "root install.sh banner did not mention Playwright"
fi

# ---------------------------------------------------------------------------
# Case 2: re-run with marker present → short-circuits, neither shim called.
# ---------------------------------------------------------------------------
: > "$CALL_LOG"
SECOND_OUT="$(run_root || true)"
SECOND_RC=$?
assert_eq "$SECOND_RC" "0" "root install.sh exits 0 on second run (already installed)"

if [[ -s "$CALL_LOG" ]]; then
  _fail "second run still invoked module installers"
  printf '  call log:\n' 1>&2; sed 's/^/    /' "$CALL_LOG" 1>&2
else
  _pass "second run short-circuited — no module installers invoked"
fi
if echo "$SECOND_OUT" | grep -qi 'already installed'; then
  _pass "second run emits 'already installed' guidance"
else
  _fail "second run missing 'already installed' message"
fi

# ---------------------------------------------------------------------------
# Case 3: missing claude → prereq check fails fast.
# ---------------------------------------------------------------------------
rm -f "$MARKER"
PATH_NO_CLAUDE="$TMPROOT/path-no-claude"
mkdir -p "$PATH_NO_CLAUDE"
# Copy only the bare essentials (not claude).
for t in bash grep find mktemp git curl awk sed tr cp mv rm mkdir chmod touch dirname basename uname head tail; do
  if command -v "$t" >/dev/null 2>&1; then
    ln -s "$(command -v "$t")" "$PATH_NO_CLAUDE/$t" 2>/dev/null || true
  fi
done

: > "$CALL_LOG"
set +e
NOCLAUDE_OUT="$(PATH="$PATH_NO_CLAUDE" HOME="$FAKE_HOME" \
  bash "$SANDBOX/install.sh" 2>&1)"
NOCLAUDE_RC=$?
set -e 2>/dev/null || true

if [[ "$NOCLAUDE_RC" -ne 0 ]]; then
  _pass "root install.sh exits non-zero when claude is absent"
else
  _fail "root install.sh exited 0 despite claude missing"
fi
if echo "$NOCLAUDE_OUT" | grep -qi 'cli-maxxing\|Claude Code not found'; then
  _pass "missing-claude message points at cli-maxxing"
else
  _fail "missing-claude message did not point at cli-maxxing"
  printf '  saw: %s\n' "${NOCLAUDE_OUT:0:300}" 1>&2
fi
if [[ ! -s "$CALL_LOG" ]]; then
  _pass "module installers NOT invoked when claude is missing"
else
  _fail "module installers still ran despite missing claude"
fi

# ---------------------------------------------------------------------------
# Case 4: script structure invariants.
# ---------------------------------------------------------------------------
assert_contains "$ROOT_INSTALL" 're:^set -euo pipefail' \
  "root install.sh uses 'set -euo pipefail' for strict mode"
assert_contains "$ROOT_INSTALL" "design/install.sh" \
  "root install.sh references design/install.sh"
assert_contains "$ROOT_INSTALL" "media/install.sh" \
  "root install.sh references media/install.sh"
assert_contains "$ROOT_INSTALL" ".creativity-maxxing-installed" \
  "root install.sh uses the canonical marker filename"

assert_report
