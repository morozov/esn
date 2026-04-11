#!/usr/bin/env bash
# T035 — Multi-column overflow: files fill columns 2 and 3
# Tests: spec/02-pc-panel.md (Column Modes and Widths, Entry Rendering)
#
# Bug: When there are more files than fit in a single column, the
# other columns (2 and 3) remain empty instead of being populated.
#
# Fixture directory + 20 extra files to overflow the first column.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T035"
CASE_DESC="Multi-column overflow fills all columns"

setup() {
  make_fixture_dir
  # Create 20 files so that with ".." we have 21 entries.
  # 17 rows per column means column 1 is full and column 2 must be used.
  for i in $(seq -w 1 20); do
    echo "data" > "$APP_WORKDIR/FILE${i}.TXT"
  done
  app_reset
  send_key
}

run() {
  # Default column mode is 3.  In 3-column mode for the left panel
  # (PanelW=38), dx=(38+1)/3=13, column 2 starts at PosX+1+dx = 2+13 = 15.

  # -----------------------------------------------------------------------
  step 1 "Default 3-column mode: column 2 contains file entries"
  local col2_text
  col2_text=$(rect_text 3 15 17 12)
  if printf '%s' "$col2_text" | grep -qF "FILE"; then
    log_pass "${CASE_ID}_01_3col_col2_has_files" \
      "3-column mode: column 2 contains file entries"
  else
    log_fail "${CASE_ID}_01_3col_col2_has_files" \
      "3-column mode: column 2 is empty"
  fi
  _maybe_dump "${CASE_ID}_01_3col_col2_has_files"

  # -----------------------------------------------------------------------
  step 2 "Ctrl+V cycles to 1-column mode"
  send_key ctrl+v
  # In 1-column mode, only the first 17 entries are visible.
  # The area where column 2 would be (in 3-col mode) now shows
  # the single-column separators, not file entries.
  assert_text_present "${CASE_ID}_02_1col_separator" "│" \
    "1-column mode: single-column separator visible"

  # -----------------------------------------------------------------------
  step 3 "Ctrl+V cycles to 2-column mode: column 2 has files"
  send_key ctrl+v
  # In 2-column mode, dx=PanelW/2=19, column 2 starts at PosX+1+dx = 2+19 = 21.
  local col2_2col_text
  col2_2col_text=$(rect_text 3 21 17 18)
  if printf '%s' "$col2_2col_text" | grep -qF "FILE"; then
    log_pass "${CASE_ID}_03_2col_col2_has_files" \
      "2-column mode: column 2 contains file entries"
  else
    log_fail "${CASE_ID}_03_2col_col2_has_files" \
      "2-column mode: column 2 is empty"
  fi
  _maybe_dump "${CASE_ID}_03_2col_col2_has_files"

  # -----------------------------------------------------------------------
  step 4 "Ctrl+V cycles back to 3-column mode"
  send_key ctrl+v
  local col2_back_text
  col2_back_text=$(rect_text 3 15 17 12)
  if printf '%s' "$col2_back_text" | grep -qF "FILE"; then
    log_pass "${CASE_ID}_04_3col_restored" \
      "3-column mode restored: column 2 contains file entries"
  else
    log_fail "${CASE_ID}_04_3col_restored" \
      "3-column mode restored: column 2 is empty"
  fi
  _maybe_dump "${CASE_ID}_04_3col_restored"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
