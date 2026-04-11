#!/usr/bin/env bash
# T036 — Create and open an FDD disk image
# Tests: spec/07-fdd-panel.md (FDD format, fddPanel)
#
# Bug: (1) F9 creates an invalid empty FDD image that the original
# program cannot open. (2) The port cannot open its own FDD images.
#
# Fixture directory: sample.scl, sample.tap, sample.trd.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T036"
CASE_DESC="Create and open an FDD disk image"

FDD_FILE=""

setup() {
  make_fixture_dir
  FDD_FILE="$APP_WORKDIR/TEST.FDD"
  app_reset
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "F9 on pcPanel — select FDD (item 3)"
  send_key home
  send_key open f9
  assert_text_present "${CASE_ID}_01_menu" "FDD" \
    "MakeImages menu shows FDD option"

  send_key down down
  send_key open return
  assert_text_present "${CASE_ID}_01_dialog" "New FDD" \
    "New FDD-file dialog appears"

  # Type filename, Tab to tracks field, Enter to accept defaults.
  send_key t
  send_key e
  send_key s
  send_key t
  send_key tab
  send_key fileop return

  # -----------------------------------------------------------------------
  step 2 "FDD file was created on disk"
  if [[ -f "$FDD_FILE" ]]; then
    local sz
    sz=$(wc -c < "$FDD_FILE")
    log_pass "${CASE_ID}_02_file_exists" \
      "TEST.FDD exists on disk ($sz bytes)"
  else
    log_fail "${CASE_ID}_02_file_exists" \
      "TEST.FDD not found"
    return
  fi

  # -----------------------------------------------------------------------
  step 3 "FDD file has valid SPM DISK signature"
  local sig
  sig=$(head -c 8 "$FDD_FILE")
  if [[ "$sig" == "SPM DISK" ]]; then
    log_pass "${CASE_ID}_03_signature" \
      "FDD file starts with 'SPM DISK' signature"
  else
    log_fail "${CASE_ID}_03_signature" \
      "FDD file does not start with 'SPM DISK' (got: '$sig')"
  fi

  # -----------------------------------------------------------------------
  step 4 "Navigate to the FDD file and open it"
  # FDD extension is not in the priority-1 group, so TEST.FDD sorts
  # after the ZX images.  Use End to jump to the last file.
  send_key home end
  send_key open return

  # If the panel opened, it should show the FDD panel type in the
  # title bar and the << go-up entry.
  assert_text_present "${CASE_ID}_04_fdd_panel" "FDD" \
    "Panel border shows FDD type"
  assert_text_present "${CASE_ID}_04_go_up" "<<" \
    "Go-up entry << is visible inside the FDD image"

  # -----------------------------------------------------------------------
  step 5 "Empty FDD has no ghost entries"
  # Only << should be visible in the file list area.
  # The type indicator < > appears for every ZX entry; an empty
  # image must have exactly one (the << go-up entry has no < >).
  assert_text_absent "${CASE_ID}_05_no_ghosts" "< >" \
    "No ghost directory entries in the empty FDD image"

  # -----------------------------------------------------------------------
  step 6 "Info lines show expected content"
  assert_text_present "${CASE_ID}_06_no_sel" "No files selected" \
    "Second info line: no files selected"
  assert_text_present "${CASE_ID}_06_free" "free" \
    "Third info line shows free space"

  # -----------------------------------------------------------------------
  step 7 "Exit FDD panel back to pcPanel"
  send_key backspace
  assert_text_present "${CASE_ID}_07_back" "Copy" \
    "Status bar shows pcPanel labels after exiting FDD"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
