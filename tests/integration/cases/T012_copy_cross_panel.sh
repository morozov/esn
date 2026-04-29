#!/usr/bin/env bash
# T012 — F5 Copy between panels
# Tests: spec/11-file-operations.md (fCopy, WillCopyMove dialog)
#        spec/12-dialogs.md (WillCopyMove layout, input field)
#        spec/02-pc-panel.md (pcPanel as copy target)
#        spec/03-trd-panel.md (Extract from TRD to PC)
#
# Fixture directory: sample.scl, sample.tap, sample.trd.
# sample.trd is at position 4 = 3 downs from ..
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T012"
CASE_DESC="F5 Copy between panels"

setup() {
  make_fixture_dir sample.trd
  app_reset
  send_key
}

run() {
  # -----------------------------------------------------------------------
  # Open sample.trd in left panel, mark one file, then F5 copy to right panel.
  # -----------------------------------------------------------------------

  step 1 "Enter sample.trd in left panel"
  send_key home
  send_key down
  send_key open return
  assert_text_present "${CASE_ID}_01_in_trd" "TRD" \
    "Left panel is in trdPanel mode (TRD visible in border)"

  # -----------------------------------------------------------------------
  step 2 "Move to first real TRD file and mark it"
  send_key down
  send_key insert
  assert_text_present "${CASE_ID}_02_file_marked" "√" \
    "Marked file shows √ indicator"
  assert_text_present "${CASE_ID}_02_blocks_selected" "block" \
    "Second info line shows block(s) selected"

  # -----------------------------------------------------------------------
  step 3 "Right panel is a PC panel"
  send_key
  assert_text_present "${CASE_ID}_03_right_is_pc" "Copy" \
    "Status bar shows pcPanel key labels (Copy action visible)"

  # -----------------------------------------------------------------------
  step 4 "Press F5 — WillCopyMove dialog appears"
  send_key open f5
  assert_text_present "${CASE_ID}_04_dialog_appears" " Copy " \
    "WillCopyMove dialog title ' Copy ' is visible"
  assert_text_present "${CASE_ID}_04_radio_buttons" "Overwrite" \
    "Copy dialog shows 'Overwrite' radio button option"

  # -----------------------------------------------------------------------
  step 5 "Press Enter to confirm the copy"
  send_key fileop return
  assert_text_absent "${CASE_ID}_05_dialog_closed" "To:" \
    "WillCopyMove dialog has closed after confirmation"

  # -----------------------------------------------------------------------
  step 6 "Escape in copy dialog cancels"
  send_key open f5
  assert_text_present "${CASE_ID}_06a_dialog_up" " Copy " \
    "WillCopyMove dialog appears again"

  send_key escape
  assert_text_absent "${CASE_ID}_06_copy_cancelled" "To:" \
    "After Escape, dialog closes and no copy is performed"
}

teardown() {
  try_keys ctrl+pageup
}

run_case "$CASE_ID" "$CASE_DESC"
