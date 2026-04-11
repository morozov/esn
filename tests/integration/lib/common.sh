#!/usr/bin/env bash
# lib/common.sh — Shared helpers for ESN end-to-end tests.
# Source this file from every test case script and from run_tests.sh.

set -euo pipefail

_COMMON_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_COMMON_SELF_DIR/timing.sh"

[[ -n "${_COMMON_LOADED:-}" ]] && return 0
_COMMON_LOADED=1

# ---------------------------------------------------------------------------
# Project paths
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/../.." && pwd)"

FIXTURES_DIR="$PROJECT_ROOT/tests/fixtures"
APP_BIN="$PROJECT_ROOT/bin/esn"

# ---------------------------------------------------------------------------
# Output directory
# ---------------------------------------------------------------------------

OUT_DIR="${OUT_DIR:-$TEST_DIR/results/run}"

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------

_PASS=0
_FAIL=0

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'
  YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RESET='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; CYAN=''; RESET=''
fi

log_pass() {
  local test_id="$1"; shift
  (( _PASS++ )) || true
  printf "${GREEN}  PASS${RESET}  [%s] %s\n" "$test_id" "$*"
}

log_fail() {
  local test_id="$1"; shift
  (( _FAIL++ )) || true
  printf "${RED}  FAIL${RESET}  [%s] %s\n" "$test_id" "$*"
}

log_skip() {
  local test_id="$1"; shift
  printf "${YELLOW}  SKIP${RESET}  [%s] %s\n" "$test_id" "$*"
}

log_info() {
  printf "${CYAN}  INFO${RESET}  %s\n" "$*"
}

log_step() {
  local step_num="$1"; shift
  printf "\n    Step %s: %s\n" "$step_num" "$*"
}

step() { local num="$1"; shift; log_step "$num" "$*"; }

# ---------------------------------------------------------------------------
# _maybe_dump TEST_ID
# Write screen content to OUT_DIR when DUMP=1.
# ---------------------------------------------------------------------------
_maybe_dump() {
  local test_id="$1"
  [[ "${DUMP:-0}" != "1" ]] && return 0
  mkdir -p "$OUT_DIR"
  screen_text > "$OUT_DIR/${test_id}.txt" 2>/dev/null || true
  screen_ansi > "$OUT_DIR/${test_id}.ansi" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# close_dialog TEXT
#
# Close the current dialog with Escape and wait for TEXT to disappear.
# ---------------------------------------------------------------------------
close_dialog() {
  local text="$1"
  send_key escape
  wait_for_no_text "$text"
}

# ---------------------------------------------------------------------------
# Polling helpers
# ---------------------------------------------------------------------------

# wait_for_text TEXT [TIMEOUT_MS]
# Poll the screen until TEXT appears or TIMEOUT_MS elapses (default 500).
# Returns 0 on success, 1 on timeout.
wait_for_text() {
  local text="$1" timeout_ms="${2:-500}"
  local elapsed=0 step=50
  while (( elapsed < timeout_ms )); do
    _screen_invalidate
    if screen_text | grep -qF "$text"; then
      return 0
    fi
    sleep "0.0${step}"
    elapsed=$(( elapsed + step ))
  done
  return 1
}

# wait_for_no_text TEXT [TIMEOUT_MS]
# Poll the screen until TEXT disappears or TIMEOUT_MS elapses (default 500).
# Returns 0 on success, 1 on timeout.
wait_for_no_text() {
  local text="$1" timeout_ms="${2:-500}"
  local elapsed=0 step=50
  while (( elapsed < timeout_ms )); do
    _screen_invalidate
    if ! screen_text | grep -qF "$text"; then
      return 0
    fi
    sleep "0.0${step}"
    elapsed=$(( elapsed + step ))
  done
  return 1
}

# ---------------------------------------------------------------------------
# Assertion functions
# ---------------------------------------------------------------------------

# assert_text_present TEST_ID TEXT [DESC]
assert_text_present() {
  local test_id="$1" text="$2"
  local desc="${3:-'$text' is present on screen}"
  if screen_text | grep -qF "$text"; then
    log_pass "$test_id" "$desc"
  else
    log_fail "$test_id" "$desc — '$text' not found on screen"
  fi
  _maybe_dump "$test_id"
  return 0
}

# assert_text_absent TEST_ID TEXT [DESC]
assert_text_absent() {
  local test_id="$1" text="$2"
  local desc="${3:-'$text' is absent from screen}"
  if screen_text | grep -qF "$text"; then
    log_fail "$test_id" "$desc — '$text' unexpectedly found on screen"
  else
    log_pass "$test_id" "$desc"
  fi
  _maybe_dump "$test_id"
  return 0
}

# assert_info_line TEST_ID EXPECTED [DESC]
# Passes when the right-trimmed info line 1 starts with EXPECTED (prefix match).
assert_info_line() {
  local test_id="$1" expected="$2"
  local desc="${3:-info line starts with '$expected'}"
  local actual
  actual=$(capture_info_line)
  if [[ "$actual" == "$expected"* ]]; then
    log_pass "$test_id" "$desc"
  else
    log_fail "$test_id" "$desc — expected prefix '$expected', got '$actual'"
  fi
  _maybe_dump "$test_id"
  return 0
}

# assert_rect_bg TEST_ID ROW COL HEIGHT WIDTH COLOR [DESC]
# Passes when every cell in the rectangle has the given background color.
assert_rect_bg() {
  local test_id="$1" row="$2" col="$3" height="$4" width="$5" color="$6"
  local desc="${7:-rect bg ($row,$col) ${height}x${width} is $color}"
  local grid actual fail_row="" fail_col="" fail_color=""
  grid=$(rect_bg "$row" "$col" "$height" "$width")
  local row_num=0
  while IFS= read -r line; do
    row_num=$(( row_num + 1 ))
    local col_num=0
    for actual in $line; do
      col_num=$(( col_num + 1 ))
      if [[ "$actual" != "$color" ]]; then
        fail_row=$(( row + row_num - 1 ))
        fail_col=$(( col + col_num - 1 ))
        fail_color="$actual"
        break 2
      fi
    done
  done <<< "$grid"
  if [[ -n "$fail_row" ]]; then
    log_fail "$test_id" \
      "$desc — row $fail_row col $fail_col: expected '$color', got '$fail_color'"
  else
    log_pass "$test_id" "$desc"
  fi
  _maybe_dump "$test_id"
  return 0
}

# assert_rect_fg TEST_ID ROW COL HEIGHT WIDTH COLOR [DESC]
# Passes when every cell in the rectangle has the given foreground color.
assert_rect_fg() {
  local test_id="$1" row="$2" col="$3" height="$4" width="$5" color="$6"
  local desc="${7:-rect fg ($row,$col) ${height}x${width} is $color}"
  local grid actual fail_row="" fail_col="" fail_color=""
  grid=$(rect_fg "$row" "$col" "$height" "$width")
  local row_num=0
  while IFS= read -r line; do
    row_num=$(( row_num + 1 ))
    local col_num=0
    for actual in $line; do
      col_num=$(( col_num + 1 ))
      if [[ "$actual" != "$color" ]]; then
        fail_row=$(( row + row_num - 1 ))
        fail_col=$(( col + col_num - 1 ))
        fail_color="$actual"
        break 2
      fi
    done
  done <<< "$grid"
  if [[ -n "$fail_row" ]]; then
    log_fail "$test_id" \
      "$desc — row $fail_row col $fail_col: expected '$color', got '$fail_color'"
  else
    log_pass "$test_id" "$desc"
  fi
  _maybe_dump "$test_id"
  return 0
}

# assert_rect_text TEST_ID ROW COL HEIGHT WIDTH EXPECTED [DESC]
# Passes when the full text content of the rectangle (right-trimmed per line)
# exactly matches EXPECTED (right-trimmed per line).
assert_rect_text() {
  local test_id="$1" row="$2" col="$3" height="$4" width="$5" expected="$6"
  local desc="${7:-rect text ($row,$col) ${height}x${width} matches expected}"
  local actual expected_trimmed
  actual=$(rect_text "$row" "$col" "$height" "$width" \
           | sed 's/[[:space:]]*$//')
  expected_trimmed=$(printf '%s' "$expected" | sed 's/[[:space:]]*$//')
  if [[ "$actual" == "$expected_trimmed" ]]; then
    log_pass "$test_id" "$desc"
  else
    log_fail "$test_id" "$desc"$'\n'"  expected: $(printf '%s' "$expected_trimmed" | head -3)"$'\n'"  actual:   $(printf '%s' "$actual" | head -3)"
  fi
  _maybe_dump "$test_id"
  return 0
}

# assert_rect_contains TEST_ID ROW COL HEIGHT WIDTH TEXT [DESC]
# Passes when TEXT appears as a substring anywhere within the rectangle.
assert_rect_contains() {
  local test_id="$1" row="$2" col="$3" height="$4" width="$5" text="$6"
  local desc="${7:-rect ($row,$col) ${height}x${width} contains '$text'}"
  local actual
  actual=$(rect_text "$row" "$col" "$height" "$width")
  if printf '%s' "$actual" | grep -qF "$text"; then
    log_pass "$test_id" "$desc"
  else
    log_fail "$test_id" "$desc — '$text' not found in region"
  fi
  _maybe_dump "$test_id"
  return 0
}

# ---------------------------------------------------------------------------
# Canonical lifecycle API stubs (overridden by app.sh)
# ---------------------------------------------------------------------------

_runner_app_start() {
  echo "ERROR: _runner_app_start not implemented — source app.sh first" >&2
  return 1
}

_runner_app_stop() {
  echo "ERROR: _runner_app_stop not implemented — source app.sh first" >&2
  return 1
}

app_reset() {
  echo "ERROR: app_reset not implemented — source app.sh first" >&2
  return 1
}

send_key() {
  echo "ERROR: send_key not implemented — source app.sh first" >&2
  return 1
}

send_insert() {
  echo "ERROR: send_insert not implemented — source app.sh first" >&2
  return 1
}

exit_zx_panel() {
  echo "ERROR: exit_zx_panel not implemented — source app.sh first" >&2
  return 1
}

app_resize() {
  echo "ERROR: app_resize not implemented — source app.sh first" >&2
  return 1
}

screen_text() {
  echo "ERROR: screen_text not implemented — source app.sh first" >&2
  return 1
}

screen_ansi() {
  echo "ERROR: screen_ansi not implemented — source app.sh first" >&2
  return 1
}

app_screen_text() {
  echo "ERROR: app_screen_text not implemented — source app.sh first" >&2
  return 1
}

rect_text()  {
  echo "ERROR: rect_text not implemented — source app.sh first" >&2
  return 1
}

rect_bg()    {
  echo "ERROR: rect_bg not implemented — source app.sh first" >&2
  return 1
}

rect_fg()    {
  echo "ERROR: rect_fg not implemented — source app.sh first" >&2
  return 1
}

capture_info_line() {
  echo "ERROR: capture_info_line not implemented — source app.sh first" >&2
  return 1
}

# ---------------------------------------------------------------------------
# try_keys KEY…
# Fire-and-forget keystrokes for teardown. Suppresses all errors.
# ---------------------------------------------------------------------------
try_keys() {
  send_key settle "$@" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# run_case — orchestrate setup / run / teardown for a single test case.
# ---------------------------------------------------------------------------
run_case() {
  local case_id="$1"
  local case_desc="$2"

  printf "\n${CYAN}━━━ %s — %s ━━━${RESET}\n" "$case_id" "$case_desc"

  local pre_pass=$_PASS
  local pre_fail=$_FAIL

  if declare -f setup > /dev/null 2>&1; then
    setup || { log_fail "$case_id" "setup() failed"; return 1; }
  fi

  if declare -f run > /dev/null 2>&1; then
    run || true
  fi

  if declare -f teardown > /dev/null 2>&1; then
    teardown || true
  fi

  _runner_app_stop 2>/dev/null || true

  if [[ -n "$_FIXTURE_DIR" ]]; then
    rm -rf "$_FIXTURE_DIR"
    _FIXTURE_DIR=""
    export APP_WORKDIR="$FIXTURES_DIR"
  fi

  local case_pass=$(( _PASS - pre_pass ))
  local case_fail=$(( _FAIL - pre_fail ))
  printf "  %s: %d passed, %d failed\n" "$case_id" "$case_pass" "$case_fail"
  [[ $case_fail -eq 0 ]]
}

# ---------------------------------------------------------------------------
# print_summary — print overall results
# ---------------------------------------------------------------------------
print_summary() {
  printf "\n"
  printf "════════════════════════════════════════\n"
  printf "  Results: %d passed, %d failed\n" "$_PASS" "$_FAIL"
  printf "════════════════════════════════════════\n"

  mkdir -p "$OUT_DIR"
  {
    printf "Date:    %s\n" "$(date '+%Y-%m-%d %H:%M:%S')"
    printf "Passed:  %d\n" "$_PASS"
    printf "Failed:  %d\n" "$_FAIL"
  } >> "$OUT_DIR/summary.txt"

  [[ $_FAIL -gt 0 ]] && return 1
  return 0
}

# ---------------------------------------------------------------------------
# require_fixture — skip test if a fixture file is missing
# ---------------------------------------------------------------------------
require_fixture() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    log_skip "fixture" "Required fixture missing: $path"
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# make_fixture_dir FILE… — create a temp dir with the named fixture files
#
# Copies each FILE from FIXTURES_DIR into a new temporary directory and
# sets APP_WORKDIR to it.  The directory is automatically removed by
# run_case after teardown.
#
# Example:
#   make_fixture_dir SAMPLE.TRD SAMPLE.TAP
# ---------------------------------------------------------------------------
_FIXTURE_DIR=""

make_fixture_dir() {
  _FIXTURE_DIR="$(mktemp -d)"
  for f in "$@"; do
    cp "$FIXTURES_DIR/$f" "$_FIXTURE_DIR/"
  done
  export APP_WORKDIR="$_FIXTURE_DIR"
}
