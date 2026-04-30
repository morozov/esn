Unit Main_Ovr;
{$mode objfpc}{$H+}

interface

uses vars;

Procedure snDone(sys:boolean);
function  CQuestion(quest: string; lan: byte): boolean;
procedure PutSmallWindow(ts, bs: string);
function  GetWildMask(tit, currentMask: string): string;
procedure About;
procedure ErrorMessage(tekst: string);

var
  willcm_skip: boolean;

Function WillCopyMove(wtype:word; var TargetPath:string; var Skip:boolean):boolean;
procedure GlobalFind;
Procedure AltF10Pressed;
Procedure CtrlLPressed;

implementation

uses rv, palette, UnicodeVideo, SysUtils,
     main, sn_Obj, sn_mem, trd,
     init, Keyboard, pc;

{ Horizontal centre of the dialog, in screen columns. }
function DlgCX: word; begin DlgCX := HalfMaxX; end;
{ Vertical centre of the dialog, in screen rows. }
function DlgCY: word; begin DlgCY := HalfMaxY; end;

{============================================================================}
{== COLOR QESTION ===========================================================}
{============================================================================}
function  CQuestion (quest:string; lan:byte):boolean;
var
  k:word;
  m: byte;
  cx, cy, x1, x2: word;
  sep: integer;
begin
  if lan = 0 then ;  { suppress unused-param hint }
CurOff;
  cx := DlgCX;
  cy := DlgCY;
  x1 := cx - 20;
  x2 := cx + 21;
  Colour(pal.bkdRama, pal.txtdRama);
  sPutWin(x1, cy - 4, x2, cy + 3);
  cmCentre(pal.bkdRama, pal.txtdRama, cy - 4, ' Confirmation ');

  sep := Pos(#255, quest);
  if sep > 0 then begin
  CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,
      cy -2, Copy(quest,1, sep - 1));
  CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,cy-1,Copy(quest,sep+1,255));
 end
else
 CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,cy-2,quest);

m:=1;
  repeat
    if m = 1 then begin
      cButton(pal.bkdButtonA, pal.txtdButtonA,
        pal.bkdButtonShadow, pal.txtdButtonShadow,
        cx - 9, cy + 1, '  Yes   ', true);
      cButton(pal.bkdButtonNA, pal.txtdButtonNA,
        pal.bkdButtonShadow, pal.txtdButtonShadow,
        cx + 3, cy + 1, '   No   ', false);
    end else begin
      cButton(pal.bkdButtonNA, pal.txtdButtonNA,
        pal.bkdButtonShadow, pal.txtdButtonShadow,
        cx - 9, cy + 1, '  Yes   ', false);
      cButton(pal.bkdButtonA, pal.txtdButtonA,
        pal.bkdButtonShadow, pal.txtdButtonShadow,
        cx + 3, cy + 1, '   No   ', true);
    end;
    UpdateScreen(false);
    k := rKey;
    case k of
      _Esc: begin CQuestion := false; RestScr; exit; end;
      _Enter, PadEnter: begin
        CQuestion := (m = 1);
        RestScr;
        exit;
  end;
      _Left,  Pad4: m := 1;
      _Right, Pad6: m := 0;
      _LowY, _UpY:  begin CQuestion := true;  RestScr; exit; end;
      _LowN, _UpN:  begin CQuestion := false; RestScr; exit; end;
  end;
  until false;
end;

{ ===== PutSmallWindow ===== }

procedure PutSmallWindow(ts, bs: string);
var
  cy: word;
begin
  cy := DlgCY;
  Colour(pal.bkdRama, pal.txtdRama);
  scPutWin(pal.bkdRama, pal.txtdRama,
    HalfMaxX - 11, cy - 4, HalfMaxX + 12, cy + 3);
  cmCentre(pal.bkdRama, pal.txtdRama, cy - 4, ts);
  cButton(pal.bkdButtonA, pal.txtdButtonA,
    pal.bkdButtonShadow, pal.txtdButtonShadow,
    HalfMaxX - 4, cy + 1, bs, true);
  UpdateScreen(false);
end;

{ ===== GetWildMask ===== }

function GetWildMask(tit, currentMask: string): string;
var
  newMask: string;
  cy: word;
    begin
  cy := DlgCY;
  Colour(pal.bkdRama, pal.txtdRama);
  scPutWin(pal.bkdRama, pal.txtdRama,
    HalfMaxX - 11, cy - 4, HalfMaxX + 12, cy + 3);
  cmCentre(pal.bkdRama, pal.txtdRama, cy - 4, tit);
  CMPrint(pal.bkdLabelST, pal.txtdLabelST, HalfMaxX - 7, cy - 2, 'Mask');
  CMPrint(pal.bkdInputNT, pal.txtdInputNT, HalfMaxX - 8, cy - 1, Space(18));
  cButton(pal.bkdButtonA, pal.txtdButtonA,
    pal.bkdButtonShadow, pal.txtdButtonShadow,
    HalfMaxX - 4, cy + 1, '    OK    ', true);
  Colour(pal.bkdInputNT, pal.txtdInputNT);
  newMask := scanf(HalfMaxX - 8, cy - 1, currentMask, 18, 18,
    Pos('.', currentMask) + 1);
  RestScr;
  if scanf_esc then
    GetWildMask := currentMask
  else
    GetWildMask := newMask;
    end;

{ ===== About ===== }

procedure About;
var
  cy: word;
                    begin
  CurOff;
  cy := DlgCY;
  Colour(LightGray, White);
  sPutWin(HalfMaxX - 25, cy - 9, HalfMaxX + 26, cy + 9);
  cmCentre(LightGray, White,   cy - 7, 'ZX Spectrum Navigator');
  cmCentre(LightGray, Black,   cy - 5, 'Version ' + Ver + ',');
  cmCentre(LightGray, Black,   cy - 4,
    'Compiled on ' + {$I %COMPILE_DATE%});
  cmCentre(LightGray, Blue,    cy - 2, 'https://github.com/morozov/esn');
  cmCentre(LightGray, Black,   cy + 0,
    'Copyright (c) 1997-2003 RomanRoms Software Co.');
  cmCentre(LightGray, Black,   cy + 1, 'Russia. Nizhny Novgorod.');
  cmCentre(LightGray, Black,   cy + 3,
    'Free Pascal port by Sergei Morozov, 2026');
  cmCentre(LightGray, Black,   cy + 5, 'This product is a freeware');
  cButton(pal.bkdButtonA, pal.txtdButtonA,
    pal.bkdButtonShadow, pal.txtdButtonShadow,
    HalfMaxX - 3, cy + 7, '   OK   ', true);
  UpdateScreen(false);
  rPause;
  RestScr;
                  end;

{ Truncate the inner ~`...~` highlighted segment of s with an ellipsis
  so that the rendered width (after stripping the ~` markers) fits in
  maxCells display cells.  Returns s unchanged when no segment is
  present or when the rendered text already fits. }
function FitInlineHighlight(const s: AnsiString;
                            maxCells: integer): AnsiString;
var
  startPos, restPos: integer;
  prefix, inner, suffix: AnsiString;
  available, leadCells, tailCells: integer;
begin
  FitInlineHighlight := s;
  startPos := Pos('~`', s);
  if startPos = 0 then exit;
  restPos := Pos('~`', Copy(s, startPos + 2, MaxInt));
  if restPos = 0 then exit;
  prefix := Copy(s, 1, startPos - 1);
  inner := Copy(s, startPos + 2, restPos - 1);
  suffix := Copy(s, startPos + 1 + restPos + 2, MaxInt);
  if dispWidth(prefix) + dispWidth(inner) + dispWidth(suffix) <= maxCells
    then exit;
  available := maxCells - dispWidth(prefix) - dispWidth(suffix);
  if available < 3 then available := 3;
  { Reserve a small tail so file extensions remain visible. }
  tailCells := (available - 3) div 4;
  if tailCells < 0 then tailCells := 0;
  leadCells := available - 3 - tailCells;
  inner := PathFit(inner, available, leadCells, tailCells);
  FitInlineHighlight := prefix + '~`' + inner + '~`' + suffix;
end;

{============================================================================}
{$push}{$hints off}{$notes off}
Function  WillCopyMove(wtype:word; var TargetPath:string; var Skip:boolean):boolean;
Var
    a1,a2:string[49]; s,st:string; wtemp:word;
{== SCANF ===================================================================}
function pscanf(scanf_posx, scanf_posy:word;
               scanf_str:string;
               scanf_total, scanf_visible,
               scanf_cur:byte):string;
var
     scanf_x, scanf_from:word;
     scanf_str_old:string;
     x:word;
     kb:word;
     ch:char;
     inRadio:boolean;
begin
x:=halfmaxx-25;
scanf_esc:=false;
scanf_str_old:=scanf_str;
scanf_str:=scanf_str+space(scanf_total-length(scanf_str));
scanf_x:=scanf_cur;
scanf_from:=1;
if scanf_visible>length(scanf_str) then scanf_visible:=length(scanf_str);
if skip then
                  begin
  cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x,halfmaxy+0,'( )'+a1);
  cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x,halfmaxy+1,'(•)'+a2);
 end
else
                    begin
  cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x,halfmaxy+0,'(•)'+a1);
  cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x,halfmaxy+1,'( )'+a2);
                    end;

inRadio:=false;
while true do begin
if not inRadio then begin
  mprint(scanf_posx,scanf_posy,copy(scanf_str,scanf_from,scanf_visible));
  gotoxy(scanf_posx+scanf_x-scanf_from,scanf_posy);
  UpdateScreen(false);
end;
kb:=rKey;
ch:=chr(kb and $FF);

if inRadio then begin
  if kb=_Esc then begin pscanf:=scanf_str_old; scanf_esc:=true; exit; end;
  if (kb=_Enter)or(kb=PadEnter) then begin pscanf:=scanf_str; exit; end;
  if kb=_Tab then
   begin
    cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x,halfmaxy+0,'( )'+a1);
    cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x,halfmaxy+1,'( )'+a2);
    if skip then
                  begin
      cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x+1,halfmaxy+0,' ');
      cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x+1,halfmaxy+1,'•');
     end
    else
                    begin
      cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x+1,halfmaxy+0,'•');
      cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x+1,halfmaxy+1,' ');
                    end;
    curon;
    inRadio:=false;
    continue;
                  end;
  if (kb=_Up)or(kb=Pad8) then
                  begin
    skip:=false;
    cmprint(pal.bkdPoleST,pal.txtdPoleST,x,halfmaxy+0,'(•)'+a1);
    cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x,halfmaxy+1,'( )'+a2);
                  end;
  if (kb=_Down)or(kb=Pad2) then
                  begin
    skip:=true;
    cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x,halfmaxy+0,'( )'+a1);
    cmprint(pal.bkdPoleST,pal.txtdPoleST,x,halfmaxy+1,'(•)'+a2);
                    end;
  continue;
                  end;

if kb=_Esc then begin pscanf:=scanf_str_old; scanf_esc:=true; exit; end;
if (kb=_Enter)or(kb=PadEnter) then begin pscanf:=scanf_str; exit; end;

if (ch>=' ')and(ch<=#255)and(scanf_x<=length(scanf_str)) then
                    begin
  scanf_str:=copy(scanf_str,1,scanf_x-1)+ch+copy(scanf_str,scanf_x,length(scanf_str));
  scanf_str:=copy(scanf_str,1,length(scanf_str)-1);
  inc(scanf_x);
  if scanf_x-scanf_from>scanf_visible then inc(scanf_from);
  if scanf_x>length(scanf_str)+1 then scanf_x:=length(scanf_str)+1;
                    end;

if ch=#8 then
                    begin
  scanf_str:=copy(scanf_str,1,scanf_x-2)+copy(scanf_str,scanf_x,length(scanf_str));
  dec(scanf_x);
  if scanf_x<scanf_from then dec(scanf_from);
  if scanf_x<1 then scanf_x:=1 else scanf_str:=scanf_str+' ';
  if scanf_from<1 then scanf_from:=1;
  if scanf_x<1 then scanf_x:=1;
                  end;

if kb=_Tab then
                    begin
  curoff;
  if skip then
                  begin
    cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x,halfmaxy+0,'( )'+a1);
    cmprint(pal.bkdPoleST,pal.txtdPoleST,x,halfmaxy+1,'(•)'+a2);
   end
  else
                    begin
    cmprint(pal.bkdPoleST,pal.txtdPoleST,x,halfmaxy+0,'(•)'+a1);
    cmprint(pal.bkdPoleNT,pal.txtdPoleNT,x,halfmaxy+1,'( )'+a2);
                    end;
  inRadio:=true;
  continue;
                  end;

if ch=#25 then
                    begin
  scanf_str:=space(scanf_total);
  scanf_from:=1;
  scanf_x:=1;
                  end;

if kb=_Home then begin scanf_from:=1; scanf_x:=1; end;
if kb=_End  then begin scanf_from:=scanf_total-scanf_visible+1; scanf_x:=length(scanf_str); end;
if kb=_Del  then scanf_str:=copy(scanf_str,1,scanf_x-1)+copy(scanf_str,scanf_x+1,length(scanf_str))+' ';
if kb=_Right then
                    begin
  inc(scanf_x);
  if scanf_x-scanf_from>scanf_visible then inc(scanf_from);
                  end;
if kb=_Left then
                  begin
  dec(scanf_x);
  if scanf_x<scanf_from then dec(scanf_from);
                  end;

if scanf_from<1 then scanf_from:=1;
if scanf_x<1 then scanf_x:=1;
if scanf_x>length(scanf_str)+1 then begin scanf_x:=length(scanf_str)+1; dec(scanf_from); end;
if scanf_posx+scanf_x>gmaxx then scanf_x:=gmaxx-scanf_posx;

end; { while }
                    end;
{============================================================================}
{== END SCANF ===============================================================}
{============================================================================}
Var p:TPanel;
Const
  { Cell budget shared by the status line above the input field and the
    input field itself, leaving 1 cell of margin before the right border. }
  kFieldCells = 52;
Begin
  a1:=' Overwrite all existing files                    ';
  a2:=' Skip all existing files                         ';
Skip:=false;
WillCopyMove:=false;

if (PanelTypeOf(focus)=zxzPanel)or(PanelTypeOf(ofocus)=zxzPanel) then exit;
if PanelTypeOf(focus)=pcPanel then
BEGIN
if (PanelTypeOf(ofocus)<>pcPanel)and(InsedOf(focus)=0)and(IndexOf(focus)<=tDirsOf(focus))
then Exit;
if (PanelTypeOf(ofocus)<>pcPanel)and(InsedOf(focus)=1)and(FirstMarkedOf(focus)<=tDirsOf(focus))
then Exit;


if InsedOf(focus)=0 then Begin s:=TrueNameOf(focus,IndexOf(focus)); wtemp:=IndexOf(focus); End;
if (InsedOf(focus)=0)and(Trim(s)='..') then Exit;
if InsedOf(focus)=1 then Begin s:=TrueNameOf(focus,FirstMarkedOf(focus)); wtemp:=FirstMarkedOf(focus); End;
if wtemp<=tDirsOf(focus)
  then
    if wtype=_F5
    then
      s:='Copy directory ~`'+s+'~`'
    else
      s:='Rename or move directory ~`'+s+'~`'
  else
    if wtype=_F5
    then
      s:='Copy file ~`'+s+'~`'
    else
      s:='Rename or move file ~`'+s+'~`';
END
else
BEGIN
Case focus of left:p:=lp; right:p:=rp; end;
if (p.Insed=0)and(p.Index=1) then Exit;
if p.Insed=0 then
 Begin
  s:=p.trdDir^[p.Index].name+'.'+TRDOSe3(p,p.Index);
  if (s[1]=#0)or(s[1]=#1) then exit;
  if p.PanelType=tapPanel then
   begin
    if (p.Index>2)and(p.trdDir^[p.Index-1].tapflag=0)
      then s:=p.trdDir^[p.Index-1].name else s:='less';
    if PanelTypeOf(oFocus)=tapPanel then
     if p.trdDir^[p.Index].tapflag=0
      then s:=p.trdDir^[p.Index].name
      else
       if (p.Index>2)and(p.trdDir^[p.Index-1].tapflag=0)
          then s:='codes of "'+p.trdDir^[p.Index-1].name+'"'
          else s:='codes';
   end;
 End;
if p.Insed=1 then
 Begin
  s:=p.trdDir^[p.FirstMarked].name+'.'+TRDOSe3(p,p.FirstMarked);
  if (s[1]=#0)or(s[1]=#1) then exit;
  if p.PanelType=tapPanel then
   begin
    if (p.FirstMarked>2)and(p.trdDir^[p.FirstMarked-1].tapflag=0)
      then s:=p.trdDir^[p.FirstMarked-1].name else s:='less';
    if PanelTypeOf(oFocus)=tapPanel then
     if p.trdDir^[p.FirstMarked].tapflag=0
      then s:=p.trdDir^[p.FirstMarked].name
      else
       if (p.Index>2)and(p.trdDir^[p.FirstMarked-1].tapflag=0)
          then s:='codes of "'+p.trdDir^[p.FirstMarked-1].name+'"'
          else s:='codes';
                  end;
                End;
if wtype=_F5
    then
      s:='Copy file ~`'+s+'~`'
    else
      s:='Rename or move file ~`'+s+'~`';
END;

if InsedOf(focus)>1 then
 Begin
  s:=strr(InsedOf(focus));
  if wtype=_F5
  then
    s:='Copy ~`'+s+'~` file'+SPlural(InsedOf(focus))
  else
    s:='Remane or move ~`'+s+'~` file'+SPlural(InsedOf(focus));
       End;

CancelSB;
Colour(pal.bkdRama,pal.txtdRama);
scPutWin(pal.bkdRama,pal.txtdRama,halfmaxx-28,halfmaxy-5,halfmaxx+29,halfmaxy-3+6);
if wtype=_F5
then
  cmCentre(pal.bkdRama,pal.txtdRama,halfmaxy-5,' Copy ')
else
  cmCentre(pal.bkdRama,pal.txtdRama,halfmaxy-5,' Rename/Move ');
StatusLineColor(pal.bkdLabelST,pal.txtdLabelST,pal.bkdLabelNT,pal.txtdLabelNT,
  halfmaxx-24,halfmaxy-3,FitInlineHighlight(s, kFieldCells));
UpdateScreen(false);

Colour(pal.bkdInputNT,pal.txtdInputNT);
CMPrint(pal.bkdInputNT,pal.txtdInputNT,halfmaxx-25,halfmaxy-2,Space(kFieldCells)); curon;
 s:=Trim(pscanf(halfmaxx-25,halfmaxy-2,'',kFieldCells,kFieldCells,1)); curoff; restscr;
 if not scanf_esc then
  begin
   TargetPath:=pcndOf(oFocus);

   if Trim(s)<>'' then TargetPath:=pcndOf(Focus)+(s);
   if (Length(s)>0)and(s[1]=PathDelim) then TargetPath:=s;
   if TargetPath[length(TargetPath)]<>PathDelim then TargetPath:=TargetPath+PathDelim;
   willcm_skip:=Skip;
   WillCopyMove:=true;

  end;

End;
{$pop}

{ ===== ErrorMessage ===== }

procedure ErrorMessage(tekst: string);
var
  cx, cy: word;
  halfW: word;
begin
 CurOff;
  if Length(tekst) > 60 then tekst := Copy(tekst, 1, 60) + '...';
  halfW := Length(tekst) div 2 + 5;
  cx := HalfMaxX;
  cy := HalfMaxY;
  scPutWin(Red, White, cx - halfW, cy - 4, cx + halfW, cy);
  cmCentre(Red, White, cy - 2, tekst);
  UpdateScreen(false);
  rKey;
 RestScr;
end;

procedure GlobalFind;
begin
end;


{============================================================================}
Procedure snDone(sys:boolean);
Begin
if not cQuestion('Exit'#255'Are you sure?',eng) then exit;

if not sys then
 Begin
  if SaveOnExit then SaveConfig;
  FreeMemPCDirs;
  Halt(0);
 End;
End;


Procedure CtrlLPressed;
Begin
Case focus of
 left:
   BEGIN
    if rp.PanelType<>noPanel then if rp.PanelType<>infPanel then
     Begin
      rp.clLastPanelType:=rp.PanelType;
      rp.PanelType:=infPanel;
      rp.Build('0');
      rp.Info('ci');
      Case lp.PanelType of
       pcPanel:
   BEGIN
          pcInfoPanel(left);
   END;
End;
     End
    else
     Begin
      rp.PanelType:=rp.clLastPanelType;
      if (rp.Paneltype>=1)and(rp.Paneltype<=10) then rp.Build('012');
reInfo('cbdnsfi');
rePDF;
      snKernelExitCode:=21;
End;
   END;
 right:
   BEGIN
    if lp.PanelType<>noPanel then if lp.PanelType<>infPanel then
     Begin
      lp.clLastPanelType:=lp.PanelType;
      lp.PanelType:=infPanel;
      lp.Build('0');
      lp.Info('ci');

      Case rp.PanelType of
       pcPanel:
         BEGIN
          pcInfoPanel(right);
         END;
      End;
     End
    else
     Begin
      lp.PanelType:=lp.clLastPanelType;
      if (lp.Paneltype>=1)and(lp.Paneltype<=10) then lp.Build('012');
      reInfo('cbdnsfi');
      rePDF;
      snKernelExitCode:=21;
     End;
   END;
End;
End;

Procedure AltF10Pressed;
begin
curoff; flash(off);
GlobalRedraw;
end;


initialization
sBar[eng,noPanel]:='~`Alt+X~` Exit';
sBar[eng,infPanel]:='~`Alt+X~` Exit';
End.
