#!/usr/bin/env bash
# T047 — PC inline rename overlay covers the full entry slot at wider widths
#
# In a 120-column terminal the 3-column entry slot is 18 cells wide
# (PanelW=58, dx=(58+1)/3=19, slot=dx-1=18).  pcRename used to seed
# rv.scanf with a hardcoded visLen of 12 cells regardless of actual
# slot width, leaving the rightmost cells of the original 8.3
# rendering visible — so a short name like 'hi.txt' would show the
# old extension on the right alongside the new one in the editor:
#
#   hi.txt         txt   ← buggy: 6 chars + 9 spaces + 'txt' (residue)
#   hi.txt               ← correct: 6 chars + 12 spaces (full cover)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T047"
CASE_DESC="PC inline rename overlay covers entry slot at wider widths"

setup() {
  _FIXTURE_DIR="$(mktemp -d)"
  : > "$_FIXTURE_DIR/hi.txt"
  export APP_WORKDIR="$_FIXTURE_DIR"
  app_reset 120 30
  send_key
}

run() {
  step 1 "Inline rename overlay covers all 18 cells of the 3-col slot"
  send_key home down
  send_key open alt+f6
  # Slot starts at column 2 (right of the left panel border) and
  # spans 18 cells in 3-col mode at 120 cols.
  assert_rect_text "${CASE_ID}_01_full_slot" 4 2 1 18 "hi.txt" \
    "full 18-cell slot reads 'hi.txt' with trailing spaces (no residue)"
  send_key escape
}

teardown() {
  :
}

run_case "$CASE_ID" "$CASE_DESC"
