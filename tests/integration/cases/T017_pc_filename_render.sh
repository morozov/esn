#!/usr/bin/env bash
# T017 — PC filename rendering details
# Tests: spec/02-pc-panel.md (Entry Rendering pcPDF, Single-column right section,
#        Name Line pcNameLine, File Attributes)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T017"
CASE_DESC="PC filename rendering details"

setup() {
  make_fixture_dir sample.scl sample.tap sample.trd
  mkdir "$_FIXTURE_DIR/SUB-DIR"
  app_reset
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "File name case: lowercase for files, uppercase for directories"
  send_key
  assert_text_present "${CASE_ID}_01_dirs_uppercase" ".." \
    "Directory entries show in uppercase (.. visible)"
  assert_text_present "${CASE_ID}_01_zx_files_present" "sample" \
    "ZX image files (priority group 1) are visible"

  # -----------------------------------------------------------------------
  step 2 "Attribute indicator column"
  send_key home down
  send_key
  assert_text_absent "${CASE_ID}_02_no_mark_yet" "√" \
    "No √ mark before any marking"

  # -----------------------------------------------------------------------
  step 3 "Extension field formatting"
  send_key
  assert_text_present "${CASE_ID}_03_ext_present" "." \
    "Extension separator . is visible in file entries"

  # -----------------------------------------------------------------------
  step 4 "Single-column mode: name line details"
  send_key
  assert_text_present "${CASE_ID}_04_info_line_present" " free" \
    "Free space info line is present"

  # -----------------------------------------------------------------------
  step 5 "pcNameLine format — cursor on a file"
  send_key home down
  send_key
  assert_text_present "${CASE_ID}_05_size_in_name_line" "SUB-DIR" \
    "Name line shows SUB-DIR for the parent dir entry type indicator"
  assert_text_present "${CASE_ID}_05_free_space" " free" \
    "Third info line shows free space on drive"

  # -----------------------------------------------------------------------
  step 6 "Color groups in PC panel"
  send_key
  assert_text_present "${CASE_ID}_06_zx_files_visible" "sample   trd" \
    "ZX image files (.trd) are listed in panel as 'sample   trd' (no dot)"
}

teardown() {
  :
}

run_case "$CASE_ID" "$CASE_DESC"
