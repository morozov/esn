#!/usr/bin/env bash
# T045 — Alt+F6 inline rename: arrow keys move cursor without inserting chars
#
# Bug (port): pcSNscanf reads rKey (a word) and inserts chr(lo(scanf_kod))
# whenever the low byte is in the printable range.  rKey encodes Right as
# $4DE0 with low byte $E0, which lies in ']'..#254 — so each arrow press
# inserted a stray $E0 byte (an invalid UTF-8 lead the terminal renders as
# '?') before the cursor advance.
#
# The original BP7 readkey returned #0 first for extended keys, routing
# nav keys to a separate branch and never letting them reach the
# character filter.
#
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T045"
CASE_DESC="Alt+F6 inline rename: arrow keys do not pollute filename"

setup() {
  _FIXTURE_DIR="$(mktemp -d)"
  : > "$_FIXTURE_DIR/hello.txt"
  export APP_WORKDIR="$_FIXTURE_DIR"
  app_reset
  send_key
}

run() {
  step 1 "Alt+F6 enters inline rename — cursor sits on the filename"
  send_key home down
  send_key open alt+f6

  # In inline rename the cursor sits on the file name itself; the
  # panel status bar is suppressed.
  assert_text_absent "${CASE_ID}_01_hotkeys_hidden" "Alt+X Exit" \
    "panel status bar is suppressed during inline rename"

  step 2 "Right twice — name stays 'hello.txt' (no inserted bytes)"
  send_key right right
  # The visible filename row in the LEFT panel must still read
  # 'hello.txt'.  With the bug, $E0 bytes appear in place of
  # the leading characters and the row reads e.g. '?e?lo.txt'.
  assert_rect_text "${CASE_ID}_02_name_row_clean" 4 2 1 12 "hello.txt" \
    "filename row unchanged after two Right presses"

  step 3 "Enter commits — file on disk is still hello.txt"
  send_key fileop return
  if [[ -f "$APP_WORKDIR/hello.txt" ]]; then
    log_pass "${CASE_ID}_03_disk_name_unchanged" \
      "hello.txt unchanged on disk after Right Right Enter"
  else
    log_fail "${CASE_ID}_03_disk_name_unchanged" \
      "hello.txt was renamed: $(ls "$APP_WORKDIR")"
  fi
}

teardown() {
  :
}

run_case "$CASE_ID" "$CASE_DESC"
