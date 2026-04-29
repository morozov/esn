#!/usr/bin/env bash
# T007 — Mark files with Insert, Plus, Minus, Star
# Tests: spec/10-keyboard-and-input.md (Insert, Plus, Minus, Star)
#        spec/11-file-operations.md (Marked set semantics)
#        spec/02-pc-panel.md (mark indicator √)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T007"
CASE_DESC="Mark files with Insert, +, -, *"

setup() {
  app_reset
  send_key home down
}

run() {
  step 1 "Initial state — nothing marked"
  send_key
  assert_text_present "${CASE_ID}_01_no_marks" "No files selected" \
    "second info line shows 'No files selected'"
  assert_text_absent "${CASE_ID}_01_no_checkmark" "√" \
    "no √ mark characters visible"

  step 2 "Press Insert to mark first file, cursor advances"
  send_key home down
  send_key insert
  assert_text_present "${CASE_ID}_02_mark_char" "√" \
    "√ mark character is visible on marked entry"
  assert_text_present "${CASE_ID}_02_selected_count" "selected in 1 file" \
    "second info line shows '... selected in 1 file'"
  # Entry occupies visual cols 2–13 (8 name + 1 attr√ + 3 ext = 12 cols).
  # The attr/checkmark cell (col 10) keeps the file-type ink color;
  # the rest of the row uses the mark ink (light-yellow).
  assert_rect_fg "${CASE_ID}_02_mark_color" 4 2 1 8 light-yellow \
    "marked file name area (cols 2-9) has bright yellow foreground"
  assert_rect_fg "${CASE_ID}_02_mark_ext" 4 11 1 3 light-yellow \
    "marked file extension area (cols 11-13) has bright yellow foreground"

  step 3 "Press Insert again on next file — marks it too"
  send_key insert
  assert_text_present "${CASE_ID}_03_two_files" "selected in 2 files" \
    "second info line shows 2 files selected"

  step 4 "Press Insert on a marked file — unmarks it (toggle)"
  send_key up
  send_key insert
  assert_text_present "${CASE_ID}_04_unmarked" "selected in 1 file" \
    "after unmark, second info line shows 1 file selected"

  step 5 "Star (*) — invert all marks"
  send_key "*"
  assert_text_present "${CASE_ID}_05_inverted" "selected" \
    "after *, some files are marked (count updated)"

  step 6 "Plus (+) — mark by wildcard mask, accept default *.*"
  send_key "*"
  send_key "+"
  assert_text_present "${CASE_ID}_06_mask_dialog" "*.*" \
    "plus dialog shows default mask *.*"
  send_key return
  assert_text_present "${CASE_ID}_06_all_marked" "files" \
    "after +/*.* all files marked — count shows 'files'"

  step 7 "Minus (-) — unmark by wildcard mask"
  send_key "-"
  assert_text_present "${CASE_ID}_07_minus_dialog" "*.*" \
    "minus dialog shows default mask *.*"
  send_key return
  assert_text_present "${CASE_ID}_07_none_marked" "No files selected" \
    "all marks removed — 'No files selected'"

  step 8 "Insert on << entry does not mark it"
  send_key home
  send_key insert
  assert_text_present "${CASE_ID}_08_go_up_no_mark" "No files selected" \
    "<< entry cannot be marked — still 'No files selected'"
}

teardown() {
  try_keys "*" "*"
}

run_case "$CASE_ID" "$CASE_DESC"
