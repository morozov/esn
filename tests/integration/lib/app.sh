#!/usr/bin/env bash
# lib/app.sh — ESN application lifecycle and screen capture (tmux-only).
#
# All test execution uses a detached tmux session. The ATTACHED=1 environment
# variable causes a Terminal.app window to be opened for observation; it has
# no effect on assertion results.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "${PROJECT_ROOT:-}" ]]; then
  source "$SCRIPT_DIR/common.sh"
fi

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

_APP_TMUX_SESSION="esn_test"

APP_WORKDIR="${APP_WORKDIR:-$PROJECT_ROOT/tests/fixtures}"

# Screen cache. Both are cleared by _screen_invalidate().
_SCREEN_TEXT_CACHE=""
_SCREEN_ANSI_CACHE=""

# ---------------------------------------------------------------------------
# _screen_invalidate — clear both caches; next accessor call triggers capture
# ---------------------------------------------------------------------------
_screen_invalidate() {
  _SCREEN_TEXT_CACHE=""
  _SCREEN_ANSI_CACHE=""
}

# ---------------------------------------------------------------------------
# screen_text — lazy plain-text screen (tmux capture-pane -p)
# ---------------------------------------------------------------------------
screen_text() {
  if [[ -z "$_SCREEN_TEXT_CACHE" ]]; then
    _SCREEN_TEXT_CACHE=$(
      tmux capture-pane -p -t "$_APP_TMUX_SESSION" 2>/dev/null || true
    )
  fi
  printf '%s' "$_SCREEN_TEXT_CACHE"
}

# ---------------------------------------------------------------------------
# screen_ansi — lazy ANSI-colored screen (tmux capture-pane -p -e)
# ---------------------------------------------------------------------------
screen_ansi() {
  if [[ -z "$_SCREEN_ANSI_CACHE" ]]; then
    _SCREEN_ANSI_CACHE=$(
      tmux capture-pane -p -e -t "$_APP_TMUX_SESSION" 2>/dev/null || true
    )
  fi
  printf '%s' "$_SCREEN_ANSI_CACHE"
}

# Backwards-compatibility alias used by a few test cases that call
# app_screen_text() directly (T027, T028, T029, T030).
app_screen_text() { screen_text; }

# ---------------------------------------------------------------------------
# rect_text ROW COL HEIGHT WIDTH
# Extract plain text from the rectangle at (ROW,COL) of size HEIGHTxWIDTH.
# ROW and COL are 1-based. Returns HEIGHT newline-separated strings.
# ---------------------------------------------------------------------------
rect_text() {
  local row="$1" col="$2" height="$3" width="$4"
  # Python string slicing is character-based (not byte-based), which is
  # required for correct column extraction when the screen contains
  # multibyte UTF-8 characters such as box-drawing glyphs.
  screen_text | python3 -c "
import sys
r, c, h, w = $row, $col, $height, $width
lines = sys.stdin.read().splitlines()
for line in lines[r-1:r-1+h]:
    while len(line) < c + w - 1:
        line += ' '
    print(line[c-1:c-1+w])
"
}

# ---------------------------------------------------------------------------
# _parse_ansi_colors MODE ROW COL HEIGHT WIDTH
# Internal: parse ANSI SGR sequences from screen_ansi and return a grid of
# color names (HEIGHT lines, each WIDTH space-separated names).
# MODE is "bg" (background, SGR 40-49) or "fg" (foreground, SGR 30-39,90-97).
# ---------------------------------------------------------------------------
_parse_ansi_colors() {
  local mode="$1" row="$2" col="$3" height="$4" width="$5"
  screen_ansi | LC_ALL=C awk \
    -v mode="$mode" \
    -v start_row="$row" \
    -v start_col="$col" \
    -v height="$height" \
    -v width="$width" \
    'BEGIN { ESC = "\033"; cur_bg = "default"; cur_fg = "default"; bright = 0 }
    {
      # Parse every SGR sequence on every line, accumulating attribute state.
      # capture-pane -e uses delta encoding: attributes set on an earlier row
      # (e.g. bold from the header) are NOT re-emitted on subsequent rows
      # unless they change.  The parser must therefore scan all rows from 1
      # up to start_row so that inherited state is correctly carried in.
      if (NR >= start_row && NR < start_row + height) {
        col_num = 0
        delete col_colors
      }
      n = length($0)
      i = 1
      while (i <= n) {
        c = substr($0, i, 1)
        if (c == ESC && i + 1 <= n && substr($0, i+1, 1) == "[") {
          j = i + 2
          while (j <= n && substr($0, j, 1) !~ /[A-Za-z]/) j++
          if (j <= n && substr($0, j, 1) == "m") {
            seq = substr($0, i+2, j - i - 2)
            if (seq == "" || seq == "0") {
              cur_bg = "default"; cur_fg = "default"; bright = 0
            } else {
              np = split(seq, parts, ";")
              for (k = 1; k <= np; k++) {
                p = int(parts[k])
                if      (p ==  0) { cur_bg = "default"; cur_fg = "default"; bright = 0 }
                else if (p ==  1) { bright = 1 }
                else if (p == 22) { bright = 0 }
                else if (p == 30) cur_fg = "black"
                else if (p == 31) cur_fg = "red"
                else if (p == 32) cur_fg = "green"
                else if (p == 33) cur_fg = "yellow"
                else if (p == 34) cur_fg = "blue"
                else if (p == 35) cur_fg = "magenta"
                else if (p == 36) cur_fg = "cyan"
                else if (p == 37) cur_fg = "white"
                else if (p == 39) cur_fg = "default"
                else if (p == 40) cur_bg = "black"
                else if (p == 41) cur_bg = "red"
                else if (p == 42) cur_bg = "green"
                else if (p == 43) cur_bg = "yellow"
                else if (p == 44) cur_bg = "blue"
                else if (p == 45) cur_bg = "magenta"
                else if (p == 46) cur_bg = "cyan"
                else if (p == 47) cur_bg = "white"
                else if (p == 49) cur_bg = "default"
                else if (p == 90) cur_fg = "light-black"
                else if (p == 91) cur_fg = "light-red"
                else if (p == 92) cur_fg = "light-green"
                else if (p == 93) cur_fg = "light-yellow"
                else if (p == 94) cur_fg = "light-blue"
                else if (p == 95) cur_fg = "light-magenta"
                else if (p == 96) cur_fg = "light-cyan"
                else if (p == 97) cur_fg = "light-white"
              }
              # Apply bold/bright modifier: SGR 1 + normal color = bright color
              if (bright) {
                if (cur_fg == "black")   cur_fg = "light-black"
                if (cur_fg == "red")     cur_fg = "light-red"
                if (cur_fg == "green")   cur_fg = "light-green"
                if (cur_fg == "yellow")  cur_fg = "light-yellow"
                if (cur_fg == "blue")    cur_fg = "light-blue"
                if (cur_fg == "magenta") cur_fg = "light-magenta"
                if (cur_fg == "cyan")    cur_fg = "light-cyan"
                if (cur_fg == "white")   cur_fg = "light-white"
              }
            }
          }
          i = j + 1
        } else {
          if (c >= "\200" && c <= "\277") {
            # UTF-8 continuation byte — part of multi-byte sequence,
            # skip without counting a column.
            i++
          } else {
            # ASCII character or UTF-8 lead byte — one terminal column.
            if (NR >= start_row && NR < start_row + height) {
              col_num++
              if (col_num >= start_col && col_num < start_col + width)
                col_colors[col_num] = (mode == "bg") ? cur_bg : cur_fg
              if (col_num >= start_col + width - 1)
                i = n + 1  # skip rest of line once past target cols
            }
            i++
          }
        }
      }
      if (NR >= start_row && NR < start_row + height) {
        out = ""
        for (c = start_col; c < start_col + width; c++) {
          color = (c in col_colors) ? col_colors[c] : "default"
          out = out (out == "" ? "" : " ") color
        }
        print out
      }
    }'
}

# ---------------------------------------------------------------------------
# rect_bg ROW COL HEIGHT WIDTH
# Returns HEIGHT lines, each WIDTH space-separated background color names.
# ---------------------------------------------------------------------------
rect_bg() { _parse_ansi_colors "bg" "$@"; }

# ---------------------------------------------------------------------------
# rect_fg ROW COL HEIGHT WIDTH
# Returns HEIGHT lines, each WIDTH space-separated foreground color names.
# ---------------------------------------------------------------------------
rect_fg() { _parse_ansi_colors "fg" "$@"; }

# ---------------------------------------------------------------------------
# capture_info_line
# Extract info line 1 (cursor name line) from the left panel.
# Info line 1 is at row pane_height - 4 (1-based), columns 1-40.
# ---------------------------------------------------------------------------
capture_info_line() {
  local h
  h=$(tmux display -p '#{pane_height}' -t "$_APP_TMUX_SESSION" 2>/dev/null \
      || echo 25)
  rect_text $(( h - 4 )) 1 1 40 | sed 's/^║//' | sed 's/[[:space:]]*$//'
}

# ---------------------------------------------------------------------------
# _runner_app_start [COLS [ROWS]]
# ---------------------------------------------------------------------------
_runner_app_start() {
  local cols="${1:-80}"
  local rows="${2:-25}"

  log_info "Starting ESN in tmux session '$_APP_TMUX_SESSION' (${cols}x${rows})..."

  tmux kill-session -t "$_APP_TMUX_SESSION" 2>/dev/null || true
  pkill -f "bin/esn" 2>/dev/null || true
  sleep_for_settle

  tmux new-session -d -s "$_APP_TMUX_SESSION" -x "$cols" -y "$rows"
  tmux send-keys -t "$_APP_TMUX_SESSION" \
    "cd '${APP_WORKDIR}' && '${APP_BIN}'" Enter

  if [[ "${ATTACHED:-0}" == "1" ]]; then
    osascript -e \
      "tell application \"Terminal\" to do script \
       \"tmux attach -t $_APP_TMUX_SESSION\"" \
      2>/dev/null || true
  fi

  sleep_for_app_start
  _screen_invalidate
  log_info "Application started."
}

# ---------------------------------------------------------------------------
# _runner_app_stop
# ---------------------------------------------------------------------------
_runner_app_stop() {
  # Two ESC bytes + the Enter that follows resolve FPC's
  # double_esc_hack.  See send_key() for the full explanation.
  tmux send-keys -t "$_APP_TMUX_SESSION" "Escape" "Escape" 2>/dev/null \
    || true
  sleep_for_app_stop

  tmux send-keys -t "$_APP_TMUX_SESSION" Enter 2>/dev/null || true

  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -f "bin/esn" > /dev/null 2>&1 || break
    sleep 0.2
  done

  if pgrep -f "bin/esn" > /dev/null 2>&1; then
    log_info "[BUG] ESN did not exit gracefully — force-killing"
    pkill -f "bin/esn" 2>/dev/null || true
    sleep 0.2
  fi

  tmux kill-session -t "$_APP_TMUX_SESSION" 2>/dev/null || true
  _screen_invalidate
}

# ---------------------------------------------------------------------------
# app_reset [COLS [ROWS]]
# ---------------------------------------------------------------------------
app_reset() {
  log_info "Resetting application..."
  _runner_app_stop
  _runner_app_start "$@"
  # ESN starts with right panel focused (per spec); switch to left panel
  # so that all tests begin with the left panel active.
  tmux send-keys -t "$_APP_TMUX_SESSION" $'\t' 2>/dev/null || true
  sleep_for_settle
  _screen_invalidate
}

# ---------------------------------------------------------------------------
# _app_delay WORD
# ---------------------------------------------------------------------------
_app_delay() {
  case "${1:-settle}" in
    settle) sleep_for_settle  ;;
    resize) sleep_for_resize  ;;
    open)   sleep_for_open    ;;
    fileop) sleep_for_file_op ;;
    *)      sleep_for_settle  ;;
  esac
}

# ---------------------------------------------------------------------------
# Key delivery
# ---------------------------------------------------------------------------
#
# Tests describe keystrokes with human tokens (`return`, `escape`,
# `alt+f6`, `ctrl+pgup`, `shift+tab`, `f9`, `insert`, `right`, …) and
# bare printable characters (`a`, `1`).  Each token is dispatched
# through one of two paths:
#
# 1. tmux key name (`Enter`, `BSpace`, `F6`, `C-v`) for keys tmux can
#    name natively, OR a plain escape sequence (e.g. `\e[5~` for PgUp)
#    sent as bytes.
#
# 2. Atomic hex bytes via `tmux send-keys -H` for sequences whose
#    bytes must arrive in a single write() so FPC's escape-sequence
#    timer cannot split them.  This applies to:
#      - Escape — FPC's double-ESC hack expects \x1b\x1b\x00;
#      - Alt+F1..F10 — leading ESC must coalesce with the F-key
#        sequence so FPC reports rawCode=_AltFn rather than plain Fn.
#
# Use `send_text` for typing literal multi-character strings (the
# in-app local-find input and similar).  Plain printable single-key
# tokens (e.g. `s`, `1`) also work via `send_key`.
# ---------------------------------------------------------------------------

_app_send_atomic() {
  tmux send-keys -H -t "$_APP_TMUX_SESSION" "$@" 2>/dev/null || true
}

_app_send_token() {
  tmux send-keys -t "$_APP_TMUX_SESSION" "$1" 2>/dev/null || true
}

# Translate one non-atomic key token into a tmux send-keys argument.
# Atomic-byte keys (escape, alt+f*, insert) are handled in send_key
# directly and never reach this function.
_app_key_tmux() {
  local lk="${1,,}"
  case "$lk" in
    return)                    echo "Enter" ;;
    tab)                       echo "Tab" ;;
    shift+tab)                 echo "BTab" ;;
    space)                     echo "Space" ;;
    delete|backspace)          echo "BSpace" ;;
    up)                        echo "Up" ;;
    down)                      echo "Down" ;;
    left)                      echo "Left" ;;
    right)                     echo "Right" ;;
    f1)                        echo "F1" ;;
    f2)                        echo "F2" ;;
    f3)                        echo "F3" ;;
    f4)                        echo "F4" ;;
    f5)                        echo "F5" ;;
    f6)                        echo "F6" ;;
    f7)                        echo "F7" ;;
    f8)                        echo "F8" ;;
    f9)                        echo "F9" ;;
    f10)                       echo "F10" ;;
    pageup)                    printf '%s' $'\e[5~' ;;
    pagedown)                  printf '%s' $'\e[6~' ;;
    home)                      printf '%s' $'\e[H' ;;
    end)                       printf '%s' $'\e[F' ;;
    ctrl+pgup|ctrl+pageup)     printf '%s' $'\e[5;5~' ;;
    ctrl+pgdn|ctrl+pagedown)   printf '%s' $'\e[6;5~' ;;
    ctrl+*)
      local c="${lk#ctrl+}"
      echo "C-${c}"
      ;;
    alt+*)
      local c="${lk#alt+}"
      printf '%s%s' $'\e' "$c"
      ;;
    shift+f*)
      local fnum="${lk#shift+f}"
      case "$fnum" in
        1)  printf '%s' $'\e[1;2P'  ;;
        2)  printf '%s' $'\e[1;2Q'  ;;
        3)  printf '%s' $'\e[1;2R'  ;;
        4)  printf '%s' $'\e[1;2S'  ;;
        5)  printf '%s' $'\e[15;2~' ;;
        6)  printf '%s' $'\e[17;2~' ;;
        7)  printf '%s' $'\e[18;2~' ;;
        8)  printf '%s' $'\e[19;2~' ;;
        9)  printf '%s' $'\e[20;2~' ;;
        10) printf '%s' $'\e[21;2~' ;;
      esac
      ;;
    *)
      printf '%s' "$1"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# send_key [DELAY] [KEY …]
#
# Send zero or more keystrokes to ESN, wait DELAY (default: settle),
# then invalidate the screen cache.
#
# DELAY: settle | resize | open | fileop
# ---------------------------------------------------------------------------
send_key() {
  local delay="settle"
  case "${1:-}" in
    settle|resize|open|fileop)
      delay="$1"; shift ;;
  esac

  for key in "$@"; do
    local lk="${key,,}"
    case "$lk" in
      escape)   _app_send_atomic 1b 1b 00              ;;
      insert)   _app_send_atomic 1b 5b 32 7e           ;;
      alt+f1)   _app_send_atomic 1b 1b 4f 50           ;;
      alt+f2)   _app_send_atomic 1b 1b 4f 51           ;;
      alt+f3)   _app_send_atomic 1b 1b 4f 52           ;;
      alt+f4)   _app_send_atomic 1b 1b 4f 53           ;;
      alt+f5)   _app_send_atomic 1b 1b 5b 31 35 7e     ;;
      alt+f6)   _app_send_atomic 1b 1b 5b 31 37 7e     ;;
      alt+f7)   _app_send_atomic 1b 1b 5b 31 38 7e     ;;
      alt+f8)   _app_send_atomic 1b 1b 5b 31 39 7e     ;;
      alt+f9)   _app_send_atomic 1b 1b 5b 32 30 7e     ;;
      alt+f10)  _app_send_atomic 1b 1b 5b 32 31 7e     ;;
      *)        _app_send_token "$(_app_key_tmux "$lk")" ;;
    esac
  done

  _app_delay "$delay"
  _screen_invalidate
}

# ---------------------------------------------------------------------------
# send_text [DELAY] TEXT
#
# Type the literal characters of TEXT, then wait DELAY (default:
# settle) and invalidate the screen cache.  No key-name interpretation.
# ---------------------------------------------------------------------------
send_text() {
  local delay="settle"
  case "${1:-}" in
    settle|resize|open|fileop)
      delay="$1"; shift ;;
  esac
  local text="${1:-}"
  if [[ -n "$text" ]]; then
    tmux send-keys -t "$_APP_TMUX_SESSION" -l "$text" 2>/dev/null || true
  fi
  _app_delay "$delay"
  _screen_invalidate
}

# ---------------------------------------------------------------------------
# app_resize COLS ROWS
# ---------------------------------------------------------------------------
app_resize() {
  local cols="$1"
  local rows="$2"
  tmux resize-window -t "$_APP_TMUX_SESSION" -x "$cols" -y "$rows" \
    2>/dev/null || true
  sleep_for_resize
  _screen_invalidate
}
