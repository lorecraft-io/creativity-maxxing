#!/usr/bin/env bash
# tests/test_update.sh
# Verifies update.sh:
#   - clones into a mktemp dir
#   - traps EXIT to rm -rf that dir (cleanup regardless of success)
#   - re-runs design/install.sh AND media/install.sh (idempotent)
#   - points at the lorecraft-io/creativity-maxxing upstream

set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
# shellcheck source=./lib/assertions.sh
source "$HERE/lib/assertions.sh"

assert_reset "test_update"

UPDATE_SH="$REPO_ROOT/update.sh"
if [[ ! -f "$UPDATE_SH" ]]; then
  printf "%sSKIP%s test_update (update.sh not present)\n" \
    "${_C_YELLOW:-}" "${_C_RESET:-}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Static invariants.
# ---------------------------------------------------------------------------
assert_contains "$UPDATE_SH" 're:^set -euo pipefail' \
  "update.sh uses strict mode"
assert_contains "$UPDATE_SH" 're:mktemp -d' \
  "update.sh creates a tempdir via 'mktemp -d'"
assert_contains "$UPDATE_SH" 're:trap .*rm -rf.*EXIT' \
  "update.sh installs a trap EXIT that 'rm -rf's the tempdir"
assert_contains "$UPDATE_SH" "lorecraft-io/creativity-maxxing" \
  "update.sh clones from lorecraft-io/creativity-maxxing"
assert_contains "$UPDATE_SH" "design/install.sh" \
  "update.sh re-runs design/install.sh"
assert_contains "$UPDATE_SH" "media/install.sh" \
  "update.sh re-runs media/install.sh"
assert_contains "$UPDATE_SH" 're:git clone.*--depth 1' \
  "update.sh shallow-clones (--depth 1) — no history bloat"

# Banner mentions the Playwright MCP so users know what the newest update
# gives them (audit requirement: Playwright is the newest addition).
assert_contains "$UPDATE_SH" "Playwright" \
  "update.sh banner mentions Playwright MCP (newest addition)"

# ---------------------------------------------------------------------------
# Behavioral probe: run update.sh with a mocked git that clones a prepared
# local sandbox into the tempdir instead of hitting the network. Verify the
# tempdir gets cleaned on exit.
# ---------------------------------------------------------------------------
TMPROOT="$(mktemp -d -t cm-update-XXXXXX)"
cleanup() {
  if [[ -n "${TMPROOT:-}" && ( "$TMPROOT" == /tmp/* || "$TMPROOT" == /var/folders/* ) ]]; then
    rm -rf "$TMPROOT"
  fi
}
trap cleanup EXIT

# Prepare the fake upstream — two shim installers that just record a call.
UPSTREAM="$TMPROOT/upstream"
mkdir -p "$UPSTREAM/design" "$UPSTREAM/media"
CALL_LOG="$TMPROOT/calls.log"
: > "$CALL_LOG"
cat > "$UPSTREAM/design/install.sh" <<SHIM
#!/usr/bin/env bash
echo "design-updated" >> "$CALL_LOG"
exit 0
SHIM
cat > "$UPSTREAM/media/install.sh" <<SHIM
#!/usr/bin/env bash
echo "media-updated" >> "$CALL_LOG"
exit 0
SHIM
chmod +x "$UPSTREAM/design/install.sh" "$UPSTREAM/media/install.sh"

# Mock git — swallow the --depth 1 args, just `cp -R` the upstream sandbox
# into the target dir so update.sh's subsequent `bash "$_TMPDIR/...` works.
MOCK_BIN="$TMPROOT/mock-bin"
mkdir -p "$MOCK_BIN"
cat > "$MOCK_BIN/git" <<SHIM
#!/usr/bin/env bash
# We only stub 'git clone' here; everything else defers to the real git.
if [[ "\$1" == "clone" ]]; then
  dest=""
  for a in "\$@"; do dest="\$a"; done
  cp -R "$UPSTREAM/." "\$dest/"
  exit 0
fi
exec /usr/bin/git "\$@"
SHIM
chmod +x "$MOCK_BIN/git"

# Run update.sh with instrumentation: we want to catch the tempdir it picks
# so we can verify cleanup after exit. We wrap update.sh in a probe that
# traces `mktemp -d` via TMPDIR.
PROBE_TMPDIR="$TMPROOT/update-tmproot"
mkdir -p "$PROBE_TMPDIR"

set +e
UPDATE_OUT="$(PATH="$MOCK_BIN:$PATH" TMPDIR="$PROBE_TMPDIR" \
  bash "$UPDATE_SH" 2>&1)"
UPDATE_RC=$?
set -e 2>/dev/null || true

assert_eq "$UPDATE_RC" "0" "update.sh exits 0 against mocked git + module installers"

if grep -q '^design-updated' "$CALL_LOG"; then
  _pass "update.sh re-ran design/install.sh"
else
  _fail "update.sh did not re-run design/install.sh"
  printf '  call log:\n' 1>&2; sed 's/^/    /' "$CALL_LOG" 1>&2
fi
if grep -q '^media-updated' "$CALL_LOG"; then
  _pass "update.sh re-ran media/install.sh"
else
  _fail "update.sh did not re-run media/install.sh"
fi

# Tempdir cleanup: update.sh's trap EXIT should have removed everything
# under $PROBE_TMPDIR that looks like a tmp.XXXXXX mktemp output. We scan
# for any dir matching the default `tmp.*` or `*.XXXXXX` shape.
LEAKED="$(find "$PROBE_TMPDIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
assert_eq "$LEAKED" "0" "update.sh's trap EXIT cleaned up its mktemp dir"

# Update banner present.
if echo "$UPDATE_OUT" | grep -qi 'creativity-maxxing.*update'; then
  _pass "update.sh prints 'creativity-maxxing — Update' banner"
else
  _fail "update.sh missing update banner"
fi

assert_report
