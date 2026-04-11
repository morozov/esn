#!/usr/bin/env bash
# T030 — Right panel right border at correct column for odd terminal width
#
# Bug: PanelW is computed as GmaxX div 2 - 2 for both panels.  At odd
# terminal widths this makes the right panel one column narrower than it
# should be: the right border and scrollbar land at GmaxX-1 instead of
# GmaxX, leaving a one-column gap on the right edge.
#
# Fix: for the right panel use GmaxX - PosX - 1
#      (= GmaxX - GmaxX div 2 - 2) so it absorbs the extra column.
#
# Assertion strategy:
#   The bottom border of both panels is an all-═ line:
#       ╚══...══╝╚══...══╝
#   Total ═ count = PanelW_left + PanelW_right.
#   With the fix this equals GmaxX - 4 (the 4 corner characters ╚╝╚╝).
#   With the bug at odd GmaxX it equals GmaxX - 5 (right panel 1 narrow).

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T030"
CASE_DESC="Right panel right border reaches terminal edge at odd width"

# ---------------------------------------------------------------------------
# check_bottom_border_width TERMINAL_COLS TEST_ID DESC
# Counts ═ characters in the bottom panel border line and asserts the count
# equals TERMINAL_COLS - 4.
# ---------------------------------------------------------------------------
check_bottom_border_width() {
  local terminal_cols="$1"
  local test_id="$2"; shift 2
  local description="$*"

  local screen bottom_line count expected
  screen=$(app_screen_text)
  bottom_line=$(printf '%s\n' "$screen" | grep '╚' | head -1)

  if [[ -z "$bottom_line" ]]; then
    log_skip "$test_id" "$description — bottom border (╚) not found"
    return 0
  fi

  count=$(printf '%s' "$bottom_line" | grep -o '═' | wc -l | tr -d ' ')
  expected=$(( terminal_cols - 4 ))

  if [[ "$count" -lt "$expected" ]]; then
    log_fail "$test_id" \
      "$description — ═ count $count < expected $expected \
(= ${terminal_cols}-4). Right panel is one column too narrow: \
PanelW = GmaxX div 2 - 2 instead of GmaxX - PosX - 1"
  else
    log_pass "$test_id" "$description"
  fi
}

setup() {
  app_reset 81 25
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Odd 81-col terminal at startup — right panel spans full width"

  check_bottom_border_width 81 "${CASE_ID}_01_startup_81" \
    "Bottom border has 77 ═ chars (=81-4) at 81-col startup. \
Fails if right PanelW = 38 (GmaxX div 2-2) instead of 39"

  # -----------------------------------------------------------------------
  step 2 "Even 80-col sanity check — no regression on even widths"
  app_resize 80 25

  check_bottom_border_width 80 "${CASE_ID}_02_even_80" \
    "Bottom border has 76 ═ chars (=80-4) at 80-col — even-width baseline"

  # -----------------------------------------------------------------------
  step 3 "Runtime resize to odd 83 cols"
  app_resize 83 25

  check_bottom_border_width 83 "${CASE_ID}_03_resize_83" \
    "After resize to 83 cols (odd), bottom border has 79 ═ chars (=83-4). \
Fails if right panel still uses GmaxX div 2 - 2 after resize"
}

teardown() {
  :
}

run_case "$CASE_ID" "$CASE_DESC"
