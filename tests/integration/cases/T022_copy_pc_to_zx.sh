#!/usr/bin/env bash
# T022 — F5 Copy: ZX file entries between TRD images (TRD→TRD)
# Tests: spec/11-file-operations.md (snCopier, trdLoad/trdSave)
#
# Fixture directory: sample.scl, sample.tap, sample.trd + COPYDST.TRD.
#   [1].. [2]COPYDST.TRD [3]sample.scl [4]sample.tap [5]sample.trd
#
# Binary assertions after copy:
#   - byte at COPYDST.TRD offset 0x8E4 changes from 0 → 1 (one file added)
#   - bytes 0..7 of COPYDST.TRD match first entry name from sample.trd
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T022"
CASE_DESC="F5 Copy ZX file entries between TRD images"

EMPTY_TRD="$PROJECT_ROOT/tests/fixtures/empty.trd"
DEST_TRD=""

# Print decimal value of one byte at a given hex/decimal offset in a file.
byte_at() { python3 -c "
with open('$1','rb') as f:
    f.seek($2); b=f.read(1)
    print(b[0] if b else -1)
"; }

# Print the 8-byte ZX name at directory entry index (0-based) as trimmed ASCII.
trd_entry_name() {
  local file="$1" idx="$2"
  python3 -c "
# CP437 bytes 0x01-0x1F map to graphical Unicode (as ESN renders them).
# Python's 'cp437' codec maps these to control chars; we must override.
cp437_ctrl = {
  0x01:'\u263a', 0x02:'\u263b', 0x03:'\u2665', 0x04:'\u2666',
  0x05:'\u2663', 0x06:'\u2660', 0x07:'\u2022', 0x08:'\u25d8',
  0x09:'\u25cb', 0x0a:'\u25d9', 0x0b:'\u2642', 0x0c:'\u2640',
  0x0d:'\u266a', 0x0e:'\u266b', 0x0f:'\u263c', 0x10:'\u25ba',
  0x11:'\u25c4', 0x12:'\u2195', 0x13:'\u203c', 0x14:'\xb6',
  0x15:'\xa7',   0x16:'\u25ac', 0x17:'\u21a8', 0x18:'\u2191',
  0x19:'\u2193', 0x1a:'\u2192', 0x1b:'\u2190', 0x1c:'\u221f',
  0x1d:'\u2194', 0x1e:'\u25b2', 0x1f:'\u25bc',
}
with open('$file','rb') as f:
    f.seek(${idx}*16)
    raw=f.read(8)
raw=raw.rstrip(b' ')
result=''.join(cp437_ctrl.get(b, chr(b)) for b in raw)
print(result)
"
}

setup() {
  require_fixture "$EMPTY_TRD" || return 1

  make_fixture_dir sample.trd
  DEST_TRD="$APP_WORKDIR/COPYDST.TRD"
  cp "$EMPTY_TRD" "$DEST_TRD"

  app_reset
  send_key
}

run() {
  local src_name files_before files_after dest_name

  src_name=$(trd_entry_name "$APP_WORKDIR/sample.trd" 0)
  files_before=$(byte_at "$DEST_TRD" $((0x8E4)))
  log_info "First file in sample.trd: '$src_name'"
  log_info "Files in COPYDST.TRD before copy: $files_before"

  # -----------------------------------------------------------------------
  step 1 "Open sample.trd in left panel"
  # [1].. [2]COPYDST.TRD [3]sample.trd
  send_key home
  send_key down down
  send_key open return
  assert_text_present "${CASE_ID}_01_in_sample" "<<" \
    "Left panel is now inside sample.trd (trdPanel, << visible)"

  # -----------------------------------------------------------------------
  step 2 "Open COPYDST.TRD in right panel"
  send_key tab
  send_key home
  send_key down
  send_key open return
  assert_text_present "${CASE_ID}_02_in_copydst" "No files selected" \
    "Right panel is inside COPYDST.TRD (empty — no files selected)"

  # -----------------------------------------------------------------------
  step 3 "Switch focus to left panel, move to first real file"
  send_key tab
  # Cursor is on << (position 1 inside trdPanel); one down moves to first file.
  send_key down
  assert_info_line "${CASE_ID}_03_cursor_on_file" "$src_name" \
    "Left panel cursor is on the first real ZX file in sample.trd"

  # -----------------------------------------------------------------------
  step 4 "Press F5, confirm copy"
  send_key open f5
  assert_text_present "${CASE_ID}_04_dialog" " Copy " \
    "WillCopyMove dialog with title ' Copy ' is visible"

  send_key fileop return
  assert_text_absent "${CASE_ID}_04_after_copy" "To:" \
    "Copy dialog closed after confirmation"

  # -----------------------------------------------------------------------
  step 5 "Binary check: COPYDST.TRD on disk has exactly 1 file with correct name"
  files_after=$(byte_at "$DEST_TRD" $((0x8E4)))
  dest_name=$(trd_entry_name "$DEST_TRD" 0)
  log_info "Files in COPYDST.TRD after copy: $files_after (expected: 1)"
  log_info "First entry name in COPYDST.TRD: '$dest_name' (expected: '$src_name')"

  if [[ "$files_after" -eq 1 ]]; then
    log_pass "${CASE_ID}_05_binary_file_count" \
      "COPYDST.TRD offset 0x8E4 = 1 (exactly one file copied)"
  else
    log_fail "${CASE_ID}_05_binary_file_count" \
      "COPYDST.TRD offset 0x8E4 = $files_after (expected 1)"
  fi

  if [[ "$dest_name" == "$src_name" ]]; then
    log_pass "${CASE_ID}_05_binary_entry_name" \
      "First entry name = '$dest_name' (matches source '$src_name')"
  else
    log_fail "${CASE_ID}_05_binary_entry_name" \
      "First entry name = '$dest_name' (expected '$src_name')"
  fi
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
