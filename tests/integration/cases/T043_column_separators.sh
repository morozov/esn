#!/usr/bin/env bash
# T043 — Column separators must render on every row
# Regression: a TRD entry whose first byte is a non-printable control
# byte (0x00 / 0x01 — TRD "deleted entry" prefixes) causes the file
# row to render one cell short, erasing the column-1/2 and 2/3
# separators ('│') for that row.
#
# Fixture: deleted_entries.trd is a synthesized 8 KB image
# (track 0 only — TR-DOS reads just the catalog) with ten
# directory entries; entries 4 and 6 carry name[0] = 0x01 and 0x00
# respectively, reproducing the deleted-entry layout that exposed
# the bug.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T043"
CASE_DESC="Column separators render on every entry row"

setup() {
  make_fixture_dir deleted_entries.trd
  app_reset
  send_key
}

run() {
  # ---------------------------------------------------------------------
  step 1 "Enter the TRD image (cursor on deleted_entries.trd, press Enter)"
  send_key down enter
  send_key

  # ---------------------------------------------------------------------
  step 2 "Every visible entry row has '│' separators at column boundaries"
  # 3-column mode, PanelW=38 → dx=13. In the LEFT panel the column-1/2
  # separator is at column 14, the column-2/3 separator at column 27.
  # File rows are 3..19 (17 visible rows below the header).
  local missing_14="" missing_27=""
  for row in 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19; do
    local sep1 sep2
    sep1=$(rect_text "$row" 14 1 1)
    sep2=$(rect_text "$row" 27 1 1)
    [[ "$sep1" != "│" ]] && missing_14="$missing_14 $row"
    [[ "$sep2" != "│" ]] && missing_27="$missing_27 $row"
  done

  if [[ -z "$missing_14" ]]; then
    log_pass "${CASE_ID}_02_sep_col14" \
      "Column-1/2 separator '│' at col 14 on every row"
  else
    log_fail "${CASE_ID}_02_sep_col14" \
      "Missing '│' at col 14 on rows:$missing_14"
  fi
  _maybe_dump "${CASE_ID}_02_sep_col14"

  if [[ -z "$missing_27" ]]; then
    log_pass "${CASE_ID}_02_sep_col27" \
      "Column-2/3 separator '│' at col 27 on every row"
  else
    log_fail "${CASE_ID}_02_sep_col27" \
      "Missing '│' at col 27 on rows:$missing_27"
  fi
  _maybe_dump "${CASE_ID}_02_sep_col27"

  # ---------------------------------------------------------------------
  step 3 "Deleted-entry rows render the CP437 glyph for the leading byte"
  # In deleted_entries.trd entries 4 and 6 carry name[0]=0x01 and 0x00.
  # In directory order the panel shows '..' as row 1, then the live
  # entries; the deleted entries land on screen rows 7 ('☺elta') and
  # 9 (' oxtrot'). The first visible cell holds the CP437 graphical
  # glyph for that byte (☺ for 0x01, blank for 0x00) — matching the
  # original DOS BIOS text-mode rendering. If the byte leaks through
  # un-mapped, the row shifts and the size column mis-aligns.
  assert_rect_text "${CASE_ID}_03_deleted_row7_cp437_glyph" \
    7 2 1 1 "☺" \
    "Row 7 (deleted '0x01'+'elta') has CP437 glyph ☺ at col 2"
  assert_rect_text "${CASE_ID}_03_deleted_row9_cp437_glyph" \
    9 2 1 1 " " \
    "Row 9 (deleted '0x00'+'oxtrot') has CP437 glyph (blank) at col 2"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
