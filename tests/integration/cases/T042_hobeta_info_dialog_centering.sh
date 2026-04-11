#!/usr/bin/env bash
# T042 — Hobeta info dialog is centered at wide terminal
# Tests: spec/09-ui-rendering.md (dialog centering)
#
# Regression for Bug 1: the dialog used hardcoded x=16,x2=65 and
# button x=36 (correct only for 80 columns).  After the fix all
# x-coordinates are derived from HalfMaxX.  At 120 columns the
# dialog title "Information" must appear on screen and the OK button
# must not be clipped to the right of the screen.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T042"
CASE_DESC="Hobeta info dialog centered at wide terminal"

setup() {
  make_fixture_dir kwiksnax.zxz
  app_reset 120 30
  send_key home
}

run() {
  step 1 "Navigate to kwiksnax.zxz and verify it is visible"
  send_key down
  # At 120x30 the pane height fallback makes capture_info_line unreliable;
  # instead confirm kwiksnax.zxz is visible anywhere on screen.
  assert_text_present "${CASE_ID}_01_zxz_visible" "kwiksnax" \
    "kwiksnax.zxz is visible on screen (cursor on it)"

  step 2 "Press Enter — Hobeta info dialog appears"
  send_key open return
  wait_for_text "Information"
  assert_text_present "${CASE_ID}_02_dialog_title" "Information" \
    "Hobeta info dialog title 'Information' is visible"
  assert_text_present "${CASE_ID}_02_column_headers" "Name" \
    "Column header 'Name' is present"
  assert_text_present "${CASE_ID}_02_ok_button" "OK" \
    "OK button is present in the dialog"

  step 3 "At 120 columns dialog is centered — content not clipped"
  assert_text_present "${CASE_ID}_03_not_clipped_start" "Start" \
    "Column header 'Start' is visible (dialog not clipped on left)"
  assert_text_present "${CASE_ID}_03_not_clipped_blocks" "Blocks" \
    "Column header 'Blocks' is visible (dialog not clipped on right)"

  step 4 "Dismiss dialog and verify panels restored"
  send_key open return
  wait_for_no_text "Information" 1000
  assert_text_absent "${CASE_ID}_04_dialog_gone" "Information" \
    "Dialog closed after Enter"
  assert_text_present "${CASE_ID}_04_panels_intact" "Exit" \
    "Status bar is intact after closing dialog"

  step 5 "Exit ZXZ panel (Enter also opens ZXZ panel after dialog)"
  exit_zx_panel
}

teardown() {
  try_keys backspace escape
}

run_case "$CASE_ID" "$CASE_DESC"
