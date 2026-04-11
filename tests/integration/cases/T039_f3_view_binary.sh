#!/usr/bin/env bash
# T039 — F3 on a binary file must not hang
# Tests: snviewer.pas (MakeTabs in GetTextFromFile)
#
# Regression: MakeTabs declares its position variable D as Byte.
# When ReadLn produces an AnsiString line longer than 255 bytes
# (which never happened in BP7 with short strings), a tab byte
# past position 255 causes D to wrap, the tab is never deleted,
# and the While loop spins forever.
#
# Fixture: DS_Store — a macOS .DS_Store file whose binary content
# contains tab bytes past position 255 within long "lines" (lines
# are delimited by the few 0x0A bytes in the binary data).
#
# Checks:
#   1. Navigate to the file.
#   2. F3 opens the viewer (frame border visible).
#   3. Esc closes the viewer (panel restored).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T039"
CASE_DESC="F3 on a binary file must not hang"

setup() {
  make_fixture_dir DS_Store
  app_reset
}

run() {
  step 1 "Navigate to DS_Store"
  local i
  for i in $(seq 1 10); do
    send_key down
    if capture_info_line | grep -qiF "DS_Store"; then
      break
    fi
  done

  assert_info_line "${CASE_ID}_01_cursor" "DS_Store" \
    "cursor is on DS_Store"

  step 2 "Press F3 to view the binary file"
  send_key open f3

  # The viewer replaces the dual-panel display with a bordered
  # view.  The panel column headers must NOT be on screen while
  # the viewer is open; this distinguishes a true viewer from
  # the panel border reusing the same box-drawing characters.
  assert_text_absent "${CASE_ID}_02_no_panels" "Name" \
    "panel column headers absent — viewer opened"

  # The bottom-left corner shows the position indicator [1:1].
  assert_text_present "${CASE_ID}_02_position" "[1:1]" \
    "viewer position indicator visible"

  step 3 "Press Esc to close the viewer"
  send_key escape

  assert_text_present "${CASE_ID}_03_panel_restored" "DS_Store" \
    "panel restored after closing viewer"
}

teardown() { :; }

# ---------------------------------------------------------------------------
source "$(dirname "${BASH_SOURCE[0]}")/../lib/app.sh"
run_case "$CASE_ID" "$CASE_DESC"
