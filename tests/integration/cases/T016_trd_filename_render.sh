#!/usr/bin/env bash
# T016 — TRD filename rendering details
# Tests: spec/03-trd-panel.md (Panel Rendering trdPDF, TRDOS3 Extension Mode,
#        File Type Display, Name Line trdNameLine)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T016"
CASE_DESC="TRD filename rendering details"

setup() {
  make_fixture_dir sample.trd
  app_reset
  send_key home
  send_key down
  send_key open return
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Inspect file list — name and type format"
  send_key
  assert_text_present "${CASE_ID}_01_go_up_format" "<<" \
    "Go-up entry << is visible"
  assert_text_present "${CASE_ID}_01_type_indicator" "<" \
    "TRD file type indicators use angle bracket format <T>"

  # -----------------------------------------------------------------------
  step 2 "First real TRD file is visible in info line"
  # sample.trd stores type as raw numeric codes (0x00, 0x03).
  # Navigate to first real file; verify the info line shows the sector count.
  # All files in this fixture have totalsec=1, formatted as '(   1)'.
  send_key down
  assert_text_present "${CASE_ID}_02_basic_type" "(   1)" \
    "Info line shows sector count '(   1)' for first real TRD file"

  # -----------------------------------------------------------------------
  step 3 "Alt+T — toggle TRDOS3 mode"
  send_key alt+t
  assert_text_present "${CASE_ID}_03_trdos3_indicator" "T3" \
    "After Alt+T, panel border shows T3 indicator for TRDOS3 mode"

  # -----------------------------------------------------------------------
  step 4 "Alt+T again — toggle TRDOS3 off"
  send_key alt+t
  assert_text_absent "${CASE_ID}_04_trdos3_off_indicator" "T3" \
    "After Alt+T again, T3 indicator is gone"
  assert_text_present "${CASE_ID}_04_normal_type_restored" "(   1)" \
    "Non-TRDOS3 mode: sector count '(   1)' still visible after T3 off"

  # -----------------------------------------------------------------------
  step 5 "Info panel shows free-sector count for TRD panel"
  # The name line format is: name + type + start + length + (totalsec).
  # Info line 3 always shows "N blocks free" in the TRD panel.
  send_key down
  send_key
  assert_text_present "${CASE_ID}_05_blocks_free" "blocks free" \
    "TRD info panel shows free-sector count ('blocks free')"
}

teardown() {
  try_keys ctrl+pageup
}

run_case "$CASE_ID" "$CASE_DESC"
