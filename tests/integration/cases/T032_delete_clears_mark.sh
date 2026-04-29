#!/usr/bin/env bash
# T032 — Deleting a marked file must clear the mark indicator
# Tests: spec/11-file-operations.md (Del function, mark clearing)
#        spec/02-pc-panel.md (mark indicator √)
#
# Bug: When a marked file is deleted on a PC panel, the √ mark
# indicator remains displayed on the line where the file used to be.
#
# Fixture directory + one extra file (_T032_TEMP.TXT) to delete.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T032"
CASE_DESC="Deleting a marked file clears its mark"

setup() {
  make_fixture_dir
  echo "test" > "$APP_WORKDIR/_T032_TEMP.TXT"
  app_reset
  # Navigate to the temp file (last in sort order due to _ prefix)
  send_key home end
}

run() {
  step 1 "Mark the file with Insert"
  send_key insert
  assert_text_present "${CASE_ID}_01_marked" "√" \
    "√ mark character is visible on marked entry"
  assert_text_present "${CASE_ID}_01_selected" "selected in 1 file" \
    "info line shows 1 file selected"

  step 2 "Delete the marked file with F8, confirm Yes"
  send_key open f8
  assert_text_present "${CASE_ID}_02_dialog" "Confirmation" \
    "Confirmation dialog appears"
  send_key fileop return
  assert_text_absent "${CASE_ID}_02_dialog_gone" "Confirmation" \
    "Dialog has closed after confirming"

  step 3 "Mark indicator must be gone after deletion"
  assert_text_absent "${CASE_ID}_03_no_mark" "√" \
    "√ mark indicator must not remain after file deletion"
  assert_text_absent "${CASE_ID}_03_no_selected" "selected in" \
    "info line must not show any selected files"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
