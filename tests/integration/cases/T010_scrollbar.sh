#!/usr/bin/env bash
# T010 — Scrollbar rendering
# Tests: spec/09-ui-rendering.md (Scrollbar Rendering — Info part 'b')
#        spec/01-architecture.md (PanelHi, from, f, tdirs, tfiles)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T010"
CASE_DESC="Scrollbar in focused and unfocused panels"

setup() {
  app_reset
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Left panel focused — scrollbar details at top of list"
  send_key home
  send_key
  assert_text_present "${CASE_ID}_01_up_arrow" "▲" \
    "Left panel scrollbar shows ▲ up arrow (focused, at top of list)"
  assert_text_present "${CASE_ID}_01_down_arrow" "▼" \
    "Left panel scrollbar shows ▼ down arrow"
  assert_text_present "${CASE_ID}_01_thumb" "■" \
    "Left panel scrollbar shows ■ thumb"
  assert_text_present "${CASE_ID}_01_track" "▒" \
    "Left panel scrollbar shows ▒ track characters"

  # -----------------------------------------------------------------------
  step 2 "Scrollbar thumb moves as cursor moves down"
  send_key pagedown
  assert_text_present "${CASE_ID}_02a_thumb_middle" "■" \
    "After PgDn, thumb ■ is still present (moved toward middle)"

  send_key end
  assert_text_present "${CASE_ID}_02b_thumb_bottom" "■" \
    "After End, thumb ■ is still present (near bottom)"

  # -----------------------------------------------------------------------
  step 3 "Tab to right panel — scrollbar focus transfers"
  send_key tab
  assert_text_present "${CASE_ID}_03_right_focused_scrollbar" "▲" \
    "Right panel scrollbar now shows ▲ (focused state)"

  # -----------------------------------------------------------------------
  step 4 "Return focus to left panel"
  send_key tab
}

teardown() {
  try_keys tab
}

run_case "$CASE_ID" "$CASE_DESC"
