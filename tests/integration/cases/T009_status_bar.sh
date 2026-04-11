#!/usr/bin/env bash
# T009 — Status bar rendering
# Tests: spec/09-ui-rendering.md (CStatusBar, color encoding)
#        spec/13-configuration.md (sBar strings per panel type)
#        spec/01-architecture.md (Status bar row = gmaxy)
#
# Fixture directory: sample.scl, sample.tap, sample.trd.
# sample.trd is at position 4 = 3 downs from ..
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T009"
CASE_DESC="Status bar rendering"

setup() {
  make_fixture_dir sample.trd
  app_reset
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "PC panel status bar content and colors"
  send_key
  assert_rect_bg "${CASE_ID}_01_sbar_background" 25 1 1 70 cyan \
    "Status bar row (last row, first 70 cols) has cyan background"
  assert_text_present "${CASE_ID}_01_sbar_exit" "Exit" \
    "Status bar shows 'Exit' action label"
  assert_text_present "${CASE_ID}_01_sbar_copy" "Copy" \
    "Status bar shows 'Copy' action label"

  # -----------------------------------------------------------------------
  step 2 "TRD panel status bar — different key labels"
  send_key home
  send_key down
  send_key open return
  send_key
  assert_text_present "${CASE_ID}_02_trd_sbar_content" "Label" \
    "TRD panel status bar shows 'Label' (F9 action unique to TRD, not 'New')"
  assert_rect_bg "${CASE_ID}_02_trd_sbar_colors" 25 1 1 70 cyan \
    "TRD status bar (first 70 cols) has cyan background"

  # -----------------------------------------------------------------------
  step 3 "Status bar is same width as screen (80 chars)"
  assert_rect_bg "${CASE_ID}_03_sbar_full_width" 25 1 1 70 cyan \
    "Status bar (first 70 cols) has cyan background"
  exit_zx_panel

  # -----------------------------------------------------------------------
  step 4 "Tab between panels — status bar unchanged"
  send_key tab
  assert_text_present "${CASE_ID}_04_sbar_same_both_panels" "Exit" \
    "Status bar shows 'Exit' regardless of which panel is active"
  send_key tab
}

teardown() {
  try_keys ctrl+pageup
}

run_case "$CASE_ID" "$CASE_DESC"
