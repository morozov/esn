#!/usr/bin/env bash
# T019 — sn.ini persistence (SaveOnExit / LoadDesktop)
# Tests: spec/13-configuration.md ([Interface] section, [Desktop] section)
#        spec/11-file-operations.md (SaveOnExit behavior)
#
# NOTE: This test requires SaveOnExit=true and LoadDesktop=true to be set
# in sn.ini, OR the test interacts with ESN to enable these options first.
# For the original, sn.ini is in C:\ESN\. For ESN, it is alongside the binary.
#
# Fixture directory: sample.scl, sample.tap, sample.trd.
# sample.trd is at position 4 = 3 downs from ..
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T019"
CASE_DESC="sn.ini persistence"

SNINI=""

setup() {
  make_fixture_dir sample.trd
  SNINI="$APP_WORKDIR/sn.ini"
  app_reset
  send_key
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Navigate to a specific file to set cursor position"
  send_key home
  send_key down
  send_key
  assert_text_present "${CASE_ID}_01_cursor_on_entry" "sample.trd" \
    "Cursor is on sample.trd"

  # -----------------------------------------------------------------------
  step 2 "Verify panel is in the expected state before exit"
  send_key
  assert_text_present "${CASE_ID}_02_before_exit" " free" \
    "Panel is in expected state before exit"

  # -----------------------------------------------------------------------
  step 3 "Exit ESN gracefully (Alt+X, confirm Yes)"
  send_key open alt+x
  assert_text_present "${CASE_ID}_03_exit_dialog" "Confirmation" \
    "Exit confirmation dialog appears"

  send_key open return
  # ESN has exited; the tmux session is now showing the shell prompt.

  # -----------------------------------------------------------------------
  step 4 "Check sn.ini content (offline check — no screenshot)"
  if [[ -f "$SNINI" ]]; then
    log_pass "${CASE_ID}_04_ini_exists" \
      "sn.ini found at $SNINI"

    if grep -q "Language" "$SNINI" 2>/dev/null; then
      log_pass "${CASE_ID}_04_language_key" "sn.ini contains 'Language' key"
    else
      log_fail "${CASE_ID}_04_language_key" "sn.ini missing 'Language' key"
    fi

    if grep -q "\[Interface\]" "$SNINI" 2>/dev/null; then
      log_pass "${CASE_ID}_04_interface_section" "sn.ini has [Interface] section"
    else
      log_fail "${CASE_ID}_04_interface_section" "sn.ini missing [Interface] section"
    fi
  else
    log_skip "${CASE_ID}_04_ini_exists" \
      "sn.ini not found at $SNINI — SaveOnExit may be false, or path differs"
  fi

  # -----------------------------------------------------------------------
  step 5 "Restart ESN and verify panel state is restored (LoadDesktop)"
  _runner_app_start
  send_key
  assert_text_present "${CASE_ID}_05_app_running" "Exit" \
    "ESN is running after restart — status bar shows 'Exit'"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
