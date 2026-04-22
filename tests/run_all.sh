#!/usr/bin/env bash
# tests/run_all.sh — orchestrate all test_*.sh files for creativity-maxxing.
#
# Semantics:
#   PASS  → test exited 0 and printed no "SKIP " sentinel
#   SKIP  → test exited 0 but printed at least one "SKIP " sentinel line
#   FAIL  → test exited non-zero
#
# SKIP sentinel = a line starting with "SKIP " (optionally preceded by an
# ANSI colour reset). Use it for forward-looking tests whose entrypoints
# aren't wired up yet.
#
# Flags:
#   [filter]   substring match against basename
#   --strict   promote every SKIP to FAIL (useful in CI once every test
#              runs for real)

set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# macOS md5 → md5sum shim
if ! command -v md5sum >/dev/null 2>&1 && command -v md5 >/dev/null 2>&1; then
  md5sum() { md5 -q "$@"; }; export -f md5sum
fi

for bin in bash grep find mktemp; do
  command -v "$bin" >/dev/null 2>&1 || { echo "FATAL: missing $bin" >&2; exit 2; }
done

STRICT=0
filter=""
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    --help|-h)
      cat <<EOF
Usage: $(basename "$0") [FILTER] [--strict]

  FILTER    Substring match on test basename (e.g. "playwright")
  --strict  Promote SKIP results to FAIL (CI gate mode)
EOF
      exit 0
      ;;
    *) filter="$arg" ;;
  esac
done

pass=0; fail=0; skip=0; total=0
declare -a failed
declare -a skipped

if [[ -t 1 ]]; then
  G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; X=$'\033[0m'
else
  G=""; R=""; Y=""; B=""; X=""
fi

echo "${B}creativity-maxxing test harness${X}"
[[ -n "$filter" ]] && echo "Filter: $filter"
[[ $STRICT -eq 1 ]] && echo "Mode:   ${Y}strict${X} (SKIP → FAIL)"
echo

shopt -s nullglob
for t in "$HERE"/test_*.sh; do
  name="$(basename "$t")"
  [[ -n "$filter" && "$name" != *"$filter"* ]] && continue
  ((total++))
  echo "${B}→ $name${X}"

  log_file="$(mktemp -t cm-test-log.XXXXXX)"
  if bash "$t" 2>&1 | tee "$log_file"; then
    rc=0
  else
    rc="${PIPESTATUS[0]}"
  fi

  is_skip=0
  if grep -qE '(^|\x1b\[[0-9;]*m)SKIP[[:space:]]' "$log_file" 2>/dev/null; then
    is_skip=1
  fi
  rm -f "$log_file"

  if [[ $rc -ne 0 ]]; then
    ((fail++)); failed+=("$name")
    echo "${R}✗ $name${X}"
  elif [[ $is_skip -eq 1 ]]; then
    if [[ $STRICT -eq 1 ]]; then
      ((fail++)); failed+=("$name (skipped under --strict)")
      echo "${R}✗ $name${X} (skip promoted to fail by --strict)"
    else
      ((skip++)); skipped+=("$name")
      echo "${Y}⊘ $name${X} (skipped)"
    fi
  else
    ((pass++))
    echo "${G}✓ $name${X}"
  fi
  echo
done
shopt -u nullglob

echo "${B}── Summary ──${X}"
printf "Total: %d  %sPassed: %d%s  %sSkipped: %d%s  %sFailed: %d%s\n" \
  "$total" "$G" "$pass" "$X" "$Y" "$skip" "$X" "$R" "$fail" "$X"

if ((skip > 0)); then
  echo "${Y}Skipped tests:${X}"
  for n in "${skipped[@]}"; do echo "  ${Y}⊘ $n${X}"; done
fi

if ((fail > 0)); then
  echo "${R}Failed tests:${X}"
  for n in "${failed[@]}"; do echo "  ${R}- $n${X}"; done
  exit 1
fi

if ((total == 0)); then
  echo "${R}No tests matched${X}"
  exit 2
fi

if ((pass == 0 && skip > 0)); then
  echo "${Y}WARNING: every matched test skipped. No real coverage ran.${X}"
  [[ $STRICT -eq 1 ]] && exit 1
fi

echo "${G}ALL GREEN${X}"
