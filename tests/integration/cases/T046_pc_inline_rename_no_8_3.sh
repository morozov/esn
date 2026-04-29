#!/usr/bin/env bash
# T046 — PC inline rename does not impose DOS 8.3 layout
#
# Bugs (port, DOS-era leftovers):
#   1. Directories (no extension) display a trailing '.' in the inline
#      editor and, on Enter, the directory is renamed to add trailing
#      whitespace.
#   2. Dot-files (e.g. .bashrc) show a spurious trailing '.' in the
#      inline editor and lose data on commit.
#   3. Names shorter than 8 chars are padded with spaces between the
#      stem and the dot (`hello   .txt`), reflecting the 8.3 grid.
#
# Modern filesystems on every supported platform (macOS, Linux,
# Windows) accept full names without the 8.3 split.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T046"
CASE_DESC="PC inline rename: no DOS 8.3 padding"

setup() {
  _FIXTURE_DIR="$(mktemp -d)"
  : > "$_FIXTURE_DIR/hello.txt"
  : > "$_FIXTURE_DIR/.bashrc"
  mkdir "$_FIXTURE_DIR/mydir"
  export APP_WORKDIR="$_FIXTURE_DIR"
  app_reset
  send_key
}

# Move cursor to the entry whose info-line shows TEXT.  Returns
# non-zero if not found within the visible panel.
_focus_entry_named() {
  local target="$1" tries=0
  send_key home
  while (( tries < 30 )); do
    if capture_info_line | grep -qF "$target"; then
      return 0
    fi
    send_key down
    tries=$(( tries + 1 ))
  done
  return 1
}

run() {
  step 1 "Directory entry — no trailing dot in inline editor"
  _focus_entry_named "mydir" || {
    log_fail "${CASE_ID}_01_focus" "could not find mydir in panel"
    return
  }
  send_key open alt+f6
  # rect at column 1 of the cursor row, 12 chars wide.  rect_text
  # right-trims whitespace, so the expected value is just the name.
  assert_rect_text "${CASE_ID}_01_dir_row" 4 2 1 12 "mydir" \
    "directory inline-edit row shows 'mydir' with no trailing dot"
  send_key escape

  step 2 "Directory rename with no edits leaves the name intact"
  _focus_entry_named "mydir" || {
    log_fail "${CASE_ID}_02_focus" "lost focus on mydir"
    return
  }
  send_key open alt+f6
  send_key fileop return
  if [[ -d "$APP_WORKDIR/mydir" ]]; then
    log_pass "${CASE_ID}_02_dir_unchanged" \
      "mydir/ directory still present after Alt+F6 + Enter"
  else
    log_fail "${CASE_ID}_02_dir_unchanged" \
      "mydir/ vanished — got: $(ls -A "$APP_WORKDIR")"
  fi

  step 3 "Dot-file — no spurious trailing dot in inline editor"
  _focus_entry_named ".bashrc" || {
    log_fail "${CASE_ID}_03_focus" "could not find .bashrc"
    return
  }
  send_key open alt+f6
  # Fixture layout: row 3 .., row 4 mydir, row 5 .bashrc, row 6 hello.txt.
  assert_rect_text "${CASE_ID}_03_dotfile_row" 5 2 1 12 ".bashrc" \
    "dot-file inline-edit row shows '.bashrc' with no extra dot"
  send_key escape

  step 4 "Short name — no internal padding between stem and extension"
  _focus_entry_named "hello.txt" || {
    log_fail "${CASE_ID}_04_focus" "could not find hello.txt"
    return
  }
  send_key open alt+f6
  assert_rect_text "${CASE_ID}_04_short_row" 6 2 1 12 "hello.txt" \
    "short-name row shows 'hello.txt' with no internal padding"
  send_key escape

  step 5 "Up exits inline rename (BP7 commit-on-Up/Down behaviour)"
  _focus_entry_named "hello.txt" || {
    log_fail "${CASE_ID}_05_focus" "could not find hello.txt"
    return
  }
  send_key open alt+f6
  # During inline rename the panel status bar is suppressed.
  assert_text_absent "${CASE_ID}_05_in_rename" "Alt+X Exit" \
    "status bar is suppressed inside inline rename"
  send_key up
  # After Up, the rename should have exited and the panel status
  # bar must be visible again.
  assert_text_present "${CASE_ID}_05_after_up" "Alt+X Exit" \
    "Up exits inline rename — panel status bar visible again"
}

teardown() {
  :
}

run_case "$CASE_ID" "$CASE_DESC"
