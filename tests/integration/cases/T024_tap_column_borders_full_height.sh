#!/usr/bin/env bash
# T024 — TAP panel column borders must render for all rows, not only entries
#
# Regression: entering a TAP file with few blocks (sample.tap has 3 visible
# entries: <<, hello, code) left the column separator │ absent on empty rows
# below the last entry.  The border should extend to the bottom of the panel
# regardless of how many entries the file contains.
#
# The bug only reproduces at terminal widths greater than 80.
#
# Fixture directory: sample.scl, sample.tap, sample.trd.
# sample.tap is at position 3 = 2 downs from ..
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T024"
CASE_DESC="TAP panel column borders render full panel height"

# Terminal dimensions for this test.
_T024_W=120
_T024_H=25

setup() {
  make_fixture_dir sample.tap
  app_reset "$_T024_W" "$_T024_H"
}

teardown() { :; }

run() {
  # ESN divides the terminal into two equal panels; right panel content
  # starts one column after the left panel ends.
  local right_col=$(( _T024_W / 2 + 1 ))

  # Panel body: row 2 is the column-header row, rows 3..(H-6) are entries.
  # Pick a row in the middle of the body — well past sample.tap's entries
  # so it is an empty slot.
  local body_first=3
  local body_last=$(( _T024_H - 6 ))
  local mid_row=$(( (body_first + body_last) / 2 ))

  # app_reset leaves the left panel active; switch to right, then enter
  # sample.tap is the only file (1 down from ..).
  send_key settle tab home
  send_key settle down
  send_key open enter

  # With the bug:  │ is absent on empty rows in the right (TAP) panel.
  # With the fix:  │ appears at the column separator on every body row.
  local right_w=$(( _T024_W - right_col + 1 ))
  assert_rect_contains "${CASE_ID}_01" \
    "$mid_row" "$right_col" 1 "$right_w" "│" \
    "Column separator │ present on empty row ${mid_row} of right panel \
(${_T024_W}x${_T024_H}) — borders render full height"
}

run_case "$CASE_ID" "$CASE_DESC"
