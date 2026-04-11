#!/usr/bin/env bash
# T026 — Startup at non-standard width (120×30)
# Tests: spec/15-terminal-resize.md — dialog centering and panel layout at
#        non-80-column width.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T026"
CASE_DESC="Startup at non-standard width (120x30)"

setup() {
  app_reset 120 30
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Initial screen at 120×30"
  send_key
  assert_text_present "${CASE_ID}_01_panels_visible" "Exit" \
    "Both panels visible — status bar shows 'Exit'"
  assert_text_present "${CASE_ID}_01_borders_intact" "╔" \
    "Panel border characters visible and untruncated"

  # -----------------------------------------------------------------------
  step 2 "WillCopyMove dialog (F5) is centered at 120-column width"
  send_key down
  send_key f5
  wait_for_text " Copy "
  assert_text_present "${CASE_ID}_02_dialog_visible" " Copy " \
    "Copy dialog title ' Copy ' is visible at 120-column width"
  assert_text_present "${CASE_ID}_02_dialog_not_clipped" "Overwrite" \
    "Dialog content fully visible — not clipped by terminal edge"

  # Close the dialog.
  send_key escape
  wait_for_no_text " Copy "

  # -----------------------------------------------------------------------
  step 3 "Exit confirmation dialog (Esc) is centered"
  send_key escape
  wait_for_text "Confirmation"
  assert_text_present "${CASE_ID}_03_exit_dialog_centered" "Confirmation" \
    "Exit confirmation dialog appears centered at 120-column screen"

  # Cancel exit.
  send_key escape
  wait_for_no_text "Confirmation"
}

teardown() {
  :
}

run_case "$CASE_ID" "$CASE_DESC"
