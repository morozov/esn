#!/usr/bin/env bash
# T020 — Back-navigation chain (Ctrl+PgUp from various depths)
# Tests: spec/11-file-operations.md (CtrlPgUp behavior in pcPanel and ZX panels)
#        spec/01-architecture.md (TreeC depth counter, PanelType switching)
#
# Fixture directory: sample.scl, sample.tap, sample.trd.
#   [1] ..   [2] sample.scl   [3] sample.tap   [4] sample.trd
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T020"
CASE_DESC="Back-navigation chain (Ctrl+PgUp from nested panels)"

setup() {
  make_fixture_dir sample.scl sample.tap sample.trd
  app_reset
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Enter sample.trd from pcPanel"
  send_key home
  send_key down down down
  send_key open return
  assert_text_present "${CASE_ID}_01_in_trd" "TRD" \
    "Left panel is now in trdPanel mode"

  # -----------------------------------------------------------------------
  step 2 "Ctrl+PgUp from trdPanel — exit to pcPanel"
  send_key ctrl+pgup
  assert_info_line "${CASE_ID}_02_cursor_on_trd_file" "sample.trd" \
    "Cursor is back on sample.trd after exiting trdPanel"

  # -----------------------------------------------------------------------
  step 3 "Enter sample.trd again, then use << entry to exit"
  send_key open return
  assert_text_present "${CASE_ID}_03a_in_trd_again" "<<" \
    "Re-entered sample.trd — trdPanel mode with << visible"

  send_key home
  send_key open return
  assert_info_line "${CASE_ID}_03c_exit_via_go_up" "sample.trd" \
    "Enter on << exits to pcPanel, cursor on sample.trd"

  # -----------------------------------------------------------------------
  step 4 "Enter SCL, then Ctrl+PgUp"
  send_key home
  send_key down
  send_key open return
  assert_text_present "${CASE_ID}_04_in_scl" "Hobeta98" \
    "Left panel is now in sclPanel mode (Hobeta98 label)"

  send_key ctrl+pgup
  assert_info_line "${CASE_ID}_04_back_from_scl" "sample.scl" \
    "Ctrl+PgUp from sclPanel returns to pcPanel, cursor on sample.scl"

  # -----------------------------------------------------------------------
  step 5 "TAP panel exit chain"
  send_key home
  send_key down down
  send_key open return
  assert_text_present "${CASE_ID}_05_in_tap" "Total" \
    "Left panel is in tapPanel mode (Total count visible)"

  send_key ctrl+pgup
  assert_info_line "${CASE_ID}_05_back_from_tap" "sample.tap" \
    "Ctrl+PgUp from tapPanel returns to pcPanel, cursor on sample.tap"

  # -----------------------------------------------------------------------
  step 6 "Ctrl+PgUp in pcPanel — go up one directory level"
  send_key home
  send_key ctrl+pgup
  assert_text_present "${CASE_ID}_06_went_up" ".." \
    "After Ctrl+PgUp in pcPanel, parent dir is accessible"
}

teardown() {
  try_keys ctrl+pageup
  try_keys ctrl+pageup
}

run_case "$CASE_ID" "$CASE_DESC"
