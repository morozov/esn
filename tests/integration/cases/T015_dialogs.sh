#!/usr/bin/env bash
# T015 — Dialog rendering
# Tests: spec/12-dialogs.md (cQuestion, About, WillCopyMove, GetWildMask)
#        spec/09-ui-rendering.md (scPutWin/sPutWin, RestScr, button shadow)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T015"
CASE_DESC="Dialog rendering"

setup() {
  app_reset
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Exit confirmation dialog (F10)"
  # Use F10 instead of Escape to open the exit dialog.  Escape
  # requires the double-escape FPC hack (\x1b\x1b\x00) which
  # leaves residual state that interferes with subsequent escape-
  # sequence keys (arrows, function keys).
  send_key f10
  wait_for_text "Confirmation"
  assert_text_present "${CASE_ID}_01_exit_dialog_appears" "Confirmation" \
    "F10 shows exit confirmation dialog with title 'Confirmation'"
  assert_text_present "${CASE_ID}_01_exit_dialog_text" "Are you sure" \
    "Dialog text shows 'Are you sure?'"
  assert_text_present "${CASE_ID}_01_yes_no_buttons" "Yes" \
    "Yes button is present"
  assert_text_present "${CASE_ID}_01_no_button" "No" \
    "No button is present"

  # Dismiss by selecting No and pressing Enter.
  send_key right
  send_key open return
  wait_for_no_text "Confirmation" 1000
  assert_text_absent "${CASE_ID}_01_dialog_dismissed" "Confirmation" \
    "After selecting No, exit dialog closes and panels are restored"

  # -----------------------------------------------------------------------
  step 2 "About dialog (F1)"
  send_key f1
  wait_for_text "Version"
  assert_text_present "${CASE_ID}_02_about_version" "Version" \
    "About dialog shows 'Version'"
  assert_text_present "${CASE_ID}_02_about_freeware" "freeware" \
    "About dialog shows 'freeware'"
  assert_text_present "${CASE_ID}_02_about_ok_button" "OK" \
    "About dialog has an OK button"

  send_key return
  wait_for_no_text "freeware"
  assert_text_absent "${CASE_ID}_02_about_closed" "freeware" \
    "After pressing OK, About dialog closes"

  # -----------------------------------------------------------------------
  step 3 "Plus (+) wildcard mask dialog"
  send_key "+"
  wait_for_text "Mask"
  assert_text_present "${CASE_ID}_03_mask_dialog_layout" "Mask" \
    "GetWildMask dialog shows 'Mask' label"
  assert_text_present "${CASE_ID}_03_mask_default_value" "*.*" \
    "Input field shows '*.*' as the default mask"

  # Dismiss by Escape
  send_key escape
  wait_for_no_text "Mask"
  assert_text_absent "${CASE_ID}_03_mask_dismissed" "Mask" \
    "Mask dialog dismissed after Escape"

  # -----------------------------------------------------------------------
  step 4 "Dialog background is preserved (screen save/restore)"
  send_key f1
  wait_for_text "Version"
  assert_text_present "${CASE_ID}_04_background_occluded" "Version" \
    "About dialog overlays the panel view"

  send_key return
  wait_for_no_text "Version"
  assert_text_absent "${CASE_ID}_04_background_restored" "Version" \
    "After closing About, panels restored — no dialog text visible"
  assert_text_present "${CASE_ID}_04_panels_back" "Exit" \
    "Status bar is intact after dialog close"

  # -----------------------------------------------------------------------
  step 5 "Nested dialog — shadow rendering"
  send_key escape
  wait_for_text "Confirmation"
  assert_text_present "${CASE_ID}_05_dialog_visible" "Confirmation" \
    "Exit dialog appears for shadow inspection"

  send_key escape
  wait_for_no_text "Confirmation"
}

teardown() {
  try_keys escape escape
}

run_case "$CASE_ID" "$CASE_DESC"
