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

  { CP437 box-drawing characters (byte values) }
  boxTL  = #201;  { ╔ }
  boxTR  = #187;  { ╗ }
  boxBL  = #200;  { ╚ }
  boxBR  = #188;  { ╝ }
  boxV   = #186;  { ║ }
  boxH   = #205;  { ═ }

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

{ CP437 mapping for ASCII control bytes 0x00..0x1F. iconv treats
  these as control characters and passes them through unchanged,
  but in CP437 the same bytes are printable glyphs (•, ▲, ↑, …).
  Table copied verbatim from FPC's `convert_lowascii_to_Unicode`
  (lib/fpc/rtl-console/src/inc/video.inc). }
const
  cp437LowAscii: array[#0..#31] of WideChar = (
    #8199, #9786, #9787, #9829, #9830, #9827, #9824, #8226,
    #9688, #9675, #9689, #9794, #9792, #9834, #9835, #9788,
    #9658, #9668, #8597, #8252, #0182, #0167, #9644, #8616,
    #8593, #8595, #8594, #8592, #8735, #8596, #9650, #9660
  );

{ Write one cell to EnhancedVideoBuf; (x,y) are 1-based.
  c is interpreted as CP437; low-ASCII (≤#31) and #127 use the
  hand-rolled table above, the rest go through iconv (cwstring)
  via CP437 codepage tagging. }
procedure SetCell(x, y: word; attr: byte; c: char);
var
  offset: longword;
  raw: RawByteString;
  egc: UnicodeString;
begin
  if (x < 1) or (y < 1) or
     (x > ScreenWidth) or (y > ScreenHeight) then
    exit;
  offset := longword(y - 1) * ScreenWidth + longword(x - 1);
  if c <= #31 then
    egc := cp437LowAscii[c]
  else if c = #127 then
    egc := #$2302
  else
  begin
    raw := c;
    SetCodePage(raw, 437, false);
    egc := UnicodeString(raw);
  end;
  EnhancedVideoBuf[offset].ExtendedGraphemeCluster := egc;
  EnhancedVideoBuf[offset].Attribute := attr;
end;

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
  attr: byte;
  i: integer;
begin
  attr := (paper shl 4) or (ink and $0F);
  { Interior rows: ║ spaces ║ }
  for i := y1 to y2 do
    CMPrint(paper, ink, x1, i, boxV + Space(x2 - x1 - 1) + boxV);
  { Top / bottom horizontal bars }
  for i := x1 + 1 to x2 - 1 do begin
    SetCell(i, y1, attr, boxH);
    SetCell(i, y2, attr, boxH);
  end;
  { Corners }
  SetCell(x1, y1, attr, boxTL);
  SetCell(x2, y1, attr, boxTR);
  SetCell(x1, y2, attr, boxBL);
  SetCell(x2, y2, attr, boxBR);
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

procedure CMPrint(paper, ink, x, y: word; const s: string);
var
  attr: byte;
  i: integer;
begin
  attr := (byte(paper) shl 4) or (byte(ink) and $0F);
  for i := 1 to Length(s) do
    SetCell(x + word(i) - 1, y, attr, s[i]);
end;

procedure MPrint(x, y: word; const s: string);
begin
  CMPrint(TextAttr shr 4, TextAttr and $0F, x, y, s);
end;

procedure Print(x, y: word; const s: string);
begin
  MPrint(x, y, s);
  curX := x + word(Length(s));
  curY := y;
  SetCursorPos(curX - 1, curY - 1);
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

procedure PaintRowSeps(posX, panelW: integer; dx: word;
  py, paper, ink, sepInk: integer);
var
  cw: integer;
begin
  cw := (panelW + 1) div 3;
  if cw > integer(dx) then
    CMPrint(paper, ink, posX + integer(dx), py,
      Space(cw - integer(dx)));
  CMPrint(paper, sepInk, posX + cw, py, #179);
  CMPrint(paper, ink, posX + cw + 1, py, Space(cw - 1));
  CMPrint(paper, sepInk, posX + 2 * cw, py, #179);
  CMPrint(paper, ink, posX + 2 * cw + 1, py,
    Space(panelW - 2 * cw));
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
