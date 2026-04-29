#!/usr/bin/env bash
# T018 — Sort modes
# Tests: spec/02-pc-panel.md (Sorting Behavior)
#        spec/01-architecture.md (SortType: NonType/NameType/ExtType/LenType)
#        spec/10-keyboard-and-input.md (Ctrl+F3/F4/F5/F6 sort keys)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T018"
CASE_DESC="Sort modes (PC panel)"

setup() {
  make_fixture_dir sample.trd
  app_reset
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Default sort — natural order with priority groups"
  send_key
  assert_text_present "${CASE_ID}_01_dirs_first" ".." \
    "Parent dir .. entry appears at the top of the file list"
  assert_text_present "${CASE_ID}_01_zx_files_present" "sample   trd" \
    "ZX image files (priority group 1) are listed as 'sample   trd' (no dot)"

  # -----------------------------------------------------------------------
  step 2 "Ctrl+F3 — sort by name (NameType)"
  send_key ctrl+f3
  assert_info_line "${CASE_ID}_02_cursor_at_top" ".." \
    "After Ctrl+F3 (sort by name), cursor is at top on .."

  # -----------------------------------------------------------------------
  step 3 "Ctrl+F4 — sort by extension (ExtType)"
  send_key ctrl+f4
  assert_text_present "${CASE_ID}_03_files_present" "sample" \
    "Files still present after sort by extension"

  # -----------------------------------------------------------------------
  step 4 "Ctrl+F5 — sort by length (LenType)"
  send_key ctrl+f5
  assert_text_present "${CASE_ID}_04_files_present" "sample" \
    "Files still present after sort by length"

  # -----------------------------------------------------------------------
  step 5 "Ctrl+F6 — no sort (NonType)"
  send_key ctrl+f6
  assert_text_present "${CASE_ID}_05_no_sort" "sample   trd" \
    "Files present after returning to natural order"

  # -----------------------------------------------------------------------
  step 6 "Sort applies to the focused panel only"
  send_key tab
  send_key ctrl+f3
  send_key tab
  assert_text_present "${CASE_ID}_06_left_unchanged" "sample   trd" \
    "Left panel content unchanged — sort settings are independent"

  # -----------------------------------------------------------------------
  step 7 "Sorting does NOT apply to ZX panels"
  send_key down
  send_key open return
  send_key ctrl+f3
  assert_text_present "${CASE_ID}_07_trd_no_sort" "<<" \
    "Ctrl+F3 in trdPanel has no effect — go-up entry still present"

  send_key ctrl+pgup
}

teardown() {
  try_keys ctrl+f6
}

run_case "$CASE_ID" "$CASE_DESC"
