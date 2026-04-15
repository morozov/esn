unit rv;
{ RV compatibility shim — replaces the original DOS/BP7 RV library.
  Implements the public RV API using FPC Video and Keyboard units. }
{$mode objfpc}{$H+}

interface

uses
  Video, Keyboard, Mouse, SysUtils, DateUtils;

{ ===== CGA color constants ===== }
const
  Black        = 0;  Blue         = 1;
  Green        = 2;  Cyan         = 3;
  Red          = 4;  Magenta      = 5;
  Brown        = 6;  LightGray    = 7;
  DarkGray     = 8;  LightBlue    = 9;
  LightGreen   = 10; LightCyan    = 11;
  LightRed     = 12; LightMagenta = 13;
  Yellow       = 14; White        = 15;

  On  = 1;
  Off = 0;

{ ===== Key code constants (DOS BIOS format: (scan shl 8) or ascii) ===== }
const
  { Function keys }
  _F1  = $3B00; _ShF1  = $5400; _CtrlF1  = $5E00; _AltF1  = $6800;
  _F2  = $3C00; _ShF2  = $5500; _CtrlF2  = $5F00; _AltF2  = $6900;
  _F3  = $3D00; _ShF3  = $5600; _CtrlF3  = $6000; _AltF3  = $6A00;
  _F4  = $3E00; _ShF4  = $5700; _CtrlF4  = $6100; _AltF4  = $6B00;
  _F5  = $3F00; _ShF5  = $5800; _CtrlF5  = $6200; _AltF5  = $6C00;
  _F6  = $4000; _ShF6  = $5900; _CtrlF6  = $6300; _AltF6  = $6D00;
  _F7  = $4100; _ShF7  = $5A00; _CtrlF7  = $6400; _AltF7  = $6E00;
  _F8  = $4200; _ShF8  = $5B00; _CtrlF8  = $6500; _AltF8  = $6F00;
  _F9  = $4300; _ShF9  = $5C00; _CtrlF9  = $6600; _AltF9  = $7000;
  _F10 = $4400; _ShF10 = $5D00; _CtrlF10 = $6700; _AltF10 = $7100;
  _F11 = $8500; _ShF11 = $8700; _CtrlF11 = $8900; _AltF11 = $8B00;
  _F12 = $8600; _ShF12 = $8800; _CtrlF12 = $8A00; _AltF12 = $8C00;

  { Numeric keypad }
  Pad8     = $4800; ShPad8   = $4838; CtrlPad8   = $8D00;
  Pad2     = $5000; ShPad2   = $5032; CtrlPad2   = $9100;
  Pad4     = $4B00; ShPad4   = $4B34; CtrlPad4   = $7300;
  Pad6     = $4D00; ShPad6   = $4D36; CtrlPad6   = $7400;
  Pad5     = $4C00; ShPad5   = $4C35; CtrlPad5   = $8F00;
  Pad0     = $5200; ShPad0   = $5230; CtrlPad0   = $9200;
  PadDel   = $5300; ShPadDel = $522E; CtrlPadDel = $9300;
  PadMinus = $4A2D;                   CtrlPadMinus = $8E00;
  AltPadMinus = $4A00;
  PadPlus  = $4E2B;                   CtrlPadPlus  = $9000;
  AltPadPlus  = $4E00;
  PadStar  = $372A;                   CtrlPadStar  = $9600;
  AltPadStar  = $3700;
  PadEnter = $E00D;                   CtrlPadEnter = $E00A;
  AltPadEnter = $A600;
  PadSlash = $E02F;                   CtrlPadSlash = $9500;
  AltPadSlash = $A400;

  { Cursor keys — enhanced-keyboard format (low byte = $E0) }
  _Up    = $48E0;                    _CtrlUp    = $8DE0; _AltUp    = $9800;
  _Down  = $50E0;                    _CtrlDown  = $91E0; _AltDown  = $A000;
  _Left  = $4BE0;                    _CtrlLeft  = $73E0; _AltLeft  = $9B00;
  _Right = $4DE0;                    _CtrlRight = $74E0; _AltRight = $9D00;
  _Home  = $47E0; _ShHome = $4737;   _CtrlHome  = $77E0; _AltHome  = $9700;
  _End   = $4FE0; _ShEnd  = $4F31;   _CtrlEnd   = $75E0; _AltEnd   = $9F00;
  _PgUp  = $49E0; _ShPgUp = $4939;   _CtrlPgUp  = $84E0; _AltPgUp  = $9900;
  _PgDn  = $51E0; _ShPgDn = $5133;   _CtrlPgDn  = $76E0; _AltPgDn  = $A100;
  _Ins   = $52E0; _ShIns  = $5230;   _CtrlIns   = $92E0; _AltIns   = $A200;
  _Del   = $53E0; _ShDel  = $532E;   _CtrlDel   = $93E0; _AltDel   = $A300;

  { Alphabetic keys }
  _LowA=$1E61; _UpA=$1E41; _CtrlA=$1E01; _AltA=$1E00;
  _LowB=$3062; _UpB=$3042; _CtrlB=$3002; _AltB=$3000;
  _LowC=$2E63; _UpC=$2E43; _CtrlC=$2E03; _AltC=$2E00;
  _LowD=$2064; _UpD=$2044; _CtrlD=$2004; _AltD=$2000;
  _LowE=$1265; _UpE=$1245; _CtrlE=$1205; _AltE=$1200;
  _LowF=$2166; _UpF=$2146; _CtrlF=$2106; _AltF=$2100;
  _LowG=$2267; _UpG=$2247; _CtrlG=$2207; _AltG=$2200;
  _LowH=$2368; _UpH=$2348; _CtrlH=$2308; _AltH=$2300;
  _LowI=$1769; _UpI=$1749; _CtrlI=$1709; _AltI=$1700;
  _LowJ=$246A; _UpJ=$244A; _CtrlJ=$240A; _AltJ=$2400;
  _LowK=$256B; _UpK=$254B; _CtrlK=$250B; _AltK=$2500;
  _LowL=$266C; _UpL=$264C; _CtrlL=$260C; _AltL=$2600;
  _LowM=$326D; _UpM=$324D; _CtrlM=$320D; _AltM=$3200;
  _LowN=$316E; _UpN=$314E; _CtrlN=$310E; _AltN=$3100;
  _LowO=$186F; _UpO=$184F; _CtrlO=$180F; _AltO=$1800;
  _LowP=$1970; _UpP=$1950; _CtrlP=$1910; _AltP=$1900;
  _LowQ=$1071; _UpQ=$1051; _CtrlQ=$1011; _AltQ=$1000;
  _LowR=$1372; _UpR=$1352; _CtrlR=$1312; _AltR=$1300;
  _LowS=$1F73; _UpS=$1F53; _CtrlS=$1F13; _AltS=$1F00;
  _LowT=$1474; _UpT=$1454; _CtrlT=$1414; _AltT=$1400;
  _LowU=$1675; _UpU=$1655; _CtrlU=$1615; _AltU=$1600;
  _LowV=$2F76; _UpV=$2F56; _CtrlV=$2F16; _AltV=$2F00;
  _LowW=$1177; _UpW=$1157; _CtrlW=$1117; _AltW=$1100;
  _LowX=$2D78; _UpX=$2D58; _CtrlX=$2D18; _AltX=$2D00;
  _LowY=$1579; _UpY=$1559; _CtrlY=$1519; _AltY=$1500;
  _LowZ=$2C7A; _UpZ=$2C5A; _CtrlZ=$2C1A; _AltZ=$2C00;

  { Number keys }
  _Num1=$0231; _Alt1=$7800; _Num2=$0332; _Alt2=$7900;
  _Num3=$0433; _Alt3=$7A00; _Num4=$0534; _Alt4=$7B00;
  _Num5=$0635; _Alt5=$7C00; _Num6=$0736; _Alt6=$7D00;
  _Num7=$0837; _Alt7=$7E00; _Num8=$0938; _Alt8=$7F00;
  _Num9=$0A39; _Alt9=$8000; _Num0=$0B30; _Alt0=$8100;

  { Miscellaneous }
  _Space       = $3920;
  _BkSp        = $0E08; _CtrlBkSp    = $0E7F; _AltBkSp     = $0E00;
  _Tab         = $0F09; _ShTab       = $0F00; _CtrlTab      = $9400;
  _BkSlash     = $2B5C; _ShBkSlash   = $2B7C; _CtrlBkSlash  = $2B1C;
  _AltBkSlash  = $2B00;
  _AltTab    = $A500;
  _Enter     = $1C0D;               _CtrlEnter = $1C0A;
  _AltEnter  = $1C00;
  _Esc       = $011B;               _AltEsc    = $0100;
  _AltMinus  = $8200;
  _AltPlus   = $8300;

{ ===== Path component selectors (from RVDOS) ===== }
const
  _dir  = 1;
  _name = 2;
  _ext  = 3;

{ ===== Variables ===== }
var
  GmaxX, GmaxY: word;
  HalfMaxX, HalfMaxY: word;
  TextAttr: byte;
  SegB800: word;    { unused; retained for source compatibility }
  Moused: boolean;
  { Optional idle callback invoked while rKey polls for input. }
  OnIdle: procedure;
  { Optional resize callback invoked when the terminal is resized. }
  OnResize: procedure;

{ Activate Video/Keyboard subsystem.  Must be called once by the
  main program before any screen or keyboard operations.  Skipped
  by unit-test runners that only need rv constants and variables. }
procedure RvInit;

{ ===== Screen / color ===== }
procedure Cls;
procedure ClrBox(x1, y1, x2, y2: byte);
procedure Colour(paper, ink: byte);
procedure Print(x, y: byte; const s: string);
procedure MPrint(x, y: byte; const s: string);
procedure CMPrint(paper, ink, x, y: word; const s: string);
procedure PrintSelf(paper, ink, x, y, len: byte);
procedure CurOn;
procedure CurOff;
procedure GotoXY(x, y: byte);
function  WhereX: byte;
function  WhereY: byte;
function  Space(n: integer): string;
procedure Flash(offOn: byte);

{ Paint single-column separator zones for a directory row.
  Draws two | separators at posX+cw and posX+2*cw (cw=(panelW+1)/3)
  with fill zones in between.  dx is the name-column width. }
procedure PaintRowSeps(posX, panelW: integer; dx: byte;
  py, paper, ink, sepInk: integer);

procedure ProcessBar(act,per,total:byte; title:string);

{ ===== Window save / restore ===== }
procedure sPutWin(x1, y1, x2, y2: byte);
procedure scPutWin(paper, ink, x1, y1, x2, y2: byte);
procedure RestScr;
procedure FlushWinStack;

{ ===== Clock ===== }
{ Draw current time (HH:MM:SS) at top-right corner of screen. }
procedure DrawClock;

{ ===== Keyboard ===== }
function  rKey: word;
procedure rPause;

{ ===== Dialog helpers ===== }
procedure cmCentre(paper, ink, y: byte; const s: string);
procedure CStatusLineColor(bk, txt1, txt2: byte; y: byte;
  const s: string);

{ Return the visible length of s, ignoring ~` toggle markers
  and lone ` chars. }
function CCLen(const s: string): integer;

{ Render s at (x,y) interpreting ~` as a color toggle.
  Starts in normal color (bkNT/txtNT); each ~` switches
  to/from highlight. }
procedure StatusLineColor(paper, ink, papermark, inkmark,
  x, y: integer; const s: string);
procedure cStatusBar(bkNT, txtNT, bkST, txtST, focus: byte;
  const s: string);
procedure cButton(bkA, txtA, bkSh, txtSh, x, y: byte;
  const s: string; active: boolean);

{ Centre s0 within pw columns (accounting for ~` markup),
  pad/truncate to pw, draw with StatusLineColor. }
procedure InfoLine(bkNT,txtNT,bkST,txtST:byte;
                   x:byte; y:integer; s0:string;
                   pw:integer);

{ ===== Text input field ===== }
var
  scanf_esc: boolean;
  scanf_tab: boolean;
  scanf_shtab: boolean;
function scanf(x, y: byte; const def: string;
  maxLen, visLen, startPos: byte): string;

{ ===== Popup item menu ===== }
const
  MenuMax = 50;
var
  menu_Name    : array[1..MenuMax] of string;
  menu_ins     : array[1..MenuMax] of boolean;
  menu_mayins  : boolean;
  menu_title   : string;
  menu_visible : integer;
  menu_Total   : integer;
  menu_f       : integer;
  menu_posx    : integer;
  menu_posy    : integer;
  menu_bkNT,   menu_txtNT,
  menu_bkST,   menu_txtST,
  menu_bkMarkNT, menu_txtMarkNT,
  menu_bkMarkST, menu_txtMarkST : integer;
  w_twosided : boolean;
  w_shadow   : boolean;

{ Display popup menu using menu_* globals; return selected item
  (1-based), or 0 on Esc.  Resets menu_posx/posy to 255 on exit. }
function ChooseItem: byte;

{ ===== String utilities ===== }
function StrR(n: int64): string;
function ExtNum(const s: string): string;
function ChangeChar(s: string; fromCh, toCh: char): string;
function LeftStr(const s: string; n: byte): string;
function RightStr(const s: string; n: byte): string;
function LeftPad(s: string; n: byte): string;
function RightPad(s: string; n: byte): string;
function NoSpace(s: string): string;
function NoSpaceLR(s: string): string;
function Vall(tempein: string): longint;
function Fill(len: byte; symb: char): string;
function WithOut(s, chars: string): string;
function CLen(s: string): integer;
function LZ(w: word): string;
function eFiles(n: longint): string;
function ewFiles(n: longint): string;
function ReverseStr(s: string): string;
function Wild(input_word, wilds: string;
  upcase_wish: boolean): boolean;
function StrHi(s: string): string;
function MatchMask(name, mask: string): boolean;
function SPlural(n: longint): string;
function sRexpand(s: string; tob: byte): string;

{ ===== Path / file helpers ===== }
function  CurentDir: string;
function  CheckDir(path: string): byte;
function  CheckDirFile(path: string): byte;
function  CreateDir(path: string): boolean;
function  FileLen(path: string): int64;
function  GetOf(fullpath: string; what: byte): string;

{ ===== INI file helpers ===== }
procedure GetProfile(inifile, section, key: string;
  var value: string);
procedure WriteProfile(inifile, section, key, value: string);

{ ===== Disk / media helpers ===== }
function  DiskStatus(drive: byte): byte;
function  DiskFree(drive: byte): longint;
function  DiskFreePath(const dir: string): Int64;
function  GetDevId(const dir: string): Int64;
function  DiskSize(drive: byte): longint;
function  FormatFreeBytes(freeBytes: Int64): string;

{ ===== Conversion helpers ===== }
function  Dec2Hex(decn: string): string;

{ ===== Mouse ===== }
procedure MouseOn;
procedure MouseOff;

implementation

uses
  Classes
  {$IFDEF UNIX}
  , BaseUnix
  {$ENDIF}
  ;

{$I rvcrt.inc}
{$I rvstr.inc}
{$I rvdos.inc}
{$I rvputs.inc}
{$I rvkeyb.inc}
{$I rvconv.inc}

{ ===== Initialization / finalization ===== }

initialization
  rvActive     := false;
  SegB800      := 0;
  Moused       := false;
  OnIdle       := nil;
  OnResize     := nil;
  needResize   := false;
  needQuit     := false;
  curX         := 1;
  curY         := 1;
  winTop       := 0;
  GmaxX        := 80;
  GmaxY        := 25;
  HalfMaxX     := GmaxX div 2;
  HalfMaxY     := GmaxY div 2;
  TextAttr     := (Black shl 4) or LightGray;
  menu_posx    := 255;
  menu_posy    := 255;
  menu_visible := 255;
  menu_mayins  := false;
  menu_bkNT    := -1; menu_txtNT    := -1;
  menu_bkST    := -1; menu_txtST    := -1;
  menu_bkMarkNT := -1; menu_txtMarkNT := -1;
  menu_bkMarkST := -1; menu_txtMarkST := -1;
  w_twosided   := true;
  w_shadow     := true;
  scanf_tab    := false;
  scanf_shtab  := false;

finalization
  if rvActive then begin
    CurOn;
    MouseOff;
    DoneKeyboard;
    DoneVideo;
    { Restore terminal palette to defaults before leaving. }
    {$IFDEF UNIX}
    Write(#27']104'#27'\');
    {$ENDIF}
    { Leave alternate screen buffer: restores the original screen
      contents and cursor position from before the program
      launched. }
    Write(#27'[?1049l');
  end;

end.
