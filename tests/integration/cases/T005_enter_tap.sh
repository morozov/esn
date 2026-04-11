#!/usr/bin/env bash
# T005 — Enter a TAP tape image
# Tests: spec/04-tap-panel.md (tapPanel rendering, type codes, name line)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T005"
CASE_DESC="Enter a TAP tape image"

setup() {
  make_fixture_dir sample.tap
  app_reset
  send_key home
}

run() {
  step 1 "Navigate to sample.tap"
  send_key down
  assert_info_line "${CASE_ID}_01_on_tap" "sample.tap" \
    "cursor is on sample.tap"

  step 2 "Press Enter to open sample.tap"
  send_key open return
  assert_text_present "${CASE_ID}_02_go_up" "<<" \
    "go-up entry << is visible"
  assert_text_present "${CASE_ID}_02_no_selection" "No files selected" \
    "second info line: nothing selected"
  assert_text_present "${CASE_ID}_02_total" "Total" \
    "third info line shows total count"

  step 3 "Move cursor down to first block entry"
  send_key down
  assert_text_present "${CASE_ID}_03_block" "P" \
    "first block shows type indicator"

  step 4 "Ctrl+PgUp to exit TAP"
  exit_zx_panel
  assert_info_line "${CASE_ID}_04_back_to_pc" "sample.tap" \
    "cursor is back on sample.tap"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
