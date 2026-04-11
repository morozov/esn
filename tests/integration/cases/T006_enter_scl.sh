#!/usr/bin/env bash
# T006 — Enter an SCL archive
# Tests: spec/05-scl-panel.md (sclPanel rendering, Hobeta98 label, free line)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T006"
CASE_DESC="Enter an SCL archive"

setup() {
  make_fixture_dir sample.scl
  app_reset
  send_key home
}

run() {
  step 1 "Navigate to sample.scl"
  send_key down
  assert_info_line "${CASE_ID}_01_on_scl" "sample.scl" \
    "cursor is on sample.scl (first ZX image alphabetically)"

  step 2 "Press Enter to open sample.scl"
  send_key open return
  assert_text_present "${CASE_ID}_02_hobeta98" "Hobeta98" \
    "left panel border shows Hobeta98 (SCL disk label)"
  assert_text_present "${CASE_ID}_02_go_up" "<<" \
    "go-up entry << is visible"
  assert_text_present "${CASE_ID}_02_no_selection" "No files selected" \
    "second info line: nothing selected"
  assert_text_present "${CASE_ID}_02_total" "Total" \
    "third info line shows total file count"

  step 3 "Move cursor to first real SCL file"
  send_key down
  assert_text_present "${CASE_ID}_03_type" "<" \
    "first real SCL file entry has type indicator <T>"

  step 4 "Ctrl+PgUp to exit SCL"
  exit_zx_panel
  assert_info_line "${CASE_ID}_04_back_to_pc" "sample.scl" \
    "cursor is back on sample.scl"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
