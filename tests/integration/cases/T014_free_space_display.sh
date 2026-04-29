#!/usr/bin/env bash
# T014 — Free space line formats
# Tests: spec/02-pc-panel.md (Free Space Line info part 'f')
#        spec/03-trd-panel.md (Disk Info Line, free sectors)
#        spec/14-known-quirks.md (Q1: 'G' label = MB quirk, Q4: -1 guard)
#
# Fixture directory: sample.scl, sample.tap, sample.trd.
# sample.trd is at position 4 = 3 downs from ..
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T014"
CASE_DESC="Free space line formats"

setup() {
  make_fixture_dir sample.scl sample.tap sample.trd
  app_reset
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "PC panel — free space line"
  send_key
  assert_text_present "${CASE_ID}_01_pc_free_format" " free" \
    "Third info line in pcPanel shows free space"

  # -----------------------------------------------------------------------
  step 2 "Free space is non-negative"
  assert_text_absent "${CASE_ID}_02_no_negative" "-1" \
    "Free space is never shown as negative"

  # -----------------------------------------------------------------------
  step 3 "TRD panel — free sectors display"
  send_key home
  send_key down down down
  send_key open return
  send_key
  assert_text_present "${CASE_ID}_03_trd_free_format" "blocks free" \
    "Third info line in trdPanel shows 'blocks free'"
  assert_text_absent "${CASE_ID}_03_trd_no_drive_label" "drive" \
    "TRD free line does NOT show 'drive' — only block count"

  # -----------------------------------------------------------------------
  step 4 "SCL panel — total files display"
  send_key ctrl+pgup
  send_key home
  send_key down
  send_key open return
  send_key
  assert_text_present "${CASE_ID}_04_scl_free_format" "Total" \
    "Third info line in sclPanel shows 'Total' file count"

  # -----------------------------------------------------------------------
  step 5 "TAP panel — total items display"
  send_key ctrl+pgup
  send_key down
  send_key open return
  send_key
  assert_text_present "${CASE_ID}_05_tap_free_format" "Total" \
    "Third info line in tapPanel shows 'Total' entry count"

  # Return to PC panel
  send_key ctrl+pgup
}

teardown() {
  try_keys ctrl+pageup
  try_keys ctrl+pageup
}

run_case "$CASE_ID" "$CASE_DESC"
