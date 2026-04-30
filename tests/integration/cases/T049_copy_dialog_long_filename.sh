#!/usr/bin/env bash
# T049 — Copy/move dialog truncates long PC filenames
# Tests: spec/12-dialogs.md (WillCopyMove status line layout)
#
# When a PC file with a name wider than the dialog interior is selected
# and F5/F6 is pressed, the status line that announces the operation
# must not overflow the dialog right border.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T049"
CASE_DESC="Copy/move dialog truncates long PC filenames"

# Long ASCII filename (100 chars) — far wider than the 53-cell status
# row.  The trailing `.tap` is what the truncation must keep visible:
# the lead/tail split exists so the file extension survives.
LONG_NAME="aaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeeeffffffffffgggggggggghhhhhhhhhhiiiiiiiiiijjjjjj.tap"

setup() {
  make_fixture_dir
  : > "${APP_WORKDIR}/${LONG_NAME}"
  app_reset
  send_key
}

# WillCopyMove dialog geometry on 80x25 (HalfMaxX=40, HalfMaxY=12):
#   left  border ║ at col 12   row 9
#   right border ║ at col 69   row 9
#   status line drawn at      col 15   row 9   (52 cells, aligned
#                                                with the input field
#                                                at row 10)
DIALOG_ROW=9
DIALOG_RIGHT_BORDER_COL=69
DIALOG_INTERIOR_RIGHT_COL=68
DIALOG_STATUS_COL=15
DIALOG_STATUS_WIDTH=54

# Helper: assert the dialog's right vertical border is intact on the
# status row (one cell wide).
assert_right_border_intact() {
  local test_id="$1" desc="$2"
  assert_rect_text "$test_id" "$DIALOG_ROW" "$DIALOG_RIGHT_BORDER_COL" 1 1 "║" \
    "$desc"
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Move to the long-named file in the left panel"
  send_key home
  send_key down
  assert_text_present "${CASE_ID}_01_file_visible" "aaaaaaaaaa" \
    "Long filename appears in the panel listing"

  # -----------------------------------------------------------------------
  step 2 "Press F5 — Copy dialog opens"
  send_key open f5
  wait_for_text " Copy "
  assert_text_present "${CASE_ID}_02_copy_title" " Copy " \
    "Copy dialog title is visible"

  step 3 "Status line stays inside the dialog right border"
  assert_right_border_intact "${CASE_ID}_03a_copy_right_border" \
    "Right border ║ is intact at the status row (Copy dialog)"
  assert_text_present "${CASE_ID}_03b_copy_ellipsis" "..." \
    "Long filename is visibly truncated with an ellipsis"
  # The first 4 characters of the long name must be visible — i.e. the
  # leading filename text was preserved after truncation.
  assert_rect_contains "${CASE_ID}_03c_copy_lead_visible" \
    "$DIALOG_ROW" "$DIALOG_STATUS_COL" 1 "$DIALOG_STATUS_WIDTH" "aaaa" \
    "Leading characters of the long filename remain visible"
  # The extension at the tail of the long name must survive truncation —
  # this is the property the lead/tail split exists to guarantee.
  assert_rect_contains "${CASE_ID}_03d_copy_ext_visible" \
    "$DIALOG_ROW" "$DIALOG_STATUS_COL" 1 "$DIALOG_STATUS_WIDTH" ".tap" \
    "File extension at the tail of the long name remains visible"
  # The status line must start in the same column as the input field
  # below (col 15) — the cell to its left must be empty.
  assert_rect_text "${CASE_ID}_03e_copy_align_left" \
    "$DIALOG_ROW" "$DIALOG_STATUS_COL" 1 1 "C" \
    "Status line begins at col $DIALOG_STATUS_COL (aligned with input)"

  send_key escape
  wait_for_no_text " Copy "

  # -----------------------------------------------------------------------
  step 4 "Press F6 — Rename/Move dialog opens with the same constraint"
  send_key open f6
  wait_for_text "Rename/Move"
  assert_text_present "${CASE_ID}_04_move_title" "Rename/Move" \
    "Rename/Move dialog title is visible"

  step 5 "Status line stays inside the dialog right border"
  assert_right_border_intact "${CASE_ID}_05a_move_right_border" \
    "Right border ║ is intact at the status row (Rename/Move dialog)"
  assert_text_present "${CASE_ID}_05b_move_ellipsis" "..." \
    "Long filename is visibly truncated with an ellipsis"
  assert_rect_contains "${CASE_ID}_05c_move_lead_visible" \
    "$DIALOG_ROW" "$DIALOG_STATUS_COL" 1 "$DIALOG_STATUS_WIDTH" "aaaa" \
    "Leading characters of the long filename remain visible"
  assert_rect_contains "${CASE_ID}_05d_move_ext_visible" \
    "$DIALOG_ROW" "$DIALOG_STATUS_COL" 1 "$DIALOG_STATUS_WIDTH" ".tap" \
    "File extension at the tail of the long name remains visible"
  assert_rect_text "${CASE_ID}_05e_move_align_left" \
    "$DIALOG_ROW" "$DIALOG_STATUS_COL" 1 1 "R" \
    "Status line begins at col $DIALOG_STATUS_COL (aligned with input)"

  send_key escape
  wait_for_no_text "Rename/Move"
}

teardown() {
  try_keys escape escape
}

run_case "$CASE_ID" "$CASE_DESC"
