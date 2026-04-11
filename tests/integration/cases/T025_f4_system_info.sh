#!/usr/bin/env bash
# T025 — F4 System information dialog on TRD panel
# Tests: zxEditParam in trd_ovr.pas (task 019)
#
# Fixture directory: sample.scl, sample.tap, sample.trd.
# sample.trd is at position 4 = 3 downs from ..
#
# Panel positions inside the TRD:
#   [1] <<   (go-up / ..)
#   [2] hello.B
#   [3] data.C
#   [4] code.D
#
# Checks:
#   1. F4 on <<   → disk-only dialog (no "File Name" row)
#   2. Esc        → dialog closes, panel unchanged
#   3. F4 on file → full dialog (disk + file section both visible)
#   4. Tab        → advances to next field within the dialog
#   5. Esc        → no write-back (disk label unchanged on disk)
#   6. F4 on file → edit disk label → Enter → Yes → bytes at 0x8F5 updated
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T025"
CASE_DESC="F4 System information dialog on TRD panel"

TRD_FILE=""

# Return the 8-byte disk label stored at offset 0x8F5 in FILE.
trd_disk_label() {
  python3 -c "
with open('$1','rb') as f:
    f.seek(0x8F5); b=f.read(8)
print(b.decode('latin-1'))
"
}

# Return decimal value of one byte at HEX_OFFSET in FILE.
byte_at_hex() {
  python3 -c "
with open('$1','rb') as f:
    f.seek($2); b=f.read(1)
print(b[0] if b else -1)
"
}

setup() {
  make_fixture_dir sample.trd
  TRD_FILE="$APP_WORKDIR/sample.trd"
  app_reset
  send_key home
  send_key down
  send_key open return
}

run() {
  local orig_label new_label

  orig_label=$(trd_disk_label "$TRD_FILE")
  log_info "Original disk label: '${orig_label}'"

  # -----------------------------------------------------------------------
  step 1 "F4 on << (position 1) shows disk-only System information dialog"
  # Cursor starts at position 1 (<<) after entering the TRD.
  send_key open f4
  assert_text_present "${CASE_ID}_01_dialog_open" \
    "System information" \
    "Dialog title 'System information' is in terminal text"
  assert_text_absent "${CASE_ID}_01_no_file_section" \
    "File Name" \
    "File Name column header is absent (disk-only mode)"

  # -----------------------------------------------------------------------
  step 2 "Esc closes the dialog without any change"
  send_key escape
  assert_text_absent "${CASE_ID}_02_dialog_gone" \
    "System information" \
    "Dialog title is gone after Esc"

  # -----------------------------------------------------------------------
  step 3 "F4 on a real file shows the full dialog (disk + file section)"
  # Move down one to 'hello.B' (position 2)
  send_key down
  send_key open f4
  assert_text_present "${CASE_ID}_03_file_name_header" \
    "File Name" \
    "File Name column header is present in full dialog"

  # -----------------------------------------------------------------------
  step 4 "Tab advances to the next field (field 2: File count)"
  # Currently in field 1 (disk label). Tab should move to field 2.
  send_key tab
  assert_text_present "${CASE_ID}_04_tab_advanced" \
    "System information" \
    "After Tab, still in System information dialog (advanced to next field)"

  # Tab again → field 3 (disk type popup)
  send_key tab
  assert_text_present "${CASE_ID}_04_disk_type_popup" \
    "Track" \
    "After Tab to field 3, disk type popup shows 'Track' options"

  # Esc out of popup
  send_key escape

  # -----------------------------------------------------------------------
  step 5 "Shift+Tab moves back to the previous field"
  send_key shift+tab
  assert_text_present "${CASE_ID}_05_shift_tab_back" \
    "Track" \
    "Shift+Tab moved back — disk type popup visible again"

  # Exit the popup first, then exit the dialog.
  # Use Return on the active popup item instead of Escape —
  # back-to-back Escape keys are unreliable due to FPC's
  # double-escape hack leaving residual bytes.
  send_key return
  close_dialog "System information"
  assert_text_absent "${CASE_ID}_05_dialog_closed" \
    "System information" \
    "After pressing Esc, dialog closes (no confirmation on Esc)"

  # Verify the label on disk is still the original (Esc = no write)
  new_label=$(trd_disk_label "$TRD_FILE")
  if [[ "$new_label" == "$orig_label" ]]; then
    log_pass "${CASE_ID}_05_no_write_on_esc" \
      "Disk label unchanged after Esc ('${orig_label}')"
  else
    log_fail "${CASE_ID}_05_no_write_on_esc" \
      "Disk label changed from '${orig_label}' to '${new_label}' after Esc"
  fi

  # -----------------------------------------------------------------------
  step 6 "Enter + Yes writes the edited disk label back to the TRD file"
  # Open dialog on hello.B (still at position 2).
  send_key open f4
  wait_for_text "System information"

  # Field 1 (disk label) is active. Clear the field and type new label.
  # Move cursor to end first, then backspace 8 times to clear "SAMPLE  ".
  # (Home+BkSp does nothing at pos 1; End+BkSp×8 clears correctly.)
  send_key end
  # Delete all 8 chars of "SAMPLE  "
  send_key delete delete delete delete delete delete delete delete
  # Type new 8-char label "testlbl "
  send_key t e s t l b l space
  # Home scrolls the field back to pos 1 so "testlbl" is fully visible.
  send_key home
  wait_for_text "testlbl"
  assert_text_present "${CASE_ID}_06_new_label_visible" \
    "testlbl" \
    "The disk label input field shows the new label 'testlbl'"

  # Press Enter to exit the loop → CQuestion appears
  send_key open return
  assert_text_present "${CASE_ID}_06_confirm_dialog" \
    "Yes" \
    "After pressing Enter, confirmation dialog appears with Yes button"

  # Press Enter to confirm (Yes)
  send_key open return
  assert_text_absent "${CASE_ID}_06_panel_restored" \
    "System information" \
    "After confirming Yes, dialog closes and panel is restored"

  # Binary assertion: offset 0x8F5 should now hold "testlbl "
  new_label=$(trd_disk_label "$TRD_FILE")
  local expected="testlbl "
  log_info "Disk label after write: '${new_label}' (expected: '${expected}')"

  if [[ "$new_label" == "$expected" ]]; then
    log_pass "${CASE_ID}_06_label_written" \
      "Disk label at offset 0x8F5 = '${new_label}' (write-back succeeded)"
  else
    log_fail "${CASE_ID}_06_label_written" \
      "Disk label at offset 0x8F5 = '${new_label}' (expected '${expected}')"
  fi
}

teardown() {
  send_key ctrl+pageup
}

run_case "$CASE_ID" "$CASE_DESC"
