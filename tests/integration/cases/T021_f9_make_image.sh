#!/usr/bin/env bash
# T021 — F9 MakeImages menu on pcPanel
# Tests: spec/11-file-operations.md (Make Image / F9 on pcPanel)
#        spec/12-dialogs.md (ChooseItem popup menu)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T021"
CASE_DESC="F9 MakeImages menu creates new image files in pcPanel"

TRD_FILE=""
TAP_FILE=""
SCL_FILE=""

setup() {
  make_fixture_dir
  TRD_FILE="${APP_WORKDIR}/TESTMAKE.TRD"
  TAP_FILE="${APP_WORKDIR}/TESTMAKE.TAP"
  SCL_FILE="${APP_WORKDIR}/TESTMAKE.SCL"
  app_reset
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "F9 on pcPanel opens MakeImages menu"
  send_key home
  send_key open f9
  assert_text_present "${CASE_ID}_01_menu_visible" "TRD" \
    "MakeImages menu shows 'TRD' option"
  assert_text_present "${CASE_ID}_01_tap_option" "TAP" \
    "MakeImages menu shows 'TAP' option"

  # -----------------------------------------------------------------------
  step 2 "Select TRD (item 1) — create a new TRD image"
  send_key open return
  assert_text_present "${CASE_ID}_02_trd_name_dialog" "New TRD" \
    "New TRD-file dialog appears with title 'New TRD'"

  # Type filename, Tab to tracks field, then Enter to accept default (80)
  send_key t
  send_key e
  send_key s
  send_key t
  send_key m
  send_key a
  send_key k
  send_key e
  send_key tab
  send_key fileop return
  assert_text_present "${CASE_ID}_02_trd_in_listing" "testmake" \
    "After creating testmake.trd, file appears in directory listing"

  # -----------------------------------------------------------------------
  step 3 "Verify TRD file was created on disk"
  if [[ -f "$TRD_FILE" ]]; then
    log_pass "${CASE_ID}_03_trd_file_exists" \
      "TESTMAKE.TRD exists on disk (size: $(wc -c < "$TRD_FILE") bytes)"
  else
    log_fail "${CASE_ID}_03_trd_file_exists" \
      "TESTMAKE.TRD not found at $TRD_FILE"
  fi

  # -----------------------------------------------------------------------
  step 4 "F9 again — select TAP (item 5)"
  send_key open f9
  send_key down down down down
  send_key open return
  assert_text_present "${CASE_ID}_04_tap_dialog_visible" "New TAP" \
    "New TAP-file dialog appears"

  send_key t
  send_key e
  send_key s
  send_key t
  send_key m
  send_key a
  send_key k
  send_key e
  send_key fileop return
  assert_text_present "${CASE_ID}_04_tap_in_listing" "testmake" \
    "After creating testmake.tap, file appears in directory listing"

  # -----------------------------------------------------------------------
  step 5 "Escape cancels the MakeImages menu without creating a file"
  send_key open f9
  send_key escape
  assert_text_absent "${CASE_ID}_05_menu_closed" "New TRD" \
    "After Escape in MakeImages menu, no new-image dialog appeared"
  assert_text_present "${CASE_ID}_05_sbar_restored" "Exit" \
    "Status bar shows normal pcPanel key bindings"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
