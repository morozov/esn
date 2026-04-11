#!/usr/bin/env bash
# T037 — Marks must not persist when navigating to a different directory
# Tests: spec/02-pc-panel.md (mark persistence)
#
# Bug: marking files in one directory, navigating into a subdirectory
# and back, caused the marks to reappear on files with the same name
# because pcMDF unconditionally restored saved CRC16 hashes.  The
# original guards this with "if path=nd" — marks are only restored
# when re-reading the *same* directory.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T037"
CASE_DESC="Marks clear when navigating away"

setup() {
  make_fixture_dir sample.trd
  mkdir "$_FIXTURE_DIR/SUB"
  # Create a file in SUB with the same name as one in the parent.
  cp "$_FIXTURE_DIR/sample.trd" "$_FIXTURE_DIR/SUB/sample.trd"
  app_reset
  send_key home
}

run() {
  step 1 "Mark sample.trd in the parent directory"
  send_key down down
  send_insert
  assert_text_present "${CASE_ID}_01_marked" "selected in 1 file" \
    "one file is marked"

  step 2 "Enter the SUB directory"
  send_key home down
  send_key return
  assert_text_present "${CASE_ID}_02_in_sub" "No files selected" \
    "no marks in the subdirectory despite same-name file"
  assert_text_absent "${CASE_ID}_02_no_checkmark" "√" \
    "no √ mark character visible in subdirectory"

  step 3 "Navigate back up to the parent"
  send_key home
  send_key return
  assert_text_present "${CASE_ID}_03_no_marks" "No files selected" \
    "marks are gone after navigating back"
  assert_text_absent "${CASE_ID}_03_no_checkmark" "√" \
    "no √ mark characters visible in parent"
}

teardown() {
  try_keys "*" "*"
}

run_case "$CASE_ID" "$CASE_DESC"
