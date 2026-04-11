#!/usr/bin/env bash
# T034 — Deleting a file refreshes the other panel when both show the same dir
# Tests: spec/11-file-operations.md (Del function)
#        spec/02-pc-panel.md (panel refresh after file operations)
#
# Bug: When both panels point at the same directory and a file is deleted
# in one panel, the other panel still shows the deleted file.
#
# Fixture directory + one extra file (DELME.TXT) to delete.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T034"
CASE_DESC="Delete refreshes other panel showing same directory"

setup() {
  make_fixture_dir
  echo "test" > "$APP_WORKDIR/DELME.TXT"
  app_reset
}

run() {
  # Panel columns: left panel occupies cols 1-40, right panel cols 41-80.
  # File listing rows start at row 3 and extend to row 19 (17 rows).

  # -----------------------------------------------------------------------
  step 1 "Temp file is visible in the left (active) panel"
  assert_rect_contains "${CASE_ID}_01_left_has_file" 3 1 17 40 "DELME" \
    "Left panel shows the temp file"

  # -----------------------------------------------------------------------
  step 2 "Temp file is also visible in the right (inactive) panel"
  assert_rect_contains "${CASE_ID}_02_right_has_file" 3 41 17 40 "DELME" \
    "Right panel also shows the temp file"

  # -----------------------------------------------------------------------
  step 3 "Navigate to the temp file and delete it"
  # DELME.TXT has priority 10, so it sorts after the ZX images.
  # It is the last entry.
  send_key home end
  send_key open f8
  assert_text_present "${CASE_ID}_03_dialog" "Confirmation" \
    "Confirmation dialog appears"
  send_key fileop return
  assert_text_absent "${CASE_ID}_03_dialog_gone" "Confirmation" \
    "Dialog has closed after confirming"

  # -----------------------------------------------------------------------
  step 4 "Deleted file is gone from the left (active) panel"
  local left_text
  left_text=$(rect_text 3 1 17 40)
  if printf '%s' "$left_text" | grep -qF "DELME"; then
    log_fail "${CASE_ID}_04_left_gone" \
      "Left panel still shows deleted file"
  else
    log_pass "${CASE_ID}_04_left_gone" \
      "Left panel no longer shows the deleted file"
  fi
  _maybe_dump "${CASE_ID}_04_left_gone"

  # -----------------------------------------------------------------------
  step 5 "Deleted file is also gone from the right (inactive) panel"
  local right_text
  right_text=$(rect_text 3 41 17 40)
  if printf '%s' "$right_text" | grep -qF "DELME"; then
    log_fail "${CASE_ID}_05_right_gone" \
      "Right panel still shows the deleted file"
  else
    log_pass "${CASE_ID}_05_right_gone" \
      "Right panel no longer shows the deleted file"
  fi
  _maybe_dump "${CASE_ID}_05_right_gone"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
