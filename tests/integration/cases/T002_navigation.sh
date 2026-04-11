#!/usr/bin/env bash
# T002 — Cursor movement within a panel
# Tests: spec/10-keyboard-and-input.md (Up/Down/PgUp/PgDn/Home/End)
#        spec/01-architecture.md (TPanel fields: from, f, PanelHi)
#
# Uses a fixture directory with exactly 3 ZX image files.
# Ordering at 80x25 (all three are priority=1 ZX images):
#   [1]  ..
#   [2]  sample.scl
#   [3]  sample.tap
#   [4]  sample.trd
#
# Cursor highlight background: in 3-column mode (default at 80x25),
# each column cell is 12 chars wide.  The left ║ border is visual col 1;
# content cells start at visual col 2 and are cyan on the cursor row.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T002"
CASE_DESC="Cursor movement within a panel"

setup() {
  make_fixture_dir sample.scl sample.tap sample.trd
  app_reset
  send_key home
}

run() {
  step 1 "Initial position — cursor on first entry"
  send_key
  assert_info_line "${CASE_ID}_01" ".." "cursor starts on parent dir"
  assert_rect_bg "${CASE_ID}_01_color" 3 2 1 12 cyan \
    "cursor row content area has cyan background"

  step 2 "Down — move to second entry"
  send_key down
  assert_info_line "${CASE_ID}_02" "sample.scl" "cursor on first file"
  assert_rect_bg "${CASE_ID}_02_color" 4 2 1 12 cyan \
    "cursor moved to second row"

  step 3 "Down two more times — land on fourth entry"
  send_key down down
  assert_info_line "${CASE_ID}_03" "sample.trd" "cursor on fourth entry"

  step 4 "Up — back to third entry"
  send_key up
  assert_info_line "${CASE_ID}_04" "sample.tap" "cursor on third entry"

  step 5 "Home — jump to first entry"
  send_key home
  assert_info_line "${CASE_ID}_05" ".." "Home lands on parent dir"
  assert_rect_bg "${CASE_ID}_05_color" 3 2 1 12 cyan \
    "cursor highlight back on row 3"

  step 6 "End — jump to last entry"
  send_key end
  assert_info_line "${CASE_ID}_06" "sample.trd" "End lands on last file"

  step 7 "PgUp — one page up from last entry"
  send_key pageup
  # With only 4 entries PgUp lands on the first entry.
  assert_info_line "${CASE_ID}_07" ".." "PgUp moves back to first entry"

  step 8 "PgDn — one page down"
  send_key pagedown
  assert_info_line "${CASE_ID}_08" "sample.trd" \
    "PgDn lands back on last file"

  step 9 "Up at top boundary — cursor stays on first entry"
  send_key home
  send_key up
  assert_info_line "${CASE_ID}_09" ".." "Up at top does not wrap"

  step 10 "Down at bottom boundary — cursor stays on last entry"
  send_key end
  send_key down
  assert_info_line "${CASE_ID}_10" "sample.trd" \
    "Down at bottom does not wrap"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
