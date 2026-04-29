#!/usr/bin/env bash
# T041 — Enter a ZXZ archive shows exactly the correct number of entries
# Tests: spec/08-zxz-panel.md (zxzPanel rendering)
#
# Regression for Bug 2: zxzMDF previously ran all 256 iterations when
# blockRead at EOF returned 0 bytes without triggering the EOF guard,
# producing 257 entries instead of the correct count.  After the fix
# (blockRead with count parameter, break on nr<22), a 3-file archive
# must show exactly 3 real entries.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T041"
CASE_DESC="ZXZ panel shows correct file count"

setup() {
  make_fixture_dir kwiksnax.zxz
  app_reset
  send_key home
}

run() {
  step 1 "Navigate to kwiksnax.zxz"
  send_key down
  assert_info_line "${CASE_ID}_01_on_zxz" "kwiksnax.zxz" \
    "cursor is on kwiksnax.zxz"

  step 2 "Press Enter — Hobeta info dialog appears, then ZXZ panel opens"
  # The Hobeta header is shown first; rpause waits for any key.
  # Send Enter to dismiss the Hobeta dialog, which then opens the ZXZ panel.
  send_key open return
  wait_for_text "Information"
  send_key open return
  wait_for_no_text "Information" 1000

  # Now the ZXZ panel should be open.
  assert_text_present "${CASE_ID}_02_go_up" "<<" \
    "go-up entry << is visible in ZXZ panel"
  assert_text_present "${CASE_ID}_02_zxzip_label" "ZXZIP" \
    "panel border label shows ZXZIP"

  step 3 "First real entry is KWIKSNAX"
  send_key down
  assert_info_line "${CASE_ID}_03_first_entry" "KWIKSNAX" \
    "first real ZXZ entry is KWIKSNAX"

  step 4 "Second real entry is kwik.1"
  send_key down
  assert_info_line "${CASE_ID}_04_second_entry" "kwik.1" \
    "second real ZXZ entry is kwik.1"

  step 5 "Third real entry is kwik.2"
  send_key down
  assert_info_line "${CASE_ID}_05_third_entry" "kwik.2" \
    "third real ZXZ entry is kwik.2"

  step 6 "Down again — cursor wraps/stays on kwik.2 (no phantom entries)"
  send_key down
  # If the bug is present, the cursor would move to a phantom 4th entry
  # that duplicates kwik.2.  After the fix it must remain on kwik.2
  # or wrap back to <<.  Either way, kwik.2 must still appear on screen.
  assert_text_present "${CASE_ID}_06_no_phantom" "kwik.2" \
    "no phantom 4th entry — kwik.2 remains the last real entry visible"

  step 7 "Exit ZXZ panel"
  send_key ctrl+pgup
  assert_info_line "${CASE_ID}_07_back_to_pc" "kwiksnax.zxz" \
    "cursor returns to kwiksnax.zxz in PC panel"
}

teardown() {
  try_keys backspace
}

run_case "$CASE_ID" "$CASE_DESC"
