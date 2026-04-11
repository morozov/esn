#!/usr/bin/env bash
# T040 — Alt+S local find moves cursor to matching file
# Tests: sn_obj.pas (LocalFind)
#
# Bug 1 (port): LocalFind modified generic f/from fields then
# called Inside, which overwrote them with stale per-type values.
#
# Bug 2 (original): backspace only deleted from the search string
# but left the cursor at its advanced position, making it
# impossible to find files that precede the current entry.
#
# Fixture directory: default fixtures (sample.scl, empty.tap, etc.)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T040"
CASE_DESC="Alt+S local find moves cursor to matching file"

setup() {
  app_reset
  send_key home
}

run() {
  step 1 "Type 's' to search — cursor moves to sample.scl"
  send_key settle alt+s
  tmux send-keys -t esn_test -l 's' 2>/dev/null || true
  sleep 0.5
  send_key escape

  assert_info_line "${CASE_ID}_01_cursor" "sample.scl" \
    "cursor landed on sample.scl"

  step 2 "Backspace + retype — cursor moves to earlier file"
  # Search for 's' again (cursor now on sample.scl), then
  # backspace to clear, then type 'e' — should find empty.tap
  # which is BEFORE sample.scl in sort order.
  send_key settle alt+s
  tmux send-keys -t esn_test -l 's' 2>/dev/null || true
  sleep 0.3
  tmux send-keys -t esn_test BSpace 2>/dev/null || true
  sleep 0.3
  tmux send-keys -t esn_test -l 'e' 2>/dev/null || true
  sleep 0.5
  send_key escape

  assert_info_line "${CASE_ID}_02_backspace" "empty.tap" \
    "backspace + retype found earlier file empty.tap"

  step 3 "Non-matching character is rejected"
  send_key settle alt+s
  tmux send-keys -t esn_test -l 'z' 2>/dev/null || true
  sleep 0.3
  _screen_invalidate

  local input_field
  input_field=$(rect_text 23 19 1 13)
  if echo "$input_field" | grep -qF 'z'; then
    log_fail "${CASE_ID}_03_rejected" \
      "non-matching character 'z' was rejected — 'z' found in input field: '$input_field'"
  else
    log_pass "${CASE_ID}_03_rejected" \
      "non-matching character 'z' was rejected"
  fi

  send_key escape
}

teardown() { :; }

# ---------------------------------------------------------------------------
source "$(dirname "${BASH_SOURCE[0]}")/../lib/app.sh"
run_case "$CASE_ID" "$CASE_DESC"
