#!/usr/bin/env bash
# T033 — Copy all marked TRD files to a new TAP image
# Tests: spec/11-file-operations.md (snCopier, multi-file marked copy)
#        spec/04-tap-panel.md (TAP block structure)
#
# Verifies that copying all marked TRD files to a new TAP image
# produces the expected number of TAP blocks (header + data per file).
#
# Fixture directory: sample.scl, sample.tap, sample.trd.
# After creating DEST.TAP via F9:
#   [1].. [2]sample.scl [3]sample.tap [4]sample.trd [5]dest.tap
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T033"
CASE_DESC="Copy all marked TRD files to new TAP"

setup() {
  make_fixture_dir sample.scl sample.tap sample.trd
  app_reset
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Create a new TAP via F9"
  send_key home
  send_key open f9
  # TAP is item 5 in the MakeImages menu
  send_key down down down down
  send_key open return
  assert_text_present "${CASE_ID}_01_tap_dialog" "New TAP" \
    "New TAP-file dialog appears"

  send_key d
  send_key e
  send_key s
  send_key t
  send_key fileop return
  assert_text_present "${CASE_ID}_01_tap_created" "dest" \
    "DEST.TAP appears in directory listing"

  # -----------------------------------------------------------------------
  step 2 "Open dest.tap in right panel"
  # [1].. [2]sample.scl [3]dest.tap [4]sample.tap [5]sample.trd
  send_key tab
  send_key home
  send_key down down
  send_key open return
  assert_text_present "${CASE_ID}_02_right_is_tap" "Tape" \
    "Right panel is inside DEST.TAP (Tape header visible)"

  # -----------------------------------------------------------------------
  step 3 "Open sample.trd in left panel"
  send_key tab
  send_key end
  send_key open return
  assert_text_present "${CASE_ID}_03_left_is_trd" "TRD" \
    "Left panel is inside sample.trd (TRD header visible)"

  # -----------------------------------------------------------------------
  step 4 "Mark ALL files with * (invert selection)"
  send_key "*"
  assert_text_present "${CASE_ID}_04_marked" "files" \
    "Info line shows files selected"

  # -----------------------------------------------------------------------
  step 5 "F5 copy marked files to TAP"
  send_key open f5
  assert_text_present "${CASE_ID}_05_dialog" " Copy " \
    "WillCopyMove dialog appears"

  send_key fileop return
  assert_text_absent "${CASE_ID}_05_done" "To:" \
    "Copy dialog closed"

  # -----------------------------------------------------------------------
  step 6 "Verify TAP has all files"
  # sample.trd has 3 files. Each produces 2 TAP blocks (header + body).
  # Expected: 6 blocks total, shown as "Total 3 files" in TAP info line.
  send_key tab
  assert_text_present "${CASE_ID}_06_total_files" "Total 3 files" \
    "TAP shows Total 3 files (all TRD entries copied)"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
