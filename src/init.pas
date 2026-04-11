{$mode objfpc}{$H+}
Unit Init;
Interface

Procedure snInit(sys:boolean);
procedure SaveConfig;

Implementation
Uses
     SysUtils, RV,
     Vars, sn_Mem, sn_Obj, Palette, Main, sn_KBD;


function IniPath: string;
 begin
  IniPath := IncludeTrailingPathDelimiter(StartDir) + 'sn.ini';
end;

function ReadBool(const sec, key: string; def: boolean): boolean;
var
  s: string;
begin
  if def then s := '1' else s := '0';
  GetProfile(IniPath, sec, key, s);
  ReadBool := (s = '1');
end;

function ReadByte(const sec, key: string; def: byte): byte;
var
  s: string;
  v: longint;
  code: integer;
begin
  Str(def, s);
  GetProfile(IniPath, sec, key, s);
  Val(s, v, code);
  if (code <> 0) or (v < 0) or (v > 255) then
    ReadByte := def
  else
    ReadByte := byte(v);
 end;

function ReadWord(const sec, key: string; def: word): word;
var
  s: string;
  v: longint;
  code: integer;
 begin
  Str(def, s);
  GetProfile(IniPath, sec, key, s);
  Val(s, v, code);
  if code <> 0 then
    ReadWord := def
  else
    ReadWord := word(v);
 end;

procedure LoadConfig;
var
  s: string;
begin
  s := '';
  GetProfile(IniPath, 'Interface', 'Language', s);
  if s = 'Rus' then Lang := Rus else Lang := Eng;

  CmdLine     := ReadBool('Interface', 'CmdLine',    CmdLine);
  DiskLine    := ReadBool('Interface', 'DiskLine',   DiskLine);
  HideHidden  := ReadBool('Interface', 'HideHidden', HideHidden);
  snMouse     := ReadBool('Interface', 'Mouse',      snMouse);
  SaveOnExit  := ReadBool('Interface', 'SaveOnExit', SaveOnExit);
  bLoadDesktop := ReadBool('Interface', 'LoadDesktop', bLoadDesktop);
  BkSpUpDir   := ReadBool('Interface', 'BkSpUpDir',  BkSpUpDir);
  RestoreVideo := ReadBool('Interface', 'RestoreVideo', RestoreVideo);
  Del_F8      := ReadBool('Interface', 'Del_F8',     Del_F8);
  InternalView := ReadBool('Interface', 'InternalView', InternalView);

  lp.SortType := ReadByte('Sorting', 'SortLeft',  lp.SortType);
  rp.SortType := ReadByte('Sorting', 'SortRight', rp.SortType);

  GetProfile(IniPath, 'Masks', 'PlusMask',  PlusMask);
  GetProfile(IniPath, 'Masks', 'MinusMask', MinusMask);
  GetProfile(IniPath, 'Masks', 'Group1',    group1);
  GetProfile(IniPath, 'Masks', 'Group2',    group2);
  GetProfile(IniPath, 'Masks', 'Group3',    group3);
  GetProfile(IniPath, 'Masks', 'Group4',    group4);
  GetProfile(IniPath, 'Masks', 'Group5',    group5);
  GetProfile(IniPath, 'Masks', 'Exe',       gExe);
  GetProfile(IniPath, 'Masks', 'Arc',       gArc);

  TRDOS3          := ReadBool('ZX', 'TRDOS3',     TRDOS3);
  AutoMove        := ReadBool('ZX', 'AutoMove',   AutoMove);
  hob2scl         := ReadBool('ZX', 'hob2scl',    hob2scl);
  MakeBoot        := ReadBool('ZX', 'MakeBoot',   MakeBoot);
  CheckMedia      := ReadBool('ZX', 'CheckMedia', CheckMedia);
  HobetaStartAddr := ReadWord('ZX', 'HobetaStartAddr', HobetaStartAddr);
  noHobNaming     := ReadByte('ZX', 'noHobNaming', noHobNaming);

  if bLoadDesktop then begin
    s := string(lp.pcnd);
    GetProfile(IniPath, 'Desktop', 'LeftPath', s);
    lp.pcnd := ShortString(IncludeTrailingPathDelimiter(s));
    s := string(rp.pcnd);
    GetProfile(IniPath, 'Desktop', 'RightPath', s);
    rp.pcnd := ShortString(IncludeTrailingPathDelimiter(s));
    s := 'Right';
    GetProfile(IniPath, 'Desktop', 'FocusedPanel', s);
    if s = 'Left' then focus := Left else focus := Right;
  end;
end;

procedure SaveConfig;
var
  ini: string;

  procedure WB(const sec, key: string; v: boolean);
  begin
    if v then WriteProfile(ini, sec, key, '1')
    else WriteProfile(ini, sec, key, '0');
  end;

  procedure WW(const sec, key: string; v: word);
  var s: string;
  begin
    Str(v, s);
    WriteProfile(ini, sec, key, s);
  end;

begin
  ini := IniPath;

  if Lang = Rus then
    WriteProfile(ini, 'Interface', 'Language', 'Rus')
  else
    WriteProfile(ini, 'Interface', 'Language', 'Eng');
  WB('Interface', 'CmdLine',      CmdLine);
  WB('Interface', 'DiskLine',     DiskLine);
  WB('Interface', 'HideHidden',   HideHidden);
  WB('Interface', 'Mouse',        snMouse);
  WB('Interface', 'SaveOnExit',   SaveOnExit);
  WB('Interface', 'LoadDesktop',  bLoadDesktop);
  WB('Interface', 'BkSpUpDir',    BkSpUpDir);
  WB('Interface', 'RestoreVideo', RestoreVideo);
  WB('Interface', 'Del_F8',       Del_F8);
  WB('Interface', 'InternalView', InternalView);

  WW('Sorting', 'SortLeft',  lp.SortType);
  WW('Sorting', 'SortRight', rp.SortType);

  WriteProfile(ini, 'Masks', 'PlusMask',  PlusMask);
  WriteProfile(ini, 'Masks', 'MinusMask', MinusMask);
  WriteProfile(ini, 'Masks', 'Group1',    group1);
  WriteProfile(ini, 'Masks', 'Group2',    group2);
  WriteProfile(ini, 'Masks', 'Group3',    group3);
  WriteProfile(ini, 'Masks', 'Group4',    group4);
  WriteProfile(ini, 'Masks', 'Group5',    group5);
  WriteProfile(ini, 'Masks', 'Exe',       gExe);
  WriteProfile(ini, 'Masks', 'Arc',       gArc);

  WB('ZX', 'TRDOS3',          TRDOS3);
  WB('ZX', 'AutoMove',        AutoMove);
  WB('ZX', 'hob2scl',         hob2scl);
  WB('ZX', 'MakeBoot',        MakeBoot);
  WB('ZX', 'CheckMedia',      CheckMedia);
  WW('ZX', 'HobetaStartAddr', HobetaStartAddr);
  WW('ZX', 'noHobNaming',     noHobNaming);

  if bLoadDesktop then begin
    WriteProfile(ini, 'Desktop', 'LeftPath',  lp.pcnd);
    WriteProfile(ini, 'Desktop', 'RightPath', rp.pcnd);
    if focus = Left then
      WriteProfile(ini, 'Desktop', 'FocusedPanel', 'Left')
    else
      WriteProfile(ini, 'Desktop', 'FocusedPanel', 'Right');
  end;
 end;

Procedure snInit(sys:boolean);
label contsys;
Begin
if sys then goto contsys;
CurOff; Flash(off);
SavedAttr:=0;
GetMemPCDirs;

ContSys:

WorkDir:=CurentDir; StartDir:=GetOf(ParamStr(0),_dir);
if StartDir='' then StartDir:=CurentDir;

Moused:=false;

focus:=left; Lang:=eng;

Esc_ShowUserScr:=true;
lp.pcnd:=curentdir;
rp.pcnd:=curentdir;

//GetPalFile;
LoadDefaultKBD;

menu_bkNT:=pal.bkMenuNT;          menu_txtNT:=pal.txtMenuNT;
menu_bkST:=pal.bkMenuST;          menu_txtST:=pal.txtMenuST;

menu_bkMarkNT:=pal.bkMenuMarkNT;  menu_txtMarkNT:=pal.txtMenuMarkNT;
menu_bkMarkST:=pal.bkMenuMarkST;  menu_txtMarkST:=pal.txtMenuMarkST;

clocked:=true;
lp.nameline:=true; rp.nameline:=true;
DiskLine:=true;
lp.infolines:=3; rp.infolines:=3;
HideCmdLine:=true;
focus:=right;
DiskMenuType:=1;
HideHidden:=false;
Refresh:=false;
Del_F8:=true;
LANG:=eng;
InternalView:=true;
pr1:=';trd;fdi;fdd;scl;tap;';
pr2:=gExe;
pr3:=gArc;

TRDOS3:=false;
TRDOS3en:=true;{}

AutoMove:=false;
hob2scl:=false;

HobetaStartAddr:=32768;

noHobNaming:=1;
CheckMedia:=true;
LoadUp80:=true;
Cat9:=true;

if lp.pcnd[length(lp.pcnd)]<>PathDelim then lp.pcnd:=lp.pcnd+PathDelim;
if rp.pcnd[length(rp.pcnd)]<>PathDelim then rp.pcnd:=rp.pcnd+PathDelim;

LoadConfig;
LoadKBD;

if Clocked then begin
  OnIdle := @DrawClock;
  DrawClock;
end;
cStatusBar(pal.bkSBarNT,pal.txtSBarNT,pal.bkSBarST,pal.txtSBarST,0,sBar[lang,PanelTypeOf(focus)]);

if HideCmdLine then CmdLine:=false else CmdLine:=true;

flash(off);

End;

End.