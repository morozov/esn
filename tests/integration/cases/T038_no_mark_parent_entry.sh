#!/usr/bin/env bash
# T038 — Insert must not mark the ".." or "<<" parent entry
# Bug: pressing Insert on the ".." entry in a PC panel or the "<<"
# entry in a ZX panel marks it, but the original forbids marking
# parent/go-up entries.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T038"
CASE_DESC="Insert must not mark parent entry"

setup() {
  make_fixture_dir sample.trd
  mkdir -p "$_FIXTURE_DIR/SUB"
  app_reset
  send_key home
}

run() {
  step 1 "Navigate into SUB directory"
  send_key down
  send_key return

  step 2 "Move cursor to .. entry and press Insert"
  send_key home
  send_key insert
  assert_text_present "${CASE_ID}_02_no_mark" "No files selected" \
    ".. entry must not be markable"
  assert_text_absent "${CASE_ID}_02_no_checkmark" "√" \
    "no √ mark character visible"
}

teardown() {
  :
}

run_case "$CASE_ID" "$CASE_DESC"
