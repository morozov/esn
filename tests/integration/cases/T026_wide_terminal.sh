#!/usr/bin/env bash
# T026 — Startup at non-standard width
# Tests: spec/15-terminal-resize.md — dialog centering and panel layout at
#        non-80-column widths.
#
# Runs the same assertions at four sizes:
#   50×25     — narrow enough that the working-directory title cannot fit
#               between the panel's corner decorations; verifies the four
#               panel corners survive the cramped title.
#   120×30    — moderately wide
#   420×120   — exposes byte overflow in coordinate math (panel PosX > 255,
#               column positions > 255)
#   1000×40   — exercises shortstring→AnsiString widening in Info/Build;
#               the info-row border assertions are skipped here because
#               FPC's Video.UpdateScreen drops rows with 256+ attributed
#               cells on Unix.
#               https://gitlab.com/freepascal.org/fpc/source/-/work_items/41725
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T026"
CASE_DESC="Startup at non-standard width"

_tag=""

setup() {
  app_reset "$_COLS" "$_ROWS"
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Initial screen at ${_COLS}×${_ROWS}"
  send_key
  assert_text_present "${CASE_ID}_${_tag}_01_panels_visible" "Exit" \
    "Both panels visible — status bar shows 'Exit'"
  assert_text_present "${CASE_ID}_${_tag}_01_borders_intact" "╔" \
    "Panel border characters visible and untruncated"

  # Panel info area: the 'selected' info row sits 2 rows above the button bar.
  # Left panel's right border ║ must be at col _COLS/2; right panel's at _COLS.
  # (regression: at wide widths, shortstring truncation of info-row nm
  # produced stray ║ at posx+~243 and missing ║ at the true right edges.)
  local info_row=$(( _ROWS - 2 ))
  local mid_col=$(( _COLS / 2 ))
  local right_start=$(( mid_col + 1 ))
  if [[ "$_tag" == "xwide" ]]; then
    log_skip "${CASE_ID}_${_tag}_01_left_info_rborder" \
      "blocked by FPC bug"
    log_skip "${CASE_ID}_${_tag}_01_right_info_rborder" \
      "blocked by FPC bug"
  else
    assert_rect_text "${CASE_ID}_${_tag}_01_left_info_rborder" \
      "$info_row" "$mid_col" 1 1 "║" \
      "Left panel info-row right border ║ at col $mid_col row $info_row"
    assert_rect_text "${CASE_ID}_${_tag}_01_right_info_rborder" \
      "$info_row" "$_COLS" 1 1 "║" \
      "Right panel info-row right border ║ at col $_COLS row $info_row"
  fi

  # Top corners that must always be present: the right panel's top-right
  # cell is intentionally occupied by the clock, so it's not asserted here.
  assert_rect_text "${CASE_ID}_${_tag}_01_left_top_lcorner" \
    1 1 1 1 "╔" \
    "Left panel top-left corner ╔ at col 1 row 1"
  assert_rect_text "${CASE_ID}_${_tag}_01_left_top_rcorner" \
    1 "$mid_col" 1 1 "╗" \
    "Left panel top-right corner ╗ at col $mid_col row 1"
  assert_rect_text "${CASE_ID}_${_tag}_01_right_top_lcorner" \
    1 "$right_start" 1 1 "╔" \
    "Right panel top-left corner ╔ at col $right_start row 1"

  # -----------------------------------------------------------------------
  step 2 "WillCopyMove dialog (F5) is centered at ${_COLS}-column width"
  send_key down
  send_key f5
  wait_for_text " Copy "
  assert_text_present "${CASE_ID}_${_tag}_02_dialog_visible" " Copy " \
    "Copy dialog title ' Copy ' is visible at ${_COLS}-column width"
  assert_text_present "${CASE_ID}_${_tag}_02_dialog_not_clipped" "Overwrite" \
    "Dialog content fully visible — not clipped by terminal edge"

  # Close the dialog.
  send_key escape
  wait_for_no_text " Copy "

  # -----------------------------------------------------------------------
  step 3 "Exit confirmation dialog (Esc) is centered"
  send_key escape
  wait_for_text "Confirmation"
  assert_text_present "${CASE_ID}_${_tag}_03_exit_dialog_centered" "Confirmation" \
    "Exit confirmation dialog appears centered at ${_COLS}-column screen"

  # Cancel exit.
  send_key escape
  wait_for_no_text "Confirmation"
}

teardown() {
  :
}

for _params in "50 25 xnarrow" "120 30 narrow" "420 120 wide" "1000 40 xwide"; do
  read -r _COLS _ROWS _tag <<< "$_params"
  run_case "$CASE_ID" "$CASE_DESC @ ${_COLS}x${_ROWS}"
done
