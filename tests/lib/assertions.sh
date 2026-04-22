#!/usr/bin/env bash
# tests/lib/assertions.sh
# Shared assertion helpers for the creativity-maxxing test harness.
# Pure bash, no external runners. macOS + Linux compatible.

# Guard against double-sourcing.
if [[ -n "${__CM_ASSERTIONS_SH_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
__CM_ASSERTIONS_SH_LOADED=1

: "${PASS_COUNT:=0}"
: "${FAIL_COUNT:=0}"
: "${CURRENT_TEST_NAME:=unknown}"
: "${FAIL_MESSAGES:=}"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  _C_RED=$'\033[0;31m'
  _C_GREEN=$'\033[0;32m'
  _C_YELLOW=$'\033[0;33m'
  _C_BLUE=$'\033[0;34m'
  _C_DIM=$'\033[2m'
  _C_BOLD=$'\033[1m'
  _C_RESET=$'\033[0m'
else
  _C_RED=""
  _C_GREEN=""
  _C_YELLOW=""
  _C_BLUE=""
  _C_DIM=""
  _C_BOLD=""
  _C_RESET=""
fi

assert_reset() {
  PASS_COUNT=0
  FAIL_COUNT=0
  FAIL_MESSAGES=""
  CURRENT_TEST_NAME="${1:-$(basename "${BASH_SOURCE[1]:-unknown}")}"
}

_pass() {
  local msg="${1:-}"
  PASS_COUNT=$((PASS_COUNT + 1))
  if [[ "${VERBOSE:-0}" == "1" ]]; then
    printf "  %sPASS%s %s\n" "${_C_GREEN}" "${_C_RESET}" "${msg}"
  fi
}

_fail() {
  local msg="${1:-}"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  FAIL_MESSAGES+="  - ${msg}\n"
  printf "  %sFAIL%s %s\n" "${_C_RED}" "${_C_RESET}" "${msg}" 1>&2
}

# assert_dir <path> [message]
assert_dir() {
  local path="$1"
  local msg="${2:-directory should exist: $path}"
  if [[ -d "$path" ]]; then
    _pass "$msg"
  else
    _fail "$msg (got: not a directory)"
  fi
}

# assert_file <path> [message]
assert_file() {
  local path="$1"
  local msg="${2:-file should exist: $path}"
  if [[ -f "$path" ]]; then
    _pass "$msg"
  else
    _fail "$msg (got: not a file)"
  fi
}

# assert_contains <path> <pattern> [message]
# Prefix pattern with "re:" to treat as ERE regex.
assert_contains() {
  local path="$1"
  local pattern="$2"
  local msg="${3:-file $path should contain: $pattern}"
  if [[ ! -f "$path" ]]; then
    _fail "$msg (file missing: $path)"
    return
  fi
  if [[ "$pattern" == re:* ]]; then
    local re="${pattern#re:}"
    if grep -qE "$re" "$path"; then
      _pass "$msg"
    else
      _fail "$msg"
    fi
  else
    if grep -qF -- "$pattern" "$path"; then
      _pass "$msg"
    else
      _fail "$msg"
    fi
  fi
}

# assert_not_contains <path> <pattern> [message]
assert_not_contains() {
  local path="$1"
  local pattern="$2"
  local msg="${3:-file $path should NOT contain: $pattern}"
  if [[ ! -f "$path" ]]; then
    _fail "$msg (file missing: $path)"
    return
  fi
  if [[ "$pattern" == re:* ]]; then
    local re="${pattern#re:}"
    if grep -qE "$re" "$path"; then
      _fail "$msg"
    else
      _pass "$msg"
    fi
  else
    if grep -qF -- "$pattern" "$path"; then
      _fail "$msg"
    else
      _pass "$msg"
    fi
  fi
}

# assert_eq <actual> <expected> [message]
assert_eq() {
  local actual="$1"
  local expected="$2"
  local msg="${3:-expected '$expected', got '$actual'}"
  if [[ "$actual" == "$expected" ]]; then
    _pass "$msg"
  else
    _fail "$msg (actual='$actual')"
  fi
}

# assert_command_succeeds "cmd string" [message]
assert_command_succeeds() {
  local cmd="$1"
  local msg="${2:-command should succeed: $cmd}"
  local out rc
  out="$(bash -c "$cmd" 2>&1)"
  rc=$?
  if [[ $rc -eq 0 ]]; then
    _pass "$msg"
  else
    _fail "$msg (rc=$rc, output: ${out:0:200})"
  fi
}

# assert_command_fails "cmd string" [message]
assert_command_fails() {
  local cmd="$1"
  local msg="${2:-command should fail: $cmd}"
  local out rc
  out="$(bash -c "$cmd" 2>&1)"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    _pass "$msg (rc=$rc)"
  else
    _fail "$msg (unexpectedly rc=0, output: ${out:0:200})"
  fi
}

# assert_shellcheck_clean <script> [message]
# Skips (_pass) if shellcheck is not installed — not every contributor has it.
assert_shellcheck_clean() {
  local path="$1"
  local msg="${2:-shellcheck clean: $path}"
  if ! command -v shellcheck >/dev/null 2>&1; then
    _pass "$msg (shellcheck not installed — skipped)"
    return
  fi
  if [[ ! -f "$path" ]]; then
    _fail "$msg (file missing)"
    return
  fi
  local out rc
  out="$(shellcheck -S warning "$path" 2>&1)"
  rc=$?
  if [[ $rc -eq 0 ]]; then
    _pass "$msg"
  else
    _fail "$msg (output: ${out:0:400})"
  fi
}

# assert_report
# Prints final pass/fail summary, returns 0 if all pass.
assert_report() {
  local total=$((PASS_COUNT + FAIL_COUNT))
  local label="${CURRENT_TEST_NAME}"
  echo
  if [[ $FAIL_COUNT -eq 0 && $PASS_COUNT -gt 0 ]]; then
    printf "%s%s[%s]%s %sPASS%s %d/%d\n" \
      "${_C_BOLD}" "${_C_GREEN}" "$label" "${_C_RESET}" \
      "${_C_GREEN}" "${_C_RESET}" "$PASS_COUNT" "$total"
    return 0
  elif [[ $total -eq 0 ]]; then
    printf "%s[%s]%s %sNO ASSERTIONS%s\n" \
      "${_C_YELLOW}" "$label" "${_C_RESET}" "${_C_YELLOW}" "${_C_RESET}"
    return 1
  else
    printf "%s%s[%s]%s %sFAIL%s %d/%d passed, %d failed\n" \
      "${_C_BOLD}" "${_C_RED}" "$label" "${_C_RESET}" \
      "${_C_RED}" "${_C_RESET}" "$PASS_COUNT" "$total" "$FAIL_COUNT"
    if [[ -n "$FAIL_MESSAGES" ]]; then
      printf "%s" "$FAIL_MESSAGES" | sed 's/^/  /'
    fi
    return 1
  fi
}
