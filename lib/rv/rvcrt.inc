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
    x1, y1, x2, y2: byte;
    buf: pointer;
    bufSize: word;
  end;

{ ===== Module-level state ===== }
var
  winStack: array[1..maxWinStack] of TSavedWin;
  winTop: byte;
  curX: byte;
  curY: byte;
  needResize: boolean;
  needQuit: boolean;
  rvActive: boolean;

procedure UpdateScreenSize;
{$IFDEF WINDOWS}
var
  hOut: THandle;
  csbi: TConsoleScreenBufferInfo;
{$ENDIF}
begin
  GmaxX := ScreenWidth;
  GmaxY := ScreenHeight;
  {$IFDEF WINDOWS}
  hOut := GetStdHandle(STD_OUTPUT_HANDLE);
  if (hOut <> INVALID_HANDLE_VALUE) and
     GetConsoleScreenBufferInfo(hOut, csbi) then
  begin
    GmaxX := csbi.srWindow.Right - csbi.srWindow.Left + 1;
    GmaxY := csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
  end;
  {$ENDIF}
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

{ Write one cell to VideoBuf; (x,y) are 1-based. }
procedure SetCell(x, y: byte; attr: byte; c: char);
var
  offset: word;
begin
  if (x < 1) or (y < 1) or
     (x > ScreenWidth) or (y > ScreenHeight) then
    exit;
  offset := word(y - 1) * ScreenWidth + word(x - 1);
  VideoBuf^[offset] := (word(attr) shl 8) or word(Ord(c));
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
procedure DrawBox(paper, ink, x1, y1, x2, y2: byte);
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
procedure SaveRegion(x1, y1, x2, y2: byte);
var
  w, h: byte;
  sz: word;
  dst: PWord;
  row, col: integer;
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
  sz := word(w) * word(h) * SizeOf(TVideoCell);
  winStack[winTop].bufSize := sz;
  GetMem(winStack[winTop].buf, sz);
  dst := PWord(winStack[winTop].buf);
  for row := y1 - 1 to y2 - 1 do
    for col := x1 - 1 to x2 - 1 do begin
      dst^ := VideoBuf^[row * ScreenWidth + col];
      Inc(dst);
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
    SetCell(byte(x) + byte(i) - 1, byte(y), attr, s[i]);
end;

procedure MPrint(x, y: byte; const s: string);
begin
  CMPrint(TextAttr shr 4, TextAttr and $0F, x, y, s);
end;

procedure Print(x, y: byte; const s: string);
begin
  MPrint(x, y, s);
  curX := x + byte(Length(s));
  curY := y;
  SetCursorPos(curX - 1, curY - 1);
end;

procedure PrintSelf(paper, ink, x, y, len: byte);
var
  attr: byte;
  i: integer;
  offset: word;
begin
  attr := (paper shl 4) or (ink and $0F);
  for i := 0 to len - 1 do begin
    offset := word(y - 1) * ScreenWidth + word(x - 1 + i);
    if offset < ScreenWidth * ScreenHeight then
      VideoBuf^[offset] :=
        (word(attr) shl 8) or (VideoBuf^[offset] and $00FF);
  end;
end;

function Space(n: integer): string;
begin
  if n <= 0 then
    result := ''
  else
    result := StringOfChar(' ', n);
end;

procedure PaintRowSeps(posX, panelW: integer; dx: byte;
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

procedure ClrBox(x1, y1, x2, y2: byte);
var
  i: integer;
  p, ink: byte;
begin
  p := TextAttr shr 4;
  ink := TextAttr and $0F;
  for i := y1 to y2 do
    CMPrint(p, ink, x1, i, Space(x2 - x1 + 1));
end;

procedure GotoXY(x, y: byte);
begin
  curX := x;
  curY := y;
  SetCursorPos(x - 1, y - 1);
end;

function WhereX: byte;
begin
  result := curX;
end;

function WhereY: byte;
begin
  result := curY;
end;

procedure CurOn;
begin
  SetCursorType(crUnderLine);
end;

procedure CurOff;
begin
  SetCursorType(crHidden);
end;

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
  col: byte;
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
  { Enter alternate screen buffer: saves the current screen contents
    and cursor position, restored when we leave on exit. }
  Write(#27'[?1049h');
  InitVideo;
  InitKeyboard;
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
