#!/usr/bin/env bash
# T001 — Initial screen on launch
# Tests: spec/01-architecture.md (Screen Layout, Clock, Status bar)
#        spec/09-ui-rendering.md (Color palette, Status bar)
#        spec/13-configuration.md (Startup defaults)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T001"
CASE_DESC="Initial screen on launch"

setup() {
  app_reset
}

run() {
  step 1 "Capture idle startup state (no keys pressed)"
  send_key

  assert_text_present "${CASE_ID}_01_dual_panels" "╔" \
    "panel border visible — dual-panel layout rendered"

  assert_text_present "${CASE_ID}_01_panel_borders" "╚" \
    "bottom border characters present"

  assert_text_present "${CASE_ID}_01_scrollbar" "▲" \
    "focused panel scrollbar has up-arrow (▲)"

  assert_text_present "${CASE_ID}_01_track" "▒" \
    "scrollbar track character (▒) present"

  assert_text_present "${CASE_ID}_01_parent_dir" ".." \
    "parent directory entry (..) visible in left panel"

  assert_text_present "${CASE_ID}_01_no_selection" "No files selected" \
    "second info line shows 'No files selected'"

  assert_text_present "${CASE_ID}_01_free_space" "bytes free" \
    "third info line shows free space"

  assert_text_present "${CASE_ID}_01_status_exit" "Exit" \
    "status bar shows Exit label"

  assert_text_present "${CASE_ID}_01_status_copy" "Copy" \
    "status bar shows Copy label (F5)"

  assert_rect_bg "${CASE_ID}_01_status_bar_bg" 25 1 1 70 cyan \
    "status bar (row 25, first 70 cols) has cyan background"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
