#!/usr/bin/env bash
# T013 — F8/Del delete with confirmation dialog
# Tests: spec/11-file-operations.md (Del function)
#        spec/12-dialogs.md (cQuestion layout — Yes/No dialog)
#        spec/10-keyboard-and-input.md (Del_F8=true: F8=Delete)
#
# Uses a fixture directory so sample.trd modifications are isolated.
# sample.trd is at position 4 = 3 downs from ..
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T013"
CASE_DESC="F8/Del delete with confirmation dialog"

setup() {
  make_fixture_dir sample.trd
  app_reset
  # Enter sample.trd in left panel
  send_key home
  send_key down
  send_key open return
  # Move to first real file
  send_key down
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Press F8 (Delete, since Del_F8=true) — confirmation dialog appears"
  send_key open f8
  assert_text_present "${CASE_ID}_01_dialog_title" "Confirmation" \
    "Confirmation dialog title is visible"
  assert_text_present "${CASE_ID}_01_dialog_text" "Do you wish to delete" \
    "Dialog text shows 'Do you wish to delete'"
  assert_text_present "${CASE_ID}_01_yes_button" "Yes" \
    "Yes button is visible"
  assert_text_present "${CASE_ID}_01_no_button" "No" \
    "No button is visible"

  # -----------------------------------------------------------------------
  step 2 "Right arrow — move focus to No button"
  send_key right
  assert_text_present "${CASE_ID}_02_no_focused" "No" \
    "No button is still visible after right arrow"

  # -----------------------------------------------------------------------
  step 3 "Press Enter with No focused — dialog closes, file unchanged"
  send_key return
  assert_text_absent "${CASE_ID}_03_dialog_closed" "Confirmation" \
    "Dialog has closed after pressing No"

  # -----------------------------------------------------------------------
  step 4 "Press Escape in delete dialog — cancels"
  send_key open f8
  assert_text_present "${CASE_ID}_04a_dialog_again" "Confirmation" \
    "Confirmation dialog appears again"

  send_key escape
  assert_text_absent "${CASE_ID}_04_escape_cancels" "Confirmation" \
    "Pressing Escape in the confirmation dialog cancels the delete"

  # -----------------------------------------------------------------------
  step 5 "Confirm deletion — file removed"
  send_key open f8
  assert_text_present "${CASE_ID}_05a_dialog_third" "Confirmation" \
    "Confirmation dialog appears for the third time"

  # Yes is focused by default; press Enter to confirm
  send_key open return
  assert_text_absent "${CASE_ID}_05_dialog_gone" "Confirmation" \
    "After confirming Yes, dialog closes"
  assert_text_present "${CASE_ID}_05_blocks_free_increased" "blocks free" \
    "Free sector count line still visible after deletion"
}

teardown() {
  try_keys ctrl+pageup
}

run_case "$CASE_ID" "$CASE_DESC"
