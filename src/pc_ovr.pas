{$mode objfpc}{$H+}
Unit PC_Ovr;
Interface
Uses sn_Obj;

function  hob2pc(name:string):string;
function  CheckEx(dir,name:string):string;

Function  hobLoad(name:string):boolean;
Function  hobSave(path:string; AltF5flag:boolean):boolean;

Procedure pcRename;
procedure hobRename;

procedure MakeImages(var p:TPanel);

Procedure pc2pc(flag: word);

procedure pcDeleteEntry(const path: string);

Implementation
Uses RV, Vars, Main, Main_Ovr, Palette,
     PC, TRD, FDI, FDI_Ovr, FDD, FDD_Ovr,
     TRD_Ovr, SCL_Ovr, TAP_Ovr,
     SysUtils, Video, Keyboard;


{============================================================================}
function hob2pc(name:string):string;
var i:byte; s,d:string;
begin
s:=nospaceLR(Copy(name,1,8));
d:=LowerCase(s);
if (d='com1')or(d='com2')or(d='com3')or(d='com4')or(d='com5')or(d='com6')or
   (d='lpt1')or(d='lpt2')or(d='lpt3')or(d='lpt4')or(d='lpt5')or(d='lpt6')or
   (d='nul')or(d='con')or(d='aux')or(d='prn') then s:=s+d;

for i:=1 to length(s) do
 begin
  if s[i]=' ' then s[i]:='_';
  if s[i] in ['.',':',',','\','/','?','*','>','<','+','"',#39] then s[i]:='-';
  if s[i]=#0 then s[i]:='0';
  if s[i]=#1 then s[i]:='1';
  if s[i]=#2 then s[i]:='2';
  if s[i]=#3 then s[i]:='3';
  if s[i]=#4 then s[i]:='4';
  if s[i]=#5 then s[i]:='5';
  if s[i]=#6 then s[i]:='6';
  if s[i]=#7 then s[i]:='7';
  if s[i]=#8 then s[i]:='8';
  if s[i]=#9 then s[i]:='9';
  if s[i]=#10 then s[i]:='A';
  if s[i]=#11 then s[i]:='B';
  if s[i]=#12 then s[i]:='C';
  if s[i]=#13 then s[i]:='D';
  if s[i]=#14 then s[i]:='E';
  if s[i]=#15 then s[i]:='F';
  if s[i]=#16 then s[i]:='G';
  if s[i]=#17 then s[i]:='H';
  if s[i]=#18 then s[i]:='I';
  if s[i]=#19 then s[i]:='J';
  if s[i]=#20 then s[i]:='K';
  if s[i]=#21 then s[i]:='L';
  if s[i]=#22 then s[i]:='M';
  if s[i]=#23 then s[i]:='N';
  if s[i]=#24 then s[i]:='O';
  if s[i]=#25 then s[i]:='P';
  if s[i]=#26 then s[i]:='Q';
  if s[i]=#27 then s[i]:='R';
  if s[i]=#28 then s[i]:='S';
  if s[i]=#29 then s[i]:='T';
  if s[i]=#30 then s[i]:='U';
  if s[i]=#31 then s[i]:='V';
end;
hob2pc:=s;
End;




{============================================================================}
function CheckEx(dir,name:string):string;
var i:longint; s:string[3]; t:string[8]; e:byte;
Begin
i:=0;
checkex:=name;
e:=checkdirfile(dir+name);
if e<>0 then exit;
while e=0 do
 Begin
  t:=getof(name,_name);
  t:=t+space(8-length(t));
  s:=strr(i);
  if (i>=0)and(i<10) then s:='00'+s;
  if (i>=10)and(i<100) then s:='0'+s;
  t[6]:=s[1];
  t[7]:=s[2];
  t[8]:=s[3];
  checkex:=nospace(t)+getof(name,_ext);
  inc(i);
  e:=checkdirfile(dir+nospace(t)+getof(name,_ext));
 End;
End;




{============================================================================}
Function  hobLoad(name:string):boolean;
Var
   f:file; i1,i2:byte;
   Begin
hobLoad:=false;
if ItHobeta(name,HobetaInfo) then
 begin
  {$I-}
  GetMem(HobetaInfo.body,256*HobetaInfo.totalsec);
  Assign(f,name); filemode := fmReadShared; reset(f,1); seek(f,17);
  i1:=IOResult;
  BlockRead(f,HobetaInfo.body^,256*HobetaInfo.totalsec);
  if IOResult=0 then;
  Close(f);
  i2:=IOResult;
  {$I+}
  if (i1=0)and(i2=0) then hobLoad:=true;
 end;
End;



{============================================================================}
Function  hobSave(path:string; AltF5flag:boolean):boolean;
Var
   f:file;
   buf:array[1..17] of byte;
   tc,m:word;
   stemp:string;
   tbytes:word;
Begin
hobSave:=false;

for tc:=1 to 8 do buf[tc]:=ord(HobetaInfo.name[tc]);
buf[9]:=ord(HobetaInfo.typ);
m:=HobetaInfo.start; buf[10]:=lo(m); buf[11]:=hi(m);
m:=HobetaInfo.length; buf[12]:=lo(m); buf[13]:=hi(m);
buf[14]:=0; buf[15]:=HobetaInfo.totalsec;
m:=0; for tc:=1 to 15 do m:=m+257*buf[tc]+(tc-1);
buf[16]:=lo(m); buf[17]:=hi(m);

stemp:=LowerCase(hob2pc(HobetaInfo.name));
if nospace(stemp)='' then stemp:='________';
if TRDOS3 and altF5flag then
 begin
  stemp:=stemp+'.'+HobetaInfo.typ+chr(lo(HobetaInfo.start))+chr(hi(HobetaInfo.start));
 end
else
 begin
  stemp:=stemp+'.$';
  if HobetaInfo.typ=' ' then stemp:=stemp+'_' else stemp:=stemp+hob2pc(HobetaInfo.typ);
  if altF5flag then stemp:=stemp+'!';
 end;

 stemp:=CheckEx(path,stemp);

{$I-}
Assign(f,path+stemp); filemode := fmReadWriteShared; rewrite(f,1);

tbytes:=256*HobetaInfo.totalsec;
if AltF5flag then if HobetaInfo.typ='B' then tbytes:=HobetaInfo.length+4
                                        else tbytes:=HobetaInfo.length;
if HobetaInfo.totalsec=0 then if HobetaInfo.typ='B' then tbytes:=HobetaInfo.length+4
                                                    else tbytes:=HobetaInfo.length;
if HobetaInfo.length=0 then tbytes:=256*HobetaInfo.totalsec;

if not AltF5flag then BlockWrite(f,buf,17);
BlockWrite(f,HobetaInfo.body^,tbytes);

Close(f);
FreeMem(HobetaInfo.body,256*HobetaInfo.totalsec);
{$I+}
if ioresult=0 then hobSave:=true;
End;





{============================================================================}
Procedure pcRename;
Var
    s,stemp:string; ff:file; CurXPos, CurYPos:byte;
     dx:byte;
{== SCANF ===================================================================}
function SNscanf(scanf_posx, scanf_posy:byte;scanf_str:string):string;
var
     scanf_kod:word;
     scanf_x:byte;
     scanf_str_old:string;
label loop;
begin
scanf_esc:=false;
scanf_str_old:=scanf_str;
scanf_x:=1;
loop:
mprint(scanf_posx,scanf_posy,scanf_str);
gotoxy(scanf_posx+scanf_x-1,scanf_posy);
UpdateScreen(false);
scanf_kod:=rKey;
if (chr(lo(scanf_kod)) in[' '..')','-','0'..'9','@'..'[',']'..#254])and(scanf_x<=length(scanf_str)) then
 begin
  scanf_str[scanf_x]:=chr(lo(scanf_kod));
  inc(scanf_x);
  if scanf_x=DX+1 then inc(scanf_x);
 end;
if chr(lo(scanf_kod))='.' then scanf_x:=DX+2;

if scanf_kod=_Right then begin inc(scanf_x); if scanf_x=DX+1 then inc(scanf_x); end;
if scanf_kod=_Left then begin dec(scanf_x); if scanf_x=DX+1 then dec(scanf_x); end;
if (scanf_kod=_Up) or (scanf_kod=_Down) then scanf_kod:=_Enter;

if scanf_kod=_ESC then begin snscanf:=scanf_str_old; scanf_esc:=true; exit; end;
if (scanf_kod=_Enter)or(scanf_kod=PadEnter) then begin snscanf:=scanf_str; exit; end;

if scanf_x<1 then scanf_x:=1;
if scanf_x>DX+4 then begin scanf_x:=DX+4; end;
goto loop;
end;
{============================================================================}
{============================================================================}

Begin
 CurXPos:=0; CurYPos:=0;
 Case focus of
  left: stemp:=lp.pcDir^[IndexOf(focus)].fname;
  right: stemp:=rp.pcDir^[IndexOf(focus)].fname;
 End;
 if nospace(stemp)='..' then exit;
 CancelSB;
 GetCurXYOf(focus,CurXPos,CurYPos);
 Case ColumnsOf(focus) of
  1,3: DX:=8;
  2:   Begin DX:=15; end;
 End;

 Colour(pal.bkCurNT,pal.txtCurNT);
 Case focus of
  left:  stemp:=sRexpand(lp.pcdir^[IndexOf(focus)].fname,DX)+'.'+sRexpand(lp.pcdir^[IndexOf(focus)].fext,3);
  right: stemp:=sRexpand(rp.pcdir^[IndexOf(focus)].fname,DX)+'.'+sRexpand(rp.pcdir^[IndexOf(focus)].fext,3);
 End;
 s:=TrueNameOf(focus,IndexOf(focus));
 if IndexOf(focus)>tdirsOf(focus) then stemp:=LowerCase(stemp);
 CurOn; stemp:=nospace(snscanf(CurXPos,CurYPos,stemp)); CurOff;
 if not scanf_esc then
  begin
   {$I-}
   assign(ff,pcndOf(focus)+s);
   rename(ff,pcndOf(focus)+stemp);
   {$I+}
   if ioresult<>0 then;
   reMDF;
   if stemp[length(stemp)]='.' then delete(stemp,length(stemp),1);
   Case focus of
    left: lp.pcnn:=stemp;
    right: rp.pcnn:=stemp;
   End;
   reTrueCur;
   reInside;
   reInfo('ni');
   rePDF;
  end;
End;




{============================================================================}
procedure hobRename;
var
   buf:array[1..19]of byte;
    stemp:string;
   tc,xc,yc:byte;
   m:word;
   f:file;
begin
if not itHobeta(pcndOf(focus)+TrueNameOf(focus,IndexOf(focus)),HobetaInfo) then exit;
CancelSB;
colour(pal.bkCurNT,pal.txtCurNT);

stemp:=HobetaInfo.name+'.';
if TRDOS3 then stemp:=stemp+hobetainfo.typ+chr(lo(hobetainfo.start))+chr(hi(hobetainfo.start))
          else stemp:=stemp+'<'+hobetainfo.typ+'>';

{$push}{$hints off}
GetCurXYOf(focus,xc,yc);
{$pop}
curon; stemp:=zxsnscanf(xc,yc,stemp,HobetaInfo.typ); curoff;
if not scanf_esc then
 begin
  for xc:=1 to 8 do buf[xc]:=byte(stemp[xc]);
  if TRDOS3 then
   begin
    buf[9]:=byte(stemp[10]);
    buf[10]:=byte(stemp[11]);
    buf[11]:=byte(stemp[12]);
   end
  else
   begin
    buf[9]:=byte(stemp[11]);
    buf[10]:=lo(hobetainfo.start);
    buf[11]:=hi(hobetainfo.start);
   end;

  m:=HobetaInfo.length; buf[12]:=lo(m); buf[13]:=hi(m);
  buf[14]:=0; buf[15]:=HobetaInfo.totalsec;
  m:=0; for tc:=1 to 15 do m:=m+257*buf[tc]+(tc-1);
  buf[16]:=lo(m); buf[17]:=hi(m);

  {$I-}
  assign(f,pcndOf(focus)+TrueNameOf(focus,IndexOf(focus))); filemode := fmReadWriteShared;
  Reset(f,1);  Seek(f,0); BlockWrite(f,buf,17); Close(f);
  {$I+}
  if IOResult=0 then;
 end;
rePDF;
end;


{============================================================================}
procedure MakeImages(var p:TPanel);
Var i:byte;
Begin
  menu_Name[1]:='~`TRD~` - Standart TR-DOS Image';
  menu_Name[2]:='~`FDI~` - TR-DOS Full Disk Image (UKV)';
  menu_Name[3]:='~`FDD~` - TR-DOS for Scorpion256 by MOA';
  menu_Name[4]:='~`SCL~` - Hobeta98 (AMD Copier)';
  menu_Name[5]:='~`TAP~` - Tape Image';
CancelSB;
menu_Total:=5;
menu_f:=1; menu_title:=''; menu_visible:=5;
w_twosided:=false;
i:=ChooseItem;
w_twosided:=true;
Case i of
 1: trdMakeImage(p,false);
 2: fdiMakeImage(p,false);
 3: fddMakeImage(p,false);
 4: sclMakeImage(false);
 5: tapMakeImage;
End;
reMDF;
p.truecur;
p.inside;
reInfo('cbdnsfi');
rePDF;
End;


{============================================================================}
Procedure pc2pc(flag: word);
const
  CopyBuf = 49152;
var
  was: int64;
  targetPath: string;
  total: int64;
  timerStart: TDateTime;
  vert: array[1..4] of char;
  cvert, fcvert: byte;
  n: word;
  sp: ^TPanel;

procedure CopyMove_pc2pc(
  cmflag: word; sPath, nm, tPath: string;
  priory: byte; skip: boolean;
  totalsize: int64; var UserOut: boolean);
var
  path, stemp: string;

  function GetTimer(secs: longint): string;
  var
    th, tm, ts: longint;
  begin
    th := secs div 3600;
    tm := (secs div 60) mod 60;
    ts := secs mod 60;
    GetTimer := LZ(word(th)) + ':'
      + LZ(word(tm)) + ':' + LZ(word(ts));
  end;

  procedure copyfile(cfrom, cto: string);
  type
    mas = array[1..CopyBuf] of byte;
  var
    buf: ^mas;
    ffr, fto: file;
    numread, numwritten: word;
    k: int64;
    j, i: longint;
    ke: TKeyEvent;
    elapsed: longint;
    fage: longint;
  begin
    numread := 0;
    numwritten := 0;
    if CheckDir(ExtractFileDir(cto)) <> 0 then
      rv.CreateDir(
        IncludeTrailingPathDelimiter(ExtractFileDir(cto)));
    if (CheckDirFile(cto) = 0) and skip then exit;
    if ExpandFileName(cfrom) = ExpandFileName(cto) then begin
      ErrorMessage('Can''t copy file to itself');
      userOut := true;
      exit;
    end;
    if CheckDir(ExtractFileDir(cto)) <> 0 then begin
      ErrorMessage('Error while checking directory');
      userOut := true;
      exit;
    end;
    CMPrint(pal.bkdLabelST, pal.txtdLabelST,
      HalfMaxX - 20, HalfMaxY - 3, 'File');
    CMPrint(pal.bkdLabelST, pal.txtdLabelST,
      HalfMaxX - 20, HalfMaxY, 'Total');
    CMPrint(pal.bkdLabelNT, pal.txtdLabelNT,
      HalfMaxX - 15, HalfMaxY - 3,
      Copy(ExtractFileName(cfrom), 1, 20)
        + Space(20));
    CMPrint(pal.bkdStatic, pal.txtdStatic,
      HalfMaxX - 18, HalfMaxY - 2,
      Fill(37, #177));
    UpdateScreen(false);

    if (cmflag = _F6) and
       (UpCase(cfrom[1]) = UpCase(cto[1])) then begin
      {$I-}
      Assign(ffr, cfrom);
      Assign(fto, cto);
      if FileExists(cto) then begin
        Erase(fto);
        if IOResult <> 0 then ;
      end;
      System.Rename(ffr, cto);
      {$I+}
      if IOResult <> 0 then ;
      k := FileLen(cto);
      if k < 0 then k := 0;
      Inc(was, k);
      if totalsize > 0 then
        i := Round((was / totalsize) * 100)
      else
        i := 100;
      if i > 100 then i := 100;
      j := 100;
      CMPrint(pal.bkdStatic, pal.txtdStatic,
        HalfMaxX - 20, HalfMaxY - 2, vert[fcvert]);
      CMPrint(pal.bkdStatic, pal.txtdStatic,
        HalfMaxX - 18, HalfMaxY - 2,
        Fill(Round(j / 2.7), #$DB));
      stemp := StrR(j) + '%';
      CMPrint(pal.bkdStatic, pal.txtdStatic,
        HalfMaxX + 20, HalfMaxY - 2,
        stemp + Space(4 - Length(stemp)));
      CMPrint(pal.bkdStatic, pal.txtdStatic,
        HalfMaxX - 20, HalfMaxY + 1, vert[cvert]);
      CMPrint(pal.bkdStatic, pal.txtdStatic,
        HalfMaxX - 18, HalfMaxY + 1,
        Fill(Round(i / 2.7), #$DB));
      stemp := StrR(i) + '%';
      CMPrint(pal.bkdStatic, pal.txtdStatic,
        HalfMaxX + 20, HalfMaxY + 1,
        stemp + Space(4 - Length(stemp)));
      Inc(cvert);
      if cvert > 4 then cvert := 1;
      Inc(fcvert);
      if fcvert > 4 then fcvert := 1;
      UpdateScreen(false);
      exit;
    end;

    {$I-}
    fage := FileAge(cfrom);
    Assign(ffr, cfrom);
    filemode := fmReadShared;
    Reset(ffr, 1);
    Assign(fto, cto);
    filemode := fmReadWriteShared;
    Rewrite(fto, 1);
    GetMem(buf, CopyBuf);
    fcvert := 1;
    k := FileLen(cfrom);
    if k < 0 then k := 0;
    if FileSize(ffr) = 0 then begin
      FreeMem(buf, CopyBuf);
      Close(ffr);
      Close(fto);
      if fage <> -1 then
        FileSetDate(cto, fage);
      if IOResult <> 0 then ;
      exit;
    end;
    repeat
      ke := PollKeyEvent;
      if ke <> 0 then begin
        ke := GetKeyEvent;
        if GetKeyEventChar(ke) = #27 then begin
          stemp := 'Stop operation?';
          if CQuestion(stemp, lang) then begin
            userOut := true;
            break;
          end;
        end;
      end;

      BlockRead(ffr, buf^, CopyBuf, numread);
      BlockWrite(fto, buf^, numread, numwritten);
      if IOResult <> 0 then begin
        userOut := true;
        break;
      end;

      Inc(was, numread);
      if totalsize > 0 then
        i := Round((was / totalsize) * 100)
      else
        i := 100;
      if i > 100 then i := 100;
      if k > 0 then
        j := Round((FilePos(ffr) / k) * 100)
      else
        j := 100;
      if j > 100 then j := 100;

      elapsed := Round(
        (Now - timerStart) * SecsPerDay);
      CMPrint(pal.bkdStatic, pal.txtdStatic,
        HalfMaxX + 15, HalfMaxY - 4,
        GetTimer(elapsed));

      if elapsed > 0 then
        cmCentre(pal.bkdStatic, pal.txtdStatic,
          HalfMaxY - 1,
          '   (' + StrR(Round(
            (was / elapsed) / 1024))
          + ' kB/sec)  ');

      CMPrint(pal.bkdStatic, pal.txtdStatic,
        HalfMaxX - 20, HalfMaxY - 2,
        vert[fcvert]);
      CMPrint(pal.bkdStatic, pal.txtdStatic,
        HalfMaxX - 18, HalfMaxY - 2,
        Fill(Round(j / 2.7), #$DB));
      stemp := StrR(j) + '%';
      CMPrint(pal.bkdStatic, pal.txtdStatic,
        HalfMaxX + 20, HalfMaxY - 2,
        stemp + Space(4 - Length(stemp)));
      CMPrint(pal.bkdStatic, pal.txtdStatic,
        HalfMaxX - 20, HalfMaxY + 1,
        vert[cvert]);
      CMPrint(pal.bkdStatic, pal.txtdStatic,
        HalfMaxX - 18, HalfMaxY + 1,
        Fill(Round(i / 2.7), #$DB));
      stemp := StrR(i) + '%';
      CMPrint(pal.bkdStatic, pal.txtdStatic,
        HalfMaxX + 20, HalfMaxY + 1,
        stemp + Space(4 - Length(stemp)));
      cmCentre(pal.bkdStatic, pal.txtdStatic,
        HalfMaxY + 2,
        ChangeChar(ExtNum(StrR(was)), ' ', ',')
        + ' bytes copied');
      Inc(cvert);
      if cvert > 4 then cvert := 1;
      Inc(fcvert);
      if fcvert > 4 then fcvert := 1;
      UpdateScreen(false);
    until numread = 0;
    FreeMem(buf, CopyBuf);
    Close(ffr);
    Close(fto);
    if fage <> -1 then
      FileSetDate(cto, fage);
    {$I+}
    if IOResult <> 0 then ;
    if userOut then begin
      {$I-}
      Assign(fto, cto);
      Erase(fto);
      {$I+}
      if IOResult <> 0 then ;
    end;
    if (cmflag = _F6) and (not userOut) then begin
      {$I-}
      Assign(ffr, cfrom);
      Erase(ffr);
      {$I+}
      if IOResult <> 0 then ;
    end;
    if Refresh then reInfo('sf');
  end;

  procedure CopyFileScan(scanPath: string);
  var
    sr: TSearchRec;
    s: string;
  begin
    if FindFirst(
         IncludeTrailingPathDelimiter(scanPath) + '*',
         faAnyFile, sr) = 0 then begin
      repeat
        {$push}{$warnings off}
        if (sr.Attr and (faDirectory or faVolumeId)) = 0 then begin
        {$pop}
          if userOut then begin
            SysUtils.FindClose(sr);
            exit;
          end;
          s := IncludeTrailingPathDelimiter(scanPath)
            + sr.Name;
          Delete(s, 1, Length(string(sp^.pcnd)));
          copyfile(
            IncludeTrailingPathDelimiter(scanPath)
              + sr.Name,
            IncludeTrailingPathDelimiter(tPath)
              + s);
          if userOut then begin
            SysUtils.FindClose(sr);
            exit;
          end;
        end;
      until FindNext(sr) <> 0;
      SysUtils.FindClose(sr);
    end;
  end;

  procedure CopyDirScan(scanPath: string);
  var
    sr: TSearchRec;
    s: string;
  begin
    if FindFirst(
         IncludeTrailingPathDelimiter(scanPath) + '*',
         faAnyFile, sr) = 0 then begin
      repeat
        if ((sr.Attr and faDirectory) = faDirectory)
           and (sr.Name <> '.') and (sr.Name <> '..')
        then begin
          if userOut then begin
            SysUtils.FindClose(sr);
            exit;
          end;
          CopyDirScan(
            IncludeTrailingPathDelimiter(scanPath)
              + sr.Name);
          if userOut then begin
            SysUtils.FindClose(sr);
            exit;
          end;
          CopyFileScan(
            IncludeTrailingPathDelimiter(scanPath)
              + sr.Name);
          if userOut then begin
            SysUtils.FindClose(sr);
            exit;
          end;
          if cmflag = _F6 then begin
            {$I-}
            RmDir(IncludeTrailingPathDelimiter(
              scanPath) + sr.Name);
            {$I+}
            if IOResult <> 0 then ;
          end;
        end;
      until FindNext(sr) <> 0;
      SysUtils.FindClose(sr);
    end;
    s := scanPath;
    Delete(s, 1, Length(string(sp^.pcnd)));
    rv.CreateDir(
      IncludeTrailingPathDelimiter(tPath) + s);
  end;

begin { CopyMove_pc2pc }
  path := IncludeTrailingPathDelimiter(sPath) + nm;
  if (Length(path) > 0) and (path[Length(path)] = '.')
  then
    Delete(path, Length(path), 1);
  if Pos(path, tPath) <> 0 then begin
    ErrorMessage('Directory '
      + ExtractFileName(nm)
      + '; attempt copy to itself');
    exit;
  end;
  if priory = 0 then begin
    if userOut then exit;
    CopyDirScan(path);
    if userOut then exit;
    CopyFileScan(path);
    if userOut then exit;
    if cmflag = _F6 then begin
      {$I-}
      RmDir(path);
      {$I+}
      if IOResult <> 0 then ;
    end;
  end else begin
    if userOut then exit;
    copyfile(path,
      IncludeTrailingPathDelimiter(tPath) + nm);
    if userOut then exit;
  end;
end; { CopyMove_pc2pc }

var
  i: word;
  userOutCopy: boolean;
BEGIN { pc2pc }
  if focus = Left then sp := @lp
  else sp := @rp;

  n := sp^.Insed;
  targetPath := '';
  if not WillCopyMove(flag, targetPath, willcm_skip) then exit;

  userOutCopy := false;
  Colour(pal.bkdRama, pal.txtdRama);
  scPutWin(pal.bkdRama, pal.txtdRama,
    HalfMaxX - 23, HalfMaxY - 5,
    HalfMaxX + 24, HalfMaxY + 3);
  if flag = _F5 then
    cmCentre(pal.bkdRama, pal.txtdRama,
      HalfMaxY - 5, ' Copy ')
  else
    cmCentre(pal.bkdRama, pal.txtdRama,
      HalfMaxY - 5, ' Move ');

  cmCentre(pal.bkdStatic, pal.txtdStatic,
    HalfMaxY - 1, ' Scanning directories...');
  UpdateScreen(false);
  total := sp^.View(true);
  cmCentre(pal.bkdStatic, pal.txtdStatic,
    HalfMaxY - 1,
    Space(25));
  cmCentre(pal.bkdRama, pal.txtdRama,
    HalfMaxY + 3,
    ' Total '
    + ChangeChar(ExtNum(StrR(total)), ' ', ',')
    + ' bytes ');
  CMPrint(pal.bkdStatic, pal.txtdStatic,
    HalfMaxX - 18, HalfMaxY + 1,
    Fill(37, #177));
  UpdateScreen(false);

  was := 0;
  timerStart := Now;
  vert[1] := '-';
  vert[2] := '\';
  vert[3] := '|';
  vert[4] := '/';
  cvert := 1;

  if n = 0 then begin
    CopyMove_pc2pc(flag, string(sp^.pcnd),
      sp^.TrueName(sp^.Index), targetPath,
      sp^.pcDir^[sp^.Index].priory,
      willcm_skip, total, userOutCopy);
  end;
  if n > 0 then
    for i := 1 to sp^.pctdirs + sp^.pctfiles do
      if sp^.pcDir^[i].mark then begin
        if userOutCopy then break;
        CopyMove_pc2pc(flag, string(sp^.pcnd),
          sp^.TrueName(i), targetPath,
          sp^.pcDir^[i].priory,
          willcm_skip, total, userOutCopy);
        if userOutCopy then break;
        sp^.pcDir^[i].mark := false;
      end;

  RestScr;
  reMDF;
  lp.TrueCur;
  lp.Inside;
  rp.TrueCur;
  rp.Inside;
  reInfo('cbdnsfi');
  rePDF;
END;


{============================================================================}
procedure pcDeleteEntry(const path: string);
var
  sr: TSearchRec;
begin
  if DirectoryExists(path) then begin
    if SysUtils.FindFirst(
      IncludeTrailingPathDelimiter(path) + '*', faAnyFile, sr) = 0 then begin
      repeat
        if (sr.Name <> '.') and (sr.Name <> '..') then
          pcDeleteEntry(
            IncludeTrailingPathDelimiter(path) + sr.Name);
      until SysUtils.FindNext(sr) <> 0;
      SysUtils.FindClose(sr);
    end;
    RemoveDir(path);
  end else
  begin
    FileSetAttr(path, 0);
    if not DeleteFile(path) then
      errormessage('Cannot delete: ' + path);
  end;
end;

End.