#!/usr/bin/env bash
# T048 — PC inline rename handles multi-byte UTF-8 filenames as graphemes
#
# rv.scanf used to operate on raw bytes: visLen and the cursor were
# treated as byte counts, and Backspace deleted one byte at a time.
# For a name like 'héllo.txt' (with é = 2 UTF-8 bytes / 1 cell):
#
#   • the inline overlay painted only 11 cells of the 12-cell slot,
#     so the trailing 't' from the panel's 8.3 rendering bled
#     through ('héllo.txt  t');
#   • Right twice landed the cursor in the middle of 'é';
#   • Backspace at that point deleted one byte of 'é', producing
#     invalid UTF-8 ('h<0xA9>llo.txt'), which on commit was renamed
#     onto disk verbatim — a broken filename.
#
# scanf now edits in grapheme clusters, so 'é' is one editable unit
# and the slot is filled to its full cell width.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T048"
CASE_DESC="PC inline rename: multi-byte UTF-8 names edit by grapheme"

setup() {
  _FIXTURE_DIR="$(mktemp -d)"
  : > "$_FIXTURE_DIR/héllo.txt"
  export APP_WORKDIR="$_FIXTURE_DIR"
  app_reset
  send_key
}

run() {
  step 1 "Inline overlay covers the whole slot — no residue past 'héllo.txt'"
  # Sole entry after '..' — home + one down lands on 'héllo.txt' at row 4.
  send_key home down
  send_key open alt+f6
  # Slot at 80 cols, 3-col mode: PanelW=38, dx=(38+1)/3=13, slot=12.
  # 'héllo.txt' is 9 cells; the rest must be spaces (no '8.3' residue).
  assert_rect_text "${CASE_ID}_01_full_slot" 4 2 1 12 "héllo.txt" \
    "12-cell slot reads 'héllo.txt' with trailing spaces (no residue)"

  step 2 "Right twice + Backspace deletes 'é' as one grapheme"
  send_key right right backspace
  assert_rect_text "${CASE_ID}_02_grapheme_delete" 4 2 1 12 "hllo.txt" \
    "Backspace after Right Right removes 'é' cleanly (no broken UTF-8)"

  step 3 "Enter commits — file on disk is 'hllo.txt' (valid UTF-8)"
  send_key fileop return
  if [[ -f "$APP_WORKDIR/hllo.txt" && ! -f "$APP_WORKDIR/héllo.txt" ]]; then
    log_pass "${CASE_ID}_03_disk_committed" \
      "héllo.txt renamed to hllo.txt on disk"
  else
    log_fail "${CASE_ID}_03_disk_committed" \
      "expected only hllo.txt — got: $(ls "$APP_WORKDIR")"
  fi
}

teardown() {
  :
}

run_case "$CASE_ID" "$CASE_DESC"
