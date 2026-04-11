#!/usr/bin/env bash
# T011 — Column mode switching
# Tests: spec/02-pc-panel.md (Column Modes and Widths, Entry Rendering)
#        spec/10-keyboard-and-input.md (Ctrl+V = PCOLUMNS)
#        spec/01-architecture.md (TPanel.Columns field)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T011"
CASE_DESC="Column mode switching (1, 2, 3 columns)"

setup() {
  app_reset
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Default state — 1-column mode"
  send_key
  assert_text_present "${CASE_ID}_01_single_column" "│" \
    "Left panel shows single-column separator │"

  # -----------------------------------------------------------------------
  step 2 "Ctrl+V — switch to 2-column mode"
  send_key ctrl+v
  assert_text_present "${CASE_ID}_02_two_columns" "║" \
    "After Ctrl+V, left panel shows double separator ║ (2-column mode)"

  # -----------------------------------------------------------------------
  step 3 "Ctrl+V again — switch to 3-column mode"
  send_key ctrl+v
  assert_text_present "${CASE_ID}_03_three_columns" "║" \
    "3-column mode: double separator ║ still visible"

  # -----------------------------------------------------------------------
  step 4 "Ctrl+V again — cycles back to 1-column mode"
  send_key ctrl+v
  assert_text_present "${CASE_ID}_04_single_column_restored" "│" \
    "Single-column separator │ restored after cycling back"

  # -----------------------------------------------------------------------
  step 5 "Right panel column mode is independent"
  send_key tab
  send_key ctrl+v
  assert_text_present "${CASE_ID}_05_right_2col_left_1col" "║" \
    "Right panel shows ║ (2-column mode) while left stays 1-column"

  # Restore
  send_key ctrl+v
  try_keys tab
}

teardown() {
  try_keys tab
}

run_case "$CASE_ID" "$CASE_DESC"
