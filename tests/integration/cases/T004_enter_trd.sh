#!/usr/bin/env bash
# T004 — Enter a TRD disk image
# Tests: spec/03-trd-panel.md (trdPanel rendering, name line, disk info)
#        spec/11-file-operations.md (Enter key in pcPanel, Ctrl+PgUp to exit)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T004"
CASE_DESC="Enter a TRD disk image"

setup() {
  make_fixture_dir sample.trd
  app_reset
  send_key home
}

run() {
  step 1 "Navigate to sample.trd"
  send_key down
  assert_info_line "${CASE_ID}_01_on_trd" "sample.trd" \
    "cursor is on sample.trd"

  step 2 "Press Enter to open sample.trd"
  send_key open return
  assert_text_present "${CASE_ID}_02_panel_type" "TRD" \
    "left panel border shows TRD panel type"
  assert_text_present "${CASE_ID}_02_go_up" "<<" \
    "go-up entry << is visible"
  assert_text_present "${CASE_ID}_02_no_selection" "No files selected" \
    "second info line: nothing selected"
  assert_text_present "${CASE_ID}_02_blocks_free" "blocks free" \
    "third info line shows free sectors"

  step 3 "Move cursor down to first real file"
  send_key down
  assert_text_present "${CASE_ID}_03_file_type" "<" \
    "first real TRD file entry has type indicator <T>"

  step 4 "Ctrl+PgUp to exit TRD and return to pcPanel"
  exit_zx_panel
  assert_info_line "${CASE_ID}_04_back_to_pc" "sample.trd" \
    "cursor is back on sample.trd after exiting trdPanel"
  assert_text_present "${CASE_ID}_04_status_bar" "Copy" \
    "status bar shows pcPanel key labels"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
