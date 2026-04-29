{ ===== Internal constants and types ===== }

const
  maxWinStack = 8;

  { Scan codes for control characters Ctrl+A..Z (indexed 1..26) }
  ctrlScanTab: array[1..26] of byte = (
    $1E, $30, $2E, $20, $12, $21, $22, $23,  { A..H }
    $17, $24, $25, $26, $32, $31, $18, $19,  { I..P }
    $10, $13, $1F, $14, $16, $2F, $11, $2D,  { Q..X }
    $15, $2C                                  { Y..Z }
  );

  { Scan codes for printable ASCII a..z (0-based index from 'a') }
  ltrScanTab: array[0..25] of byte = (
    $1E, $30, $2E, $20, $12, $21, $22, $23,  { a..h }
    $17, $24, $25, $26, $32, $31, $18, $19,  { i..p }
    $10, $13, $1F, $14, $16, $2F, $11, $2D,  { q..x }
    $15, $2C                                  { y..z }
  );

  { Scan codes for digits 0..9 (0-based) }
  digScanTab: array[0..9] of byte = (
    $0B, $02, $03, $04, $05, $06, $07, $08, $09, $0A
  );

  boxTL: UnicodeString = '╔';
  boxTR: UnicodeString = '╗';
  boxBL: UnicodeString = '╚';
  boxBR: UnicodeString = '╝';
  boxV:  UnicodeString = '║';
  boxH:  UnicodeString = '═';

  { CP437 graphical glyphs for byte values that are control codes
    in ASCII (0x00–0x1F, 0x7F).  In the original DOS text mode,
    each cell of the BIOS framebuffer was a glyph index into the
    character ROM, so these bytes rendered as their CP437 shapes.
    A modern terminal would interpret them as control codes; we
    rewrite them at the cell-write boundary to keep the visual
    behaviour and avoid letting ESC/BEL/BS escape into the output
    stream. }
  cp437ControlGlyph: array[0..31] of WideChar = (
    ' ',  { 00 NUL — blank }
    '☺',  { 01 }
    '☻',  { 02 }
    '♥',  { 03 }
    '♦',  { 04 }
    '♣',  { 05 }
    '♠',  { 06 }
    '•',  { 07 }
    '◘',  { 08 }
    '○',  { 09 }
    '◙',  { 0A }
    '♂',  { 0B }
    '♀',  { 0C }
    '♪',  { 0D }
    '♫',  { 0E }
    '☼',  { 0F }
    '►',  { 10 }
    '◄',  { 11 }
    '↕',  { 12 }
    '‼',  { 13 }
    '¶',  { 14 }
    '§',  { 15 }
    '▬',  { 16 }
    '↨',  { 17 }
    '↑',  { 18 }
    '↓',  { 19 }
    '→',  { 1A }
    '←',  { 1B }
    '∟',  { 1C }
    '↔',  { 1D }
    '▲',  { 1E }
    '▼'   { 1F }
  );

type
  TSavedWin = record
    x1, y1, x2, y2: word;
    buf: TEnhancedVideoBuf;
  end;

{ ===== Module-level state ===== }
var
  winStack: array[1..maxWinStack] of TSavedWin;
  winTop: byte;
  curX: word;
  curY: word;
  needResize: boolean;
  needQuit: boolean;
  rvActive: boolean;
  {$IFDEF WINDOWS}
  savedOutMode: DWORD;
  savedInMode: DWORD;
const
  ENABLE_MOUSE_INPUT                  = $0010;
  ENABLE_EXTENDED_FLAGS               = $0080;
  ENABLE_VIRTUAL_TERMINAL_INPUT       = $0200;
  ENABLE_VIRTUAL_TERMINAL_PROCESSING  = $0004;
  {$ENDIF}

procedure UpdateScreenSize;
var
  m: TVideoMode;
  wantCols, wantRows: word;
  {$IFDEF WINDOWS}
  hOut: THandle;
  csbi: TConsoleScreenBufferInfo;
  {$ENDIF}
  {$IFDEF UNIX}
  ws: TWinSize;
  {$ENDIF}
begin
  { FPC's Video unit caps ScreenWidth at 240 (Unix, and at least
    some Windows console configurations).  Query the real terminal
    dimensions from the OS and tell Video to allocate a matching
    buffer.  The SetVideoMode call is a no-op when FPC's detected
    size already matches the OS. }
  wantCols := ScreenWidth;
  wantRows := ScreenHeight;
  {$IFDEF UNIX}
  if FpIoctl(1, TIOCGWINSZ, @ws) = 0 then
  begin
    if ws.ws_col > 0 then wantCols := ws.ws_col;
    if ws.ws_row > 0 then wantRows := ws.ws_row;
  end;
  {$ENDIF}
  {$IFDEF WINDOWS}
  hOut := GetStdHandle(STD_OUTPUT_HANDLE);
  if (hOut <> INVALID_HANDLE_VALUE) and
     GetConsoleScreenBufferInfo(hOut, csbi) then
  begin
    wantCols := csbi.srWindow.Right - csbi.srWindow.Left + 1;
    wantRows := csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
  end;
  {$ENDIF}
  if (wantCols <> ScreenWidth) or (wantRows <> ScreenHeight) then
  begin
    m.Col := wantCols;
    m.Row := wantRows;
    m.Color := true;
    { If the driver rejects the mode, fall through with FPC's
      reported ScreenWidth/ScreenHeight: rendering stays correct
      within that smaller area rather than writing past VideoBuf. }
    SetVideoMode(m);
  end;
  GmaxX := ScreenWidth;
  GmaxY := ScreenHeight;
  HalfMaxX := GmaxX div 2;
  HalfMaxY := GmaxY div 2;
end;

{$IFDEF UNIX}
procedure SigWinchHandler(sig: longint); cdecl;
begin
  if sig = sig then needResize := true;
end;

procedure SigTermHandler(sig: longint); cdecl;
begin
  if sig = sig then needQuit := true;
end;
{$ENDIF}

{ ===== Internal helpers ===== }


{ Return scan code for an ASCII character. }
function charScan(c: char): byte;
var
  lo: char;
begin
  lo := Chr(Ord(c) or $20);  { cheap ASCII tolower }
  if (lo >= 'a') and (lo <= 'z') then
    result := ltrScanTab[Ord(lo) - Ord('a')]
  else if (c >= '0') and (c <= '9') then
    result := digScanTab[Ord(c) - Ord('0')]
  else case c of
    ' ':  result := $39;
    '-':  result := 0;    '=': result := $0D;
    '[':  result := $1A;  ']': result := $1B;
    ';':  result := $27;  '''': result := $28;
    '`':  result := $29;  '\': result := $2B;
    ',':  result := $33;  '.': result := $34;
    '/':  result := $35;
    else  result := 0;
  end;
end;

{ Draw a double-line box; fills interior with spaces. }
procedure DrawBox(paper, ink: byte; x1, y1, x2, y2: word);
var
  i, innerW: integer;
begin
  { Inverted coordinates: the parameters are word, so x2-x1 / y2-y1
    underflow to huge positives when the bounds are reversed.  Bail
    out instead of painting a degenerate box at unrelated rows. }
  if (y2 < y1) or (x2 < x1) then exit;
  innerW := x2 - x1 - 1;
  if innerW < 0 then innerW := 0;
  CMPrint(paper, ink, x1, y1,
          boxTL + Fill(innerW, boxH) + boxTR);
  for i := y1 + 1 to y2 - 1 do
    CMPrint(paper, ink, x1, i, boxV + Space(innerW) + boxV);
  CMPrint(paper, ink, x1, y2,
          boxBL + Fill(innerW, boxH) + boxBR);
end;

{ Save a screen region to the win stack. Coordinates are 1-based,
  clamped to screen bounds. }
procedure SaveRegion(x1, y1, x2, y2: word);
var
  w, h: word;
  row, col: integer;
  k: longword;
begin
  if winTop >= maxWinStack then
    exit;
  { Clamp to screen }
  if x2 > ScreenWidth  then x2 := ScreenWidth;
  if y2 > ScreenHeight then y2 := ScreenHeight;
  if x1 > x2 then exit;
  if y1 > y2 then exit;
  Inc(winTop);
  winStack[winTop].x1 := x1;
  winStack[winTop].y1 := y1;
  winStack[winTop].x2 := x2;
  winStack[winTop].y2 := y2;
  w := x2 - x1 + 1;
  h := y2 - y1 + 1;
  SetLength(winStack[winTop].buf, longword(w) * longword(h));
  k := 0;
  for row := y1 - 1 to y2 - 1 do
    for col := x1 - 1 to x2 - 1 do begin
      winStack[winTop].buf[k] :=
        EnhancedVideoBuf[row * ScreenWidth + col];
      Inc(k);
    end;
end;

{ ===== Screen / color ===== }

procedure Colour(paper, ink: byte);
begin
  TextAttr := (paper shl 4) or (ink and $0F);
end;

procedure CMPrint(paper, ink, x, y: word; const s: UnicodeString);
var
  attr: byte;
  cw, j: integer;
  col: word;
  cluster, glyph: UnicodeString;
  offset: longword;
begin
  attr := (byte(paper) shl 4) or (byte(ink) and $0F);
  col := x;
  for cluster in
    TUnicodeStringExtendedGraphemeClustersEnumerator.Create(s) do
  begin
    glyph := cluster;
    if Length(glyph) = 1 then
      if glyph[1] < #$20 then glyph := cp437ControlGlyph[Ord(glyph[1])]
      else if glyph[1] = #$7F then glyph := '⌂';
    cw := ExtendedGraphemeClusterDisplayWidth(glyph);
    if cw <= 0 then cw := 1;
    if (col >= 1) and (col <= ScreenWidth) and
       (y >= 1) and (y <= ScreenHeight) then
    begin
      offset := longword(y - 1) * ScreenWidth + longword(col - 1);
      EnhancedVideoBuf[offset].ExtendedGraphemeCluster := glyph;
      EnhancedVideoBuf[offset].Attribute := attr;
      { Wide chars (cw>1) span multiple cells.  Clear the trailing
        cells so stale content from a previous render at the same
        position doesn't bleed through where the wide glyph
        visually overlays. }
      for j := 1 to cw - 1 do
        if col + word(j) <= ScreenWidth then
        begin
          offset := longword(y - 1) * ScreenWidth +
                    longword(col - 1 + word(j));
          EnhancedVideoBuf[offset].ExtendedGraphemeCluster := '';
          EnhancedVideoBuf[offset].Attribute := attr;
        end;
    end;
    Inc(col, cw);
  end;
end;

procedure MPrint(x, y: word; const s: UnicodeString);
begin
  CMPrint(TextAttr shr 4, TextAttr and $0F, x, y, s);
end;

procedure PrintSelf(paper, ink: byte; x, y, len: word);
var
  attr: byte;
  i: integer;
  offset: longword;
begin
  attr := (paper shl 4) or (ink and $0F);
  for i := 0 to len - 1 do begin
    offset := longword(y - 1) * ScreenWidth + longword(x - 1 + i);
    if offset < longword(ScreenWidth) * ScreenHeight then
      EnhancedVideoBuf[offset].Attribute := attr;
  end;
end;

function Space(n: integer): string;
begin
  if n <= 0 then
    result := ''
  else
    result := StringOfChar(' ', n);
end;

procedure Cls;
var
  attr: byte;
  i: integer;
begin
  attr := TextAttr;
  Colour(Black, LightGray);
  for i := 1 to GmaxY do
    CMPrint(Black, LightGray, 1, i, Space(GmaxX));
  TextAttr := attr;
  GotoXY(1, 1);
  UpdateScreen(false);
end;

procedure ClrBox(x1, y1, x2, y2: word);
var
  i: integer;
  p, ink: byte;
begin
  p := TextAttr shr 4;
  ink := TextAttr and $0F;
  for i := y1 to y2 do
    CMPrint(p, ink, x1, i, Space(x2 - x1 + 1));
end;

procedure GotoXY(x, y: word);
{$IFDEF WINDOWS}
var
  hOut: THandle;
  coord: TCoord;
begin
  curX := x;
  curY := y;
  SetCursorPos(x - 1, y - 1);
  hOut := GetStdHandle(STD_OUTPUT_HANDLE);
  coord.X := x - 1;
  coord.Y := y - 1;
  SetConsoleCursorPosition(hOut, coord);
end;
{$ELSE}
begin
  curX := x;
  curY := y;
  SetCursorPos(x - 1, y - 1);
end;
{$ENDIF}

function WhereX: word;
begin
  result := curX;
end;

function WhereY: word;
begin
  result := curY;
end;

procedure CurOn;
{$IFDEF WINDOWS}
var
  hOut: THandle;
  cci: TConsoleCursorInfo;
begin
  hOut := GetStdHandle(STD_OUTPUT_HANDLE);
  if GetConsoleCursorInfo(hOut, cci) then
  begin
    cci.bVisible := True;
    SetConsoleCursorInfo(hOut, cci);
  end;
  SetCursorType(crUnderLine);
end;
{$ELSE}
begin
  SetCursorType(crUnderLine);
end;
{$ENDIF}

procedure CurOff;
{$IFDEF WINDOWS}
var
  hOut: THandle;
  cci: TConsoleCursorInfo;
begin
  hOut := GetStdHandle(STD_OUTPUT_HANDLE);
  if GetConsoleCursorInfo(hOut, cci) then
  begin
    cci.bVisible := False;
    SetConsoleCursorInfo(hOut, cci);
  end;
  SetCursorType(crHidden);
end;
{$ELSE}
begin
  SetCursorType(crHidden);
end;
{$ENDIF}

procedure Flash(offOn: byte);
begin
  { offOn checked to satisfy compiler; no-op on modern terminals. }
  if offOn = 0 then exit;
end;

{ ===== Clock ===== }

procedure DrawClock;
var
  h, m, s, ms: word;
  ts: string;
  col: word;
begin
  DecodeTime(Now, h, m, s, ms);
  { 10 chars: ' HH:MM:SS ' — matches original CLOCK.PAS layout }
  ts := Format(' %.2d:%.2d:%.2d ', [h, m, s]);
  { Start at GmaxX-9 so the string ends at column GmaxX }
  col := GmaxX - 9;
  CMPrint(Blue, LightCyan, col, 1, ts);
  UpdateScreen(false);
end;

{ ===== Mouse ===== }

procedure MouseOn;
begin
  InitMouse;
  Write(StdErr, #27'[?1000h');
  Flush(StdErr);
end;

procedure MouseOff;
begin
  Write(StdErr, #27'[?1000l');
  Flush(StdErr);
  DoneMouse;
end;

{ ===== RvInit — explicit Video/Keyboard activation ===== }

procedure RvInit;
begin
  if rvActive then exit;
  {$IFDEF WINDOWS}
  { Save original console modes and enable virtual terminal processing
    on stdout so ANSI escape sequences are interpreted. }
  GetConsoleMode(GetStdHandle(STD_OUTPUT_HANDLE), @savedOutMode);
  SetConsoleMode(GetStdHandle(STD_OUTPUT_HANDLE),
    savedOutMode or ENABLE_VIRTUAL_TERMINAL_PROCESSING);
  GetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), @savedInMode);
  {$ENDIF}
  { Enter alternate screen buffer: saves the current screen contents
    and cursor position, restored when we leave on exit. }
  Write(#27'[?1049h');
  Flush(Output);
  InitEnhancedVideo;
  InitKeyboard;
  {$IFDEF WINDOWS}
  { Disable ENABLE_PROCESSED_INPUT to prevent conhost/Windows Terminal
    from intercepting F11 / Alt+Enter as global shortcuts. }
  SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE),
    ENABLE_EXTENDED_FLAGS or ENABLE_MOUSE_INPUT);
  {$ENDIF}
  MouseOn;
  {$IFDEF UNIX}
  fpSignal(SIGWINCH, @SigWinchHandler);
  fpSignal(SIGTERM, @SigTermHandler);
  fpSignal(SIGHUP, @SigTermHandler);
  {$ENDIF}
  UpdateScreenSize;
  CurOff;
  rvActive := true;
end;
