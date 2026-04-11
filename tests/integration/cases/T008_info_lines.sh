#!/usr/bin/env bash
# T008 — Info line content verification
# Tests: spec/02-pc-panel.md (pcNameLine, Selected summary, Free space line)
#        spec/03-trd-panel.md (trdNameLine, Selected-blocks summary, Disk info)
#
# Fixture directory: sample.scl, sample.tap, sample.trd.
# sample.trd is at position 4 = 3 downs from ..
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T008"
CASE_DESC="Info line content"

setup() {
  make_fixture_dir sample.trd
  app_reset
  send_key home
}

run() {
  step 1 "PC panel — cursor on .. entry"
  send_key
  assert_info_line "${CASE_ID}_01_dotdot" ".." \
    "info line shows .. for parent dir entry"
  assert_text_present "${CASE_ID}_01_subdir" "SUB-DIR" \
    "info line 1 shows SUB-DIR for directory"
  assert_text_present "${CASE_ID}_01_no_selection" "No files selected" \
    "info line 2 shows 'No files selected'"
  assert_text_present "${CASE_ID}_01_free_space" "bytes free" \
    "info line 3 shows 'bytes free on drive'"

  step 2 "PC panel — cursor on first real file"
  send_key down
  assert_text_present "${CASE_ID}_02_file_size" "bytes free" \
    "free space line still present after moving to file"

  step 3 "PC panel — mark one file, check selected summary"
  send_key home down
  send_insert
  assert_text_present "${CASE_ID}_03_selected_one" "selected in 1 file" \
    "info line 2 shows bytes selected in 1 file"

  step 4 "TRD panel — check selected-blocks summary"
  send_key home
  send_key down
  assert_info_line "${CASE_ID}_04_on_trd" "sample.trd" \
    "cursor on sample.trd"
  send_key open return
  send_key down
  send_insert
  assert_text_present "${CASE_ID}_04_blocks_selected" "block" \
    "TRD info line 2 shows block(s) selected"
  assert_text_present "${CASE_ID}_04_blocks_free" "blocks free" \
    "TRD info line 3 shows free sector count"
  exit_zx_panel
}

teardown() {
  try_keys ctrl+pageup
}

run_case "$CASE_ID" "$CASE_DESC"
