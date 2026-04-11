#!/usr/bin/env bash
# T023 — Extension columns must not linger after navigating to a smaller dir
#
# Reproduction: start in a directory, navigate into a subdirectory that has
# files with 3-letter extensions (e.g. .BAK), navigate back.  Without the
# fix, extensions from the subdirectory linger on parent entries — e.g.
# "original BAK", "CLAUDE   mdS".
#
# Tests: spec/02-pc-panel.md — PcColumnEntry must right-pad ext to 3 chars.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T023"
CASE_DESC="Extension columns must not linger after navigating to a smaller directory"

setup() {
  make_fixture_dir sample.trd
  # Create a subdirectory with files that have 3-letter extensions.
  mkdir "$_FIXTURE_DIR/SUB"
  echo "data" > "$_FIXTURE_DIR/SUB/FILE1.BAK"
  echo "data" > "$_FIXTURE_DIR/SUB/FILE2.BAK"
  echo "data" > "$_FIXTURE_DIR/SUB/FILE3.BAK"
  app_reset
  send_key home
}

run() {
  step 1 "Navigate into SUB directory"
  send_key down
  send_key return
  assert_text_present "${CASE_ID}_01_in_sub" "BAK" \
    ".BAK files are visible inside SUB"

  step 2 "Navigate back up to parent"
  send_key home
  send_key return
  assert_text_absent "${CASE_ID}_02_no_linger" "BAK" \
    "no lingering BAK extensions after navigating back"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
