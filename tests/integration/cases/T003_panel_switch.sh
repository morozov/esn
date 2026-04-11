#!/usr/bin/env bash
# T003 — Tab between panels
# Tests: spec/10-keyboard-and-input.md (Focus Switch / TAB)
#        spec/09-ui-rendering.md (Scrollbar rendering, focused vs unfocused)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T003"
CASE_DESC="Tab between panels"

setup() {
  app_reset
  send_key home
}

run() {
  step 1 "Initial state — left panel focused"
  send_key
  assert_text_present "${CASE_ID}_01_up_arrow" "▲" \
    "left panel scrollbar has up arrow (focused)"
  assert_text_present "${CASE_ID}_01_track" "▒" \
    "scrollbar track character present"
  assert_info_line "${CASE_ID}_01_cursor" ".." \
    "info line shows left panel cursor entry (..)"

  step 2 "Press Tab — focus moves to right panel"
  send_key tab
  assert_text_present "${CASE_ID}_02_up_arrow" "▲" \
    "right panel scrollbar now has up arrow (focused)"
  assert_info_line "${CASE_ID}_02_right_cursor" ".." \
    "right panel cursor on first entry"

  step 3 "Press Tab again — focus returns to left panel"
  send_key tab
  assert_text_present "${CASE_ID}_03_up_arrow" "▲" \
    "left panel scrollbar has up arrow again (refocused)"
  assert_info_line "${CASE_ID}_03_left_cursor" ".." \
    "left panel cursor preserved"

  step 4 "Tab twice rapidly — ends back on right"
  send_key tab tab
  assert_info_line "${CASE_ID}_04_right" ".." \
    "after two tabs, right panel is focused (cursor on first entry)"
}

teardown() {
  try_keys tab tab
}

run_case "$CASE_ID" "$CASE_DESC"
