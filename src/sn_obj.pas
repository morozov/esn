Unit sn_Obj;
{$mode tp}
Interface

Type
    zxDirRec=
         record
          name:string[10];
          typ:char;
          start:word;
          length:word;
          totalsec:byte;
          n1sec:byte;
          n1tr:byte;
          mark:boolean;

          param1:word;
          param2:word;
          tapflag:byte;
          taptyp:byte;
          offset:longint;

          zxzPackSize:word;
          zxzCRC32:longint;
          zxzPackMethod:byte;
          zxzFlag:byte;

          description:string[1];

         end;
    zxDirP=array[1..1] of zxDirRec;
    zxDiskRec=
         record
          n1FreeSec:byte;
          nTr1FreeSec:byte;
          DiskTyp:byte;
          files:word;
          free:word;
          trdosCode:byte;
          delfiles:word;
          diskLabel:string[20];
          tracks:byte;
         end;
    zxInsedRec=
         record
          crc16:word;
         end;
    zxInsedP=array[1..1] of zxInsedRec;

    TFileDateRec=
      record
       year,month,day,hour,min,sec:word;
      end;

     pcDirRec=
      record
       fname:string;
       fext:string;
       flength:int64;
       mark:boolean;
       fdt:TFileDateRec;
       fattr:word;
       priory:byte;
       fullname:string;
      end;
     pcDirP=array[1..1]of pcDirRec;

     pcInsedRec=
      record
       crc16:word;
      end;
     pcInsedP=array[1..1] of pcInsedRec;

Type
   tfdi=
    record
     kLabel:string[3];
     Flag:byte;
     cyl:word;
     heads:word;
     offText:word;
     offData:word;
     extDataLenHeader:word;
     extDataLen:word;
     offHeaderCyl:word;
    end;

Type
     PPanel=^TPanel;
     TPanel=
      object
       Place                    :byte;
       PanelLong, PanelHi, PanelW:word;
       Columns                  :byte;
       InfoLines                :byte;
       PutFrom, PosX, PosY      :word;
       NameLine                 :boolean;
       Visible                  :boolean;
       Focused                  :boolean;

       PanelType                :byte;
       clLastPanelType,
       ckLastPanelType,
       LastPanelType            :byte;

       xc,yc,lc                 :word;
       tdirs,tfiles             :integer;
       from,f                   :integer;

       pcDir                    :^pcdirp;
       pcIns                    :^pcinsedp;
       pcnd,oldpcnd             :string;
       pcnn                     :string;
       devId                    :Int64;
       TreeC                    :byte;
       SortType                 :byte;

       pctdirs,pctfiles         :integer;
       oldpctdirs,oldpctfiles   :integer;

       flptfiles,
       trdtfiles,taptfiles,fditfiles,
       fddtfiles,zxztfiles,scltfiles
                                :word;

       flpnn,
       trdnn,fdinn,fddnn,
       tapnn,sclnn,zxznn        :string;

       pcf,pcfrom,
       trdfrom,trdf,fdifrom,fdif,
       tapfrom,tapf, fddfrom,fddf,
       flpfrom,flpf, isfrom,isf,
       zxzfrom,zxzf, sclfrom,sclf,
       bbsfrom,bbsf             :integer;

       zxDisk                   :zxDiskRec;
       trdDir                   :^zxDirP;
       trdIns                   :^zxInsedP;

       flpDrive                 :char;
       trdFile,tapFile,fdiFile,
       fddFile,zxzFile,sclFile  :string;

       fdiRec:tfdi;

       Procedure flpMDFs(flpDriveName:char);
       Procedure flpPDFs(fr:integer);

       Procedure zxzMDFs(zxzFileName:string);
       Procedure zxzPDFs(fr:integer);

       Procedure fddMDFs(fddFileName:string);
       Procedure fddPDFs(fr:integer);

       Procedure tapMDFs(tapFileName:string);
       Procedure tapPDFs(fr:integer);

       Procedure sclMDFs(sclFileName:string);
       Procedure sclPDFs(fr:integer);

       Procedure trdMDFs(trdFileName:string);
       Procedure trdPDFs(fr:integer);

       Procedure fdiMDFs(fdiFileName:string);
       Procedure fdiPDFs(fr:integer);

       Procedure PanelSetup;
       Procedure Build(parts:string);

       procedure pcAdd(r:pcdirrec; isitdir:boolean; ind:integer);
       procedure pcMDF(path:string);
       procedure GetCurXY(var x,y:word);
       procedure pcPDF(fr:integer);

       procedure MDF;
       procedure PDF;

       Procedure Info(parts:string);

       Function  GetTreeC(path:string):byte;
       Function  Insed:word;

       Procedure Inside;
       Procedure Outside;
       Function  Index:word;
       Function  TrueName(ind:word):string;
       Procedure TrueCur;

       Procedure Enter;
       Procedure CtrlPgUp;
       Procedure CtrlPgDn;

       Procedure AltF1F2(ps:byte);
       Procedure CtrlLeftRightDoIt(stemp:char);

       Procedure Insert;
       Procedure Star(Ctrled:boolean);
       Procedure Plus(Ctrled:boolean);
       Procedure Minus(Ctrled:boolean);

       Function  FirstMarked:word;
       Procedure Del;

       Procedure fCopy;
       Procedure fMove;
       Procedure Rename;
       Function  View(sys:boolean):int64;{}
       Procedure Edit;{}
       Procedure MkDir;
       Procedure LocalFind;
       Procedure Navigate;
      end;

Var
     rp,lp:TPanel;

function BuildHorizSep(panelW, columns: integer): AnsiString;
procedure ClampPanel(var f, from: longint;
                     panelHi, cols, total: longint);

Implementation
Uses
     rv, vars, palette, Main_Ovr,
     main, sorting, sn_kbd, snviewer,
     trd, trd_ovr, scl_ovr, scl, tap_ovr, tap,
     fdi, fdi_ovr, fdd, fdd_ovr, zxzip, pc, pc_ovr,
     UnicodeVideo, SysUtils, StrUtils
     {$IFDEF WINDOWS}
     , Windows
     {$ENDIF}
     ;


{============================================================================}
{$push}{$hints off}
Procedure TPanel.flpMDFs(flpDriveName:char); Begin End;
{$pop}



{============================================================================}
{$push}{$hints off}
Procedure TPanel.flpPDFs(fr:integer); Begin End;
{$pop}



{============================================================================}
Procedure TPanel.zxzMDFs(zxzFileName:string);
{$push}{$hints off}
Begin
 if Place=left  then zxzMDF(lp,zxzfile);
 if Place=right then zxzMDF(rp,zxzfile);
End;
{$pop}



{============================================================================}
Procedure TPanel.zxzPDFs(fr:integer);
Begin
 if Place=left  then zxzPDF(lp,fr);
 if Place=right then zxzPDF(rp,fr);
End;



{============================================================================}
Procedure TPanel.fddMDFs(fddFileName:string);
{$push}{$hints off}
Begin
 if Place=left  then fddMDF(lp,fddfile);
 if Place=right then fddMDF(rp,fddfile);
End;
{$pop}



{============================================================================}
Procedure TPanel.fddPDFs(fr:integer);
Begin
 if Place=left  then fddPDF(lp,fr);
 if Place=right then fddPDF(rp,fr);
End;



{============================================================================}
Procedure TPanel.tapMDFs(tapFileName:string);
{$push}{$hints off}
Begin
 if Place=left  then tapMDF(lp,tapfile);
 if Place=right then tapMDF(rp,tapfile);
End;
{$pop}



{============================================================================}
Procedure TPanel.tapPDFs(fr:integer);
Begin
 if Place=left  then tapPDF(lp,fr);
 if Place=right then tapPDF(rp,fr);
End;



{============================================================================}
Procedure TPanel.sclMDFs(sclFileName:string);
{$push}{$hints off}
Begin
 if Place=left  then sclMDF(lp,lp.sclfile);
 if Place=right then sclMDF(rp,rp.sclfile);
End;
{$pop}



{============================================================================}
Procedure TPanel.sclPDFs(fr:integer);
Begin
 if Place=left  then sclPDF(lp,fr);
 if Place=right then sclPDF(rp,fr);
End;



{============================================================================}
Procedure TPanel.trdMDFs(trdFileName:string);
{$push}{$hints off}
Begin
 if Place=left  then trdMDF(lp,trdfile);
 if Place=right then trdMDF(rp,trdfile);
End;
{$pop}



{============================================================================}
Procedure TPanel.trdPDFs(fr:integer);
Begin
 if Place=left  then trdPDF(lp,fr);
 if Place=right then trdPDF(rp,fr);
End;



{============================================================================}
Procedure TPanel.fdiMDFs(fdiFileName:string);
{$push}{$hints off}
Begin
 if Place=left  then fdiMDF(lp,fdifile);
 if Place=right then fdiMDF(rp,fdifile);
End;
{$pop}



{============================================================================}
Procedure TPanel.fdiPDFs(fr:integer);
Begin
 if Place=left  then fdiPDF(lp,fr);
 if Place=right then fdiPDF(rp,fr);
End;



{============================================================================}
Procedure TPanel.PanelSetup;
Begin
PanelLong:=gmaxy-1;
if CmdLine then dec(PanelLong);

PanelHi:=gmaxy-4-InfoLines;
if NameLine then Begin dec(PanelHi); PutFrom:=3; End else PutFrom:=2;
if CmdLine then dec(PanelHi);
if Place=Right then begin PosX:=GmaxX div 2+1; PanelW:=GmaxX-GmaxX div 2-2; end
               else PanelW:=GmaxX div 2-2;
End;


function Fill(n: integer; const ch: AnsiString): AnsiString;
begin
  Fill := DupeString(ch, n);
end;

function BuildHorizSep(panelW, columns: integer): AnsiString;
var
  cw, dh: integer;
begin
  cw := (panelW + 1) div 3;
  dh := panelW div 2;
  case columns of
    1: BuildHorizSep :=
         '║' + Fill(cw - 1, '─') + '┴' +
         Fill(panelW - cw, '─') + '║';
    2: BuildHorizSep :=
         '║' + Fill(dh - 1, '─') + '┴' +
         Fill(panelW - dh, '─') + '║';
    3: BuildHorizSep :=
         '║' + Fill(cw - 1, '─') + '┴' +
         Fill(cw - 1, '─') + '┴' +
         Fill(panelW - 2 * cw, '─') + '║';
  else
    BuildHorizSep := '║' + Fill(panelW, '─') + '║';
  end;
end;

procedure ClampPanel(var f, from: longint;
                     panelHi, cols, total: longint);
begin
  if f > panelHi * cols then f := panelHi * cols;
  if (total > 0) and (f > total) then f := total;
  if f < 1 then f := 1;
  if from + f - 1 > total then begin
    from := total - f + 1;
    if from < 1 then from := 1;
  end;
end;





{============================================================================}
Procedure TPanel.Build(parts:string);
Var
    s:AnsiString;
    i,cw:integer;
Begin
PanelSetup;{}
if Columns<1 then Columns:=1;
if Columns>3 then Columns:=3;

if pos('0',parts)<>0 then if PanelType<>noPanel then
 begin
  s:='╔'+Fill(PanelW,'═')+'╗';
  if (posx<>1)and clocked then
    s:='╔'+Fill(PanelW-9,'═');
  cmprint(pal.BkRama,pal.TxtRama,posx,1, s);
  s:='║'+Space(PanelW)+'║';
  for i:=1 to PanelLong-2 do
    cmprint(pal.BkRama,pal.TxtRama,posx,1+i,s);
  s:='╚'+Fill(PanelW,'═')+'╝';
  cmprint(pal.BkRama,pal.TxtRama,posx,PanelLong,s);
 end;

if pos('1',parts)<>0 then if (PanelType>=1)and(PanelType<=10) then
 begin
  cw:=(PanelW+1) div 3;
  for i:=1 to PanelLong-InfoLines-3 do
   begin
          cmprint(pal.BkRama,pal.TxtRama,
            posx+cw,1+i,'│');
          cmprint(pal.BkRama,pal.TxtRama,
            posx+2*cw,1+i,'│');
   end;

  s:=BuildHorizSep(PanelW, Columns);
  cmprint(pal.BkRama,pal.TxtRama,posx,PanelLong-InfoLines-1,s);
 end;

if pos('2',parts)<>0 then if (PanelType>=1)and(PanelType<=10) then
 begin
  if NameLine then
   begin
    cw:=(PanelW+1) div 3;
    s:='    Name    ';
         cmprint(pal.BkNameLine,pal.TxtNameLine,posx+1,2,s);
         cmprint(pal.BkNameLine,pal.TxtNameLine,posx+1+cw,2,s);
         cmprint(pal.BkNameLine,pal.TxtNameLine,posx+1+2*cw,2,s);
   end;
 end;

if pos('0',parts)<>0 then DrawClock;
UpdateScreen(false);
End;


{============================================================================}
procedure TPanel.pcAdd(r:pcdirrec; isitdir:boolean; ind:integer);
begin
pcdir^[ind].fname  :=r.fname;
pcdir^[ind].fext   :=r.fext;
pcdir^[ind].fdt    :=r.fdt;
pcdir^[ind].fattr  :=r.fattr;
pcdir^[ind].fullname:=r.fullname;
pcdir^[ind].mark   :=false;
if isitdir then
 begin
  pcdir^[ind].flength:=-1; pcdir^[ind].priory:=0;
 end
else
 begin
  pcdir^[ind].flength:=r.flength;  pcdir^[ind].priory:=10;
  r.fext:=nospace(LowerCase(r.fext)); if r.fext='' then r.fext:='.';
  if pos(';'+r.fext+';',pr1)<>0 then pcdir^[ind].priory:=1;
  if pos(';'+r.fext+';',pr2)<>0 then pcdir^[ind].priory:=2;
  if pos(';'+r.fext+';',pr3)<>0 then pcdir^[ind].priory:=3;
  if pos(';'+r.fext+';',pr4)<>0 then pcdir^[ind].priory:=4;
  if pos(';'+r.fext+';',pr5)<>0 then pcdir^[ind].priory:=5;
  if pos(';'+r.fext+';',pr6)<>0 then pcdir^[ind].priory:=6;
  if pos(';'+r.fext+';',pr7)<>0 then pcdir^[ind].priory:=7;
  if pos(';'+r.fext+';',pr8)<>0 then pcdir^[ind].priory:=8;
  if pos(';'+r.fext+';',pr9)<>0 then pcdir^[ind].priory:=9;
 end;
end;



{============================================================================}
procedure TPanel.pcMDF(path: string);
var
  sr: TSearchRec;
  fnew: pcDirRec;
  i, j, pcinsed: integer;
  dt: TDateTime;
  y, mo, d, h, mi, s, ms2: word;
  savedMarks: array[1..MaxFiles] of word;  { CRC16 of fname+'.'+fext }
  nd: string;
begin
  {$push}{$hints off}{$notes off}
  FillChar(fnew, SizeOf(fnew), 0);
  {$pop}
  nd := pcnd;
  j := 0;
  for i := 1 to pctdirs + pctfiles do begin
    if pcDir^[i].mark then begin
      Inc(j);
      savedMarks[j] := CRC16(string(pcDir^[i].fullname));
    end;
  end;
  pcinsed := j;

  path := CheckPath(path);
  if (Length(path) > 1) and (path[Length(path)] = PathDelim) and
     (path[Length(path) - 1] <> ':') then
    Delete(path, Length(path), 1);
  if not SetCurrentDir(path) then begin
    path := GetCurrentDir;
  end;
  pcnd := GetCurrentDir;
  if (Length(pcnd) > 0) and (pcnd[Length(pcnd)] <> PathDelim) then
    pcnd := pcnd + PathDelim;
  devId := GetDevId(pcnd);
GetTreeC(pcnd);

  oldpctdirs  := pctdirs;
  oldpctfiles := pctfiles;
  pctdirs     := 0;
  pctfiles    := 0;  if TreeC > 1 then begin
    {$push}{$notes off}
    FillChar(fnew, SizeOf(fnew), 0);
    {$pop}
    fnew.fname    := ' ..';
    fnew.fext     := '';
    fnew.fullname := '..';
    fnew.flength  := -1;
    Inc(pctdirs);
    pcAdd(fnew, true, 1);
  end;  {$push}{$warnings off}{$hints off}{$notes off}
  FillChar(fnew, SizeOf(fnew), 0);
  if SysUtils.FindFirst(
       IncludeTrailingPathDelimiter(pcnd) + '*',
       faAnyFile, sr) = 0 then begin
    repeat
      if sr.Name = '.' then begin
        if SysUtils.FindNext(sr) <> 0 then break;
        continue;
      end;
      if sr.Name = '..' then begin        if TreeC > 1 then begin
          dt := FileDateToDateTime(sr.Time);
          DecodeDate(dt, y, mo, d);
          DecodeTime(dt, h, mi, s, ms2);
          pcDir^[1].fdt.year  := y;
          pcDir^[1].fdt.month := mo;
          pcDir^[1].fdt.day   := d;
          pcDir^[1].fdt.hour  := h;
          pcDir^[1].fdt.min   := mi;
          pcDir^[1].fdt.sec   := s;
        end;
        if SysUtils.FindNext(sr) <> 0 then break;
        continue;
      end;
  {$push}{$hints off}{$notes off}
  FillChar(fnew, SizeOf(fnew), 0);
  {$pop}
      dt := FileDateToDateTime(sr.Time);
      DecodeDate(dt, y, mo, d);
      DecodeTime(dt, h, mi, s, ms2);
      fnew.fdt.year  := y;
      fnew.fdt.month := mo;
      fnew.fdt.day   := d;
      fnew.fdt.hour  := h;
      fnew.fdt.min   := mi;
      fnew.fdt.sec   := s;
      if sr.Name = '..' then begin
        fnew.fname    := ' ..';
        fnew.fext     := '';
        fnew.fullname := '..';
      end else begin
        fnew.fname    := ChangeFileExt(sr.Name, '');
        fnew.fext     := Copy(ExtractFileExt(sr.Name), 2, MaxInt);
        fnew.fullname := sr.Name;
      end;
      fnew.flength  := sr.Size;
      fnew.fattr    := sr.Attr;
      fnew.mark     := false;
      if (sr.Attr and faDirectory) <> 0 then begin
        if HideHidden and (sr.Name <> '..') then begin
          if (sr.Attr and faHidden) = 0 then begin
            Inc(pctdirs);
            pcAdd(fnew, true, pctdirs + pctfiles);
          end;
        end else begin
          Inc(pctdirs);
          pcAdd(fnew, true, pctdirs + pctfiles);
        end;
      end;
      if (sr.Attr and (faDirectory or faVolumeId)) = 0 then begin
        if HideHidden then begin
          if (sr.Attr and faHidden) = 0 then begin
            Inc(pctfiles);
            pcAdd(fnew, false, pctdirs + pctfiles);
          end;
        end else begin
          Inc(pctfiles);
          pcAdd(fnew, false, pctdirs + pctfiles);
   end;
   end;

      if (sr.Name = '..') and (TreeC = 1) then begin
        Dec(pctdirs);
        if pctdirs < 0 then pctdirs := 0;
   end;

      if pctdirs + pctfiles > MaxFiles - 10 then
    break;

      if SysUtils.FindNext(sr) <> 0 then
    break;
    until false;
    SysUtils.FindClose(sr);
 end;

  for i := pctdirs + pctfiles + 1 to
            pctdirs + pctfiles + PanelHi * Columns do begin
    pcDir^[i].fname := '';
    pcDir^[i].fext  := '';
 end;

globalsort(left);
  GlobalSort(Right);  if pcnd = nd then
    for i := 1 to pcinsed do
      for j := 1 to pctdirs + pctfiles do
        if savedMarks[i] = CRC16(string(pcDir^[j].fullname)) then
          pcDir^[j].mark := true;
End;
{$pop}








{============================================================================}
Procedure TPanel.GetCurXY(var x,y:word);
Var
    px,py,dx:word;
    i,n:integer;
Begin
n:=tdirs+tfiles;
if n>from-1+panelhi*Columns then n:=from-1+panelhi*Columns;
px:=posx+1; py:=putfrom;
Case Columns of 1: dx:=PanelW; 2: dx:=PanelW div 2; 3: dx:=(PanelW+1) div 3; End;
for i:=from to n do
 begin
  if i=integer(Index) then
   begin
    x:=px; y:=py; Exit;
   end;
  inc(py);
  if py>panelhi+putfrom-1 then begin py:=putfrom; inc(px,dx); end;
 end;
x:=PosX+1;
y:=PutFrom;
End;




{============================================================================}
procedure TPanel.pcPDF(fr:integer);
var paper,ink,ii,iii:byte;
    px,py,dx,ddx:word;
    i,n:integer;
    name,e:string;
begin

if paneltype<>pcPanel then exit;{}

n:=pctdirs+pctfiles;
if n>fr-1+panelhi*Columns then n:=fr-1+panelhi*Columns;
px:=posx+1; py:=putfrom;
Case Columns of 1: dx:=13; 2: dx:=PanelW div 2; 3: dx:=(PanelW+1) div 3; End;
for i:=fr to n do
 begin
  ddx:=0;
  name:=PcColumnEntry(string(pcDir^[i].fname),string(pcDir^[i].fext),dx,ddx);
  paper:=pal.bkNT; ink:=pal.txtNT;
  if i<=pctdirs then begin paper:=pal.bkDir; ink:=pal.txtDir; end
  else
   begin
    e:=nospace(string(pcDir^[i].fext)); if e='' then e:='.';
    col(e,pcDir^[i].flength,paper,ink);
   end;
  ii:=ink; iii:=ink;
  if pcdir^[i].mark then begin paper:=pal.bkST; ink:=pal.txtST; end;
  if focused and(i=from+f-1) then begin paper:=pal.bkCurNT; ink:=pal.txtCurNT; end;
  if focused and(i=from+f-1)and(pcdir^[i].mark) then begin paper:=pal.bkCurST; ink:=pal.txtCurST; end;
  e:=' ';
  {$push}{$warnings off}
  if ((pcdir^[i].fattr and faReadOnly)<> 0) then e:='░';
  if ((pcdir^[i].fattr and faHidden)  <> 0) then e:='▒';
  if ((pcdir^[i].fattr and faSysFile) <> 0) then e:='▓';
  {$pop}
  if pcdir^[i].mark then e:='√';
  cmprint(paper,ink,px,py,name);
  if e <> ' ' then
    cmprint(paper, ink, px + dx + integer(ddx) - 5, py, e);

  if Columns=1 then
    PaintRowSeps(PosX, PanelW, dx, py, paper, ink, pal.TxtRama);

  if ii=paper then ii:=ink;
  if focused and(i=from+f-1) then ii:=pal.txtCurNT;
  if focused and(i=from+f-1)and(pcdir^[i].mark) then
    begin ii:=iii; if ii=pal.bkCurST then ii:=pal.txtCurST; end;
  PrintSelf(paper,ii,px+dx+ddx-5,py,1);

  inc(py);
  if py>panelhi+putfrom-1 then begin py:=putfrom; inc(px,dx); end;
 end;

for i:=n+1 to fr-1+panelhi*Columns do
 begin
  ddx:=0;
  name:=space(dx+integer(ddx)-1);
  cmprint(pal.bkNT,pal.txtNT,px,py,name);
  if Columns=1 then
    PaintRowSeps(PosX, PanelW, dx, py, pal.bkNT, pal.txtNT, pal.TxtRama);
  inc(py);
  if py>panelhi+putfrom-1 then begin py:=putfrom; inc(px,dx); end;
 end;

UpdateScreen(false);
end;




{============================================================================}
Procedure TPanel.MDF;
Begin
 case PanelType of
  pcPanel: pcMDF(pcnd);
  trdPanel: trdMDFs(trdfile);
  fdiPanel: fdiMDFs(fdifile);
  sclPanel: sclMDFs(sclfile);
  tapPanel: tapMDFs(tapfile);
  fddPanel: fddMDFs(fddfile);
  zxzPanel: zxzMDFs(zxzfile);
 end;
End;



{============================================================================}
Procedure TPanel.PDF;
Begin
 case PanelType of
  pcPanel: pcPDF(pcfrom);
  trdPanel: trdPDFs(trdfrom);
  fdiPanel: fdiPDFs(fdifrom);
  sclPanel: sclPDFs(sclfrom);
  tapPanel: tapPDFs(tapfrom);
  fddPanel: fddPDFs(fddfrom);
  zxzPanel: zxzPDFs(zxzfrom);
 end;
End;



{$IFDEF WINDOWS}
function WindowsDriveLetters: AnsiString;
var
  mask: DWORD;
  k: integer;
  acc: AnsiString;
begin
  acc := '';
  mask := GetLogicalDrives;
  for k := 0 to 25 do
    if (mask and (DWORD(1) shl k)) <> 0 then
      acc := acc + Chr(Ord('A') + k);
  WindowsDriveLetters := acc;
end;
{$ENDIF}


{============================================================================}
Procedure TPanel.Info(parts:string);
Var
    s, nm, stemp: AnsiString;
    r:AnsiString; p:byte; d:word; x,y:word; m,n:word; i:integer;
    ml,byt2:longint; byt:int64;
    freeBytes:int64;
    spaced:boolean; q:word; activeCh:char;
Begin


                        {== Текущий каталог ==}
if (pos('c',LowerCase(parts))<>0)or(pos('A',parts)<>0) then if (PanelType>=1)and(PanelType<=12) then
 Begin
  Case PanelType of
   pcPanel: if TreeC=1 then s:=' '+pcnd+' ' else s:=' '+copy(pcnd,1,length(pcnd)-1)+' ';
   infPanel: s:=' Information ';
   trdPanel: s:=' '+nospaceLR(zxDisk.DiskLabel)+' ';
   fdiPanel: s:=' '+nospaceLR(zxDisk.DiskLabel)+' ';
   sclPanel: s:=' Hobeta98 ';
   tapPanel: s:=' Tape ';
   fddPanel: s:=' '+nospaceLR(zxDisk.DiskLabel)+' ';
   zxzPanel: s:=' '+nospaceLR(zxDisk.DiskLabel)+' ';
  End;
  { Width available for the title between the left-corner ═══ overlay and
    either the clock (clocked right panel) or the right-corner overlay. }
  if (posx<>left) and clocked then m:=PanelW-12 else m:=PanelW-6;
  if m<8 then m:=8;
  if length(s)>m then
   begin
    d:=m-7;
    s:=copy(s,1,4)+'...'+copy(s,length(s)-d+1,d);
   end;
  if focused then begin p:=pal.bkNDactive; i:=pal.txtNDactive; end else begin p:=pal.bkNDpassive; i:=pal.txtNDpassive; end;
  x:=posx+4+(m-length(s)) div 2;
  if (posx<>left) and clocked then r:=Fill(PanelW-9,'═') else r:=Fill(PanelW,'═');
  cmprint(pal.BkRama,pal.TxtRama,posx+1,posy,r);
  cmprint(p,i,x,1,s);
  CurOff;

  Case PanelType of
   trdPanel: cmprint(pal.BkRama,pal.TxtRama,posx+5,posy,'TRD');
   fdiPanel: cmprint(pal.BkRama,pal.TxtRama,posx+5,posy,'FDI');
   fddPanel: cmprint(pal.BkRama,pal.TxtRama,posx+5,posy,'FDD');
  End;

  if TRDOS3 then cmprint(pal.BkRama,pal.TxtRama,posx+2,1,'T3') else cmprint(pal.BkRama,pal.TxtRama,posx+2,1,'══');
  DrawClock;
  UpdateScreen(false);
 End;


                        {=== Бегунок прокрутки ==}
if (pos('b',LowerCase(parts))<>0)or(pos('A',parts)<>0) then if (PanelType>=1)and(PanelType<=10) then
 Begin
  if (tdirs+tfiles-1)<=0 then m:=1 else m:=tdirs+tfiles-1;
  n:=((from+f-2)*(PanelHi-2))div(m);
  for x:=1 to PanelHi+1 do
   begin
    p:=pal.bkRama; i:=pal.txtRama;
    r:='║';
    if focused then
     begin
      r:='▒';
      if x=1 then         begin p:=pal.bkBP; i:=pal.txtBP; r:='▲'; end;
      if x=PanelHi+1 then begin p:=pal.bkBP; i:=pal.txtBP; r:='▼'; end;
      if x=n+2 then begin p:=pal.bkBP; i:=pal.txtBP; r:='■'; end;
     end;
    cmprint(p,i,posx+PanelW+1,posy+x,r);
   end;
 End;


if (pos('d',LowerCase(parts))<>0)or(pos('A',parts)<>0) then if (PanelType>=1)and(PanelType<=10) then
 Begin
  s := '';
  {$IFDEF WINDOWS}
  if DiskLine then s := WindowsDriveLetters;
  {$ENDIF}
  if s <> '' then
   begin
    cmprint(pal.bkDiskLineR,pal.txtDiskLineR,posx,PanelLong,'╚'+'[ ');
    d := posx + 3;
    spaced := (length(s) * 2 + 5) <= PanelW;
    if length(pcnd) > 0 then activeCh := UpCase(pcnd[1]) else activeCh := #0;
    for x := 1 to length(s) do
     begin
      { Need 1 cell for the letter and 2 for the trailing ' ]'.
        Stop early if drawing this letter would push past the
        panel's right border. }
      if d > posx + PanelW - 2 then break;
      if s[x] = activeCh then
       begin p := pal.bkDiskLineST; i := pal.txtDiskLineST; end
      else
       begin p := pal.bkDiskLineNT; i := pal.txtDiskLineNT; end;
      cmprint(p,i,d,PanelLong,s[x]);
      inc(d);
      if spaced and (x < length(s)) then
       begin
        cmprint(pal.bkDiskLineNT,pal.txtDiskLineNT,d,PanelLong,' ');
        inc(d);
       end;
     end;
    cmprint(pal.bkDiskLineR,pal.txtDiskLineR,d,PanelLong,' ]');
    q := d + 2;
    if q <= posx + PanelW then
      cmprint(pal.bkRama,pal.txtRama,q,PanelLong,
        Fill(posx + PanelW + 1 - q, '═'));
   end
  else
   begin
    cmprint(pal.bkRama,pal.txtRama,posx+1,PanelLong,Fill(PanelW,'═'));
   end;
  cmprint(pal.bkRama,pal.txtRama,posx+PanelW+1,PanelLong,'╝');
 End;


                    {========== CURSOR NAME =========}
if (pos('n',LowerCase(parts))<>0)or(pos('A',parts)<>0) then if (PanelType>=1)and(PanelType<=10) then
 Begin
  Case PanelType of
   pcPanel:
      BEGIN
       m:=pcfrom+pcf-1; nm:=space(PanelW);
       if (m>0)and(pctdirs+pctfiles>0) then
        if place=left then nm:=pcNameLine(lp,m) else nm:=pcNameLine(rp,m);
       m:=0; for n:=1 to pctdirs+pctfiles do if pcdir^[n].mark then inc(m);
       if (infolines<=1)and(m<>0) then else
       cmprint(pal.bkCurLine,pal.txtCurLine,posx+1,PutFrom+PanelHi+1,nm);{}
       cmPrint(pal.bkRama,pal.txtRama,posx,PutFrom+PanelHi+1,'║');
       cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,PutFrom+PanelHi+1,'║');
      END;
   trdPanel:
      BEGIN
       if (infolines<=1)and(Insed<>0) then else
        begin
         nm:='<<'+space(PanelW-2);
         if Index>1 then if place=left then nm:=trdNameLine(lp,Index) else nm:=trdNameLine(rp,Index);
         cmprint(pal.bkCurLine,pal.txtCurLine,posx+1,PutFrom+PanelHi+1,nm);{}
         cmPrint(pal.bkRama,pal.txtRama,posx,PutFrom+PanelHi+1,'║');
         cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,PutFrom+PanelHi+1,'║');
        end;
      END;
   fdiPanel:
      BEGIN
       if (infolines<=1)and(Insed<>0) then else
        begin
         nm:='<<'+space(PanelW-2);
         if Index>1 then if place=left then nm:=fdiNameLine(lp,Index) else nm:=fdiNameLine(rp,Index);
         cmprint(pal.bkCurLine,pal.txtCurLine,posx+1,PutFrom+PanelHi+1,nm);{}
         cmPrint(pal.bkRama,pal.txtRama,posx,PutFrom+PanelHi+1,'║');
         cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,PutFrom+PanelHi+1,'║');
        end;
      END;
   fddPanel:
      BEGIN
       if (infolines<=1)and(Insed<>0) then else
        begin
         nm:='<<'+space(PanelW-2);
         if Index>1 then if place=left then nm:=fddNameLine(lp,Index) else nm:=fddNameLine(rp,Index);
         cmprint(pal.bkCurLine,pal.txtCurLine,posx+1,PutFrom+PanelHi+1,nm);{}
         cmPrint(pal.bkRama,pal.txtRama,posx,PutFrom+PanelHi+1,'║');
         cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,PutFrom+PanelHi+1,'║');
        end;
      END;
   tapPanel:
      BEGIN
       if (infolines<=1)and(Insed<>0) then else
        begin
         nm:='<<';
         if Index>1 then if place=left then nm:=tapNameLine(lp,Index) else nm:=tapNameLine(rp,Index);
         nm:=nm+space(PanelW-length(nm));
         p:=pal.bkcurline; i:=pal.txtcurline; x:=posx+1; y:=putfrom+panelhi+1;
         cmprint(p,i,x,y,nm);{}
        end;
      END;
   sclPanel:
      BEGIN
       if (infolines<=1)and(Insed<>0) then else
        begin
         nm:='<<'+space(PanelW-2);
         if Index>1 then if place=left then nm:=sclNameLine(lp,Index) else nm:=sclNameLine(rp,Index);
         cmprint(pal.bkCurLine,pal.txtCurLine,posx+1,PutFrom+PanelHi+1,nm);{}
         cmPrint(pal.bkRama,pal.txtRama,posx,PutFrom+PanelHi+1,'║');
         cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,PutFrom+PanelHi+1,'║');
        end;
      END;
   zxzPanel:
      BEGIN
       if (infolines<3)and(Insed<>0) then else
        begin
         if place=left then nm:=zxzNameLine(lp,Index) else nm:=zxzNameLine(rp,Index);
         cmprint(pal.bkCurLine,pal.txtCurLine,posx+1,PutFrom+PanelHi+1,nm);{}
         cmPrint(pal.bkRama,pal.txtRama,posx,PutFrom+PanelHi+1,'║');
         cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,PutFrom+PanelHi+1,'║');
        end;

       stemp:=space(PanelW);
       if Index>1 then
        begin
         m:=trdDir^[Index].zxzPackSize;
         byt:=m; byt2:=trdDir^[Index].length; ml:=byt;
        end
       else
        begin
         byt:=0; byt2:=0;
         for n:=2 to zxztfiles do
          begin
           inc(byt,trdDir^[n].zxzPackSize);
           inc(byt2,trdDir^[n].length);
          end;
         ml:=byt;
        end;
       if byt2<>0 then begin
       byt:=byt*100;
       byt:=byt div byt2;
       end else
        byt:=0;

       stemp:='~`Packed:  ~`'+changechar(extnum(strr(ml)),' ',',')+
                               space(17-length(changechar(extnum(strr(ml)),' ',',')))+
                               '~`Ratio:  ~`'+strr(100-byt)+'%';
       i:=PanelW div 2-(length(without(stemp,'~`'))div 2); if i<0 then i:=0;
       nm:=stemp; nm:=nm+space(abs(PanelW-CClen(nm))); if CClen(nm)>PanelW then delete(nm,PanelW+1+8,10);
       {}
       x:=posx+1; if InfoLines<=1 then y:=PutFrom+PanelHi+1 else y:=PutFrom+PanelHi+2;
       if infolines>1 then
        StatusLineColor(pal.bkSelectedNT,pal.txtSelectedNT,pal.bkSelectedST,pal.txtSelectedST,x,y,nm);
       cmPrint(pal.bkRama,pal.txtRama,posx,y,'║'); cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,y,'║');
        end;
      END;
  UpdateScreen(false);
 End;


                       {=========== SELECTED =============}
if (pos('s',LowerCase(parts))<>0)or(pos('A',parts)<>0) then if (PanelType>=1)and(PanelType<=10) then
 Begin
  Case PanelType of
   pcPanel:
     BEGIN
      m:=0; byt:=0;
      for n:=1 to pctdirs+pctfiles do
       if pcdir^[n].mark then
       begin inc(m); if pcdir^[n].flength>=0 then inc(byt,pcdir^[n].flength); end;
      stemp:='No files selected';
      if m>0 then stemp:='~`'+changechar(extnum(strr(byt)),' ',',')+'~` bytes selected in ~`'+strr(m)
                        +'~` file'+ewfiles(m);
      i:=PanelW div 2-(length(without(stemp,'~`'))div 2); if i<0 then i:=0;
      nm:=space(i)+stemp; nm:=nm+space(abs(PanelW-CClen(nm)));
      if CClen(nm)>PanelW then delete(nm,PanelW+1+8,10);
      x:=posx+1; if InfoLines<=1 then y:=PutFrom+PanelHi+1 else y:=PutFrom+PanelHi+2;
      if (m=0)and(infolines=1) then else
      StatusLineColor(pal.bkSelectedNT,pal.txtSelectedNT,pal.bkSelectedST,pal.txtSelectedST,x,y,nm);
        cmPrint(pal.bkRama,pal.txtRama,posx,y,'║'); cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,y,'║');
     END;
  trdPanel:
     BEGIN
      m:=0; byt:=0;
      for i:=2 to trdtfiles do if trddir^[i].mark then
        begin inc(m); inc(byt,trddir^[i].totalsec); end;
      x:=posx+1; y:=putfrom+panelhi+2;
      if infolines<=1 then dec(y);
      stemp:='No files selected';
      if m>0 then stemp:='~`'+changechar(extnum(strr(byt)),' ',',')+
                                          '~` block'+eb(byt)+' selected in ~`'+strr(m)+'~` file'+ewfiles(m);
      i:=PanelW div 2-(length(without(stemp,'~`'))div 2); if i<0 then i:=0;
      nm:=space(i)+stemp; nm:=nm+space(abs(PanelW-CClen(nm))); if CClen(nm)>PanelW then delete(nm,PanelW+1+8,10);
      x:=posx+1; if InfoLines<=1 then y:=PutFrom+PanelHi+1 else y:=PutFrom+PanelHi+2;
      if (m=0)and(infolines=1) then else
      StatusLineColor(pal.bkSelectedNT,pal.txtSelectedNT,pal.bkSelectedST,pal.txtSelectedST,x,y,nm);{}
        cmPrint(pal.bkRama,pal.txtRama,posx,y,'║'); cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,y,'║');
     END;
  fdiPanel:
     BEGIN
      m:=0; byt:=0;
      for i:=2 to fditfiles do if trddir^[i].mark then
        begin inc(m); inc(byt,trddir^[i].totalsec); end;
      x:=posx+1; y:=putfrom+panelhi+2;
      if infolines<=1 then dec(y);
      stemp:='No files selected';
      if m>0 then stemp:='~`'+changechar(extnum(strr(byt)),' ',',')+
                                          '~` block'+eb(byt)+' selected in ~`'+strr(m)+'~` file'+ewfiles(m);
      i:=PanelW div 2-(length(without(stemp,'~`'))div 2); if i<0 then i:=0;
      nm:=space(i)+stemp; nm:=nm+space(abs(PanelW-CClen(nm))); if CClen(nm)>PanelW then delete(nm,PanelW+1+8,10);
      x:=posx+1; if InfoLines<=1 then y:=PutFrom+PanelHi+1 else y:=PutFrom+PanelHi+2;
      if (m=0)and(infolines=1) then else
      StatusLineColor(pal.bkSelectedNT,pal.txtSelectedNT,pal.bkSelectedST,pal.txtSelectedST,x,y,nm);{}
        cmPrint(pal.bkRama,pal.txtRama,posx,y,'║'); cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,y,'║');
     END;
  fddPanel:
     BEGIN
      m:=0; byt:=0;
      for i:=2 to fddtfiles do if trddir^[i].mark then
        begin inc(m); inc(byt,trddir^[i].totalsec); end;
      x:=posx+1; y:=putfrom+panelhi+2;
      if infolines<=1 then dec(y);
      stemp:='No files selected';
      if m>0 then stemp:='~`'+changechar(extnum(strr(byt)),' ',',')+
                                          '~` block'+eb(byt)+' selected in ~`'+strr(m)+'~` file'+ewfiles(m);
      i:=PanelW div 2-(length(without(stemp,'~`'))div 2); if i<0 then i:=0;
      nm:=space(i)+stemp; nm:=nm+space(abs(PanelW-CClen(nm))); if CClen(nm)>PanelW then delete(nm,PanelW+1+8,10);
      x:=posx+1; if InfoLines<=1 then y:=PutFrom+PanelHi+1 else y:=PutFrom+PanelHi+2;
      if (m=0)and(infolines=1) then else
      StatusLineColor(pal.bkSelectedNT,pal.txtSelectedNT,pal.bkSelectedST,pal.txtSelectedST,x,y,nm);{}
        cmPrint(pal.bkRama,pal.txtRama,posx,y,'║'); cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,y,'║');
     END;
  tapPanel:
     BEGIN
      m:=0; byt:=0;
      for i:=2 to taptfiles do if trddir^[i].mark then
       begin inc(m); inc(byt,trddir^[i].length); end;
      x:=posx+1; y:=putfrom+panelhi+2;
      if infolines<=1 then dec(y);
      stemp:='No files selected';

      if (lp.PanelType=tapPanel)and(rp.PanelType=tapPanel) then
      stemp:='No items selected';
      if m>0 then stemp:='~`'+changechar(extnum(strr(byt)),' ',',')+
                                          '~` bytes selected in ~`'+strr(m)+'~` file'+ewfiles(m);
      if (lp.PanelType=tapPanel)and(rp.PanelType=tapPanel) then
      if m>0 then stemp:='~`'+changechar(extnum(strr(byt)),' ',',')+
                                          '~` bytes selected in ~`'+strr(m)+'~` item'+ewitems(m,lang);
      i:=PanelW div 2-(length(without(stemp,'~`'))div 2); if i<0 then i:=0;
      nm:=space(i)+stemp; nm:=nm+space(abs(PanelW-CClen(nm))); if CClen(nm)>PanelW then delete(nm,PanelW+1+8,10);
      if (m=0)and(infolines=1) then else
      StatusLineColor(pal.bkSelectedNT,pal.txtSelectedNT,pal.bkSelectedST,pal.txtSelectedST,x,y,nm);{}
        cmPrint(pal.bkRama,pal.txtRama,posx,y,'║'); cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,y,'║');
     END;
  sclPanel:
     BEGIN
      m:=0; byt:=0;
      for i:=2 to scltfiles do if trddir^[i].mark then
        begin inc(m); inc(byt,trddir^[i].totalsec); end;
      x:=posx+1; y:=putfrom+panelhi+2;
      if infolines<=1 then dec(y);
      stemp:='No files selected';
      if m>0 then stemp:='~`'+changechar(extnum(strr(byt)),' ',',')+
                                          '~` block'+eb(byt)+' selected in ~`'+strr(m)+'~` file'+ewfiles(m);
      i:=PanelW div 2-(length(without(stemp,'~`'))div 2); if i<0 then i:=0;
      nm:=space(i)+stemp; nm:=nm+space(abs(PanelW-CClen(nm))); if CClen(nm)>PanelW then delete(nm,PanelW+1+8,10);
      x:=posx+1; if InfoLines<=1 then y:=PutFrom+PanelHi+1 else y:=PutFrom+PanelHi+2;
      if (m=0)and(infolines=1) then else
      StatusLineColor(pal.bkSelectedNT,pal.txtSelectedNT,pal.bkSelectedST,pal.txtSelectedST,x,y,nm);{}
        cmPrint(pal.bkRama,pal.txtRama,posx,y,'║'); cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,y,'║');
     END;
  zxzPanel:
     BEGIN
      m:=0; byt:=0;
      for i:=2 to zxztfiles do if trddir^[i].mark then
        begin inc(m); inc(byt,trddir^[i].totalsec); end;
      if infolines<=1 then dec(y);
      stemp:='No files selected';
      if m>0 then stemp:='~`'+changechar(extnum(strr(byt)),' ',',')+
                                          '~` block'+eb(byt)+' selected in ~`'+strr(m)+'~` file'+ewfiles(m);

      i:=PanelW div 2-(length(without(stemp,'~`'))div 2); if i<0 then i:=0;
      nm:=space(i)+stemp; nm:=nm+space(abs(PanelW-CClen(nm))); if CClen(nm)>PanelW then delete(nm,PanelW+1+8,10);
      x:=posx+1; if InfoLines<=1 then y:=PutFrom+PanelHi+1 else y:=PutFrom+PanelHi+2;
      if (m=0)and(infolines=1) then else
      Case InfoLines of
       1: y:=putfrom+panelhi+1;
       2: y:=putfrom+panelhi+1;
       3: y:=putfrom+panelhi+3;
      End;
      StatusLineColor(pal.bkSelectedNT,pal.txtSelectedNT,pal.bkSelectedST,pal.txtSelectedST,x,y,nm);
      cmPrint(pal.bkRama,pal.txtRama,posx,y,'║'); cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,y,'║');
     END;
  End;
  UpdateScreen(false);
 End;

                       {=========== FREE =============}
if (pos('f',LowerCase(parts))<>0)or(pos('A',parts)<>0) then if (PanelType>=1)and(PanelType<=10) then
 Begin
  Case PanelType of
   pcPanel:
     BEGIN
      if infolines>2 then
       begin
        freeBytes:=DiskFreePath(pcnd); nm:=FormatFreeBytes(freeBytes);
        stemp:='~`'+nm+'~` free';
        i:=PanelW div 2-(length(without(stemp,'~`'))div 2); if i<0 then i:=0;
        nm:=space(i)+stemp;
        nm:=nm+space(abs(PanelW-CClen(nm))); if CClen(nm)>PanelW then delete(nm,PanelW+1+8,10);
        x:=posx+1; if InfoLines<=1 then y:=PutFrom+PanelHi+1 else y:=PutFrom+PanelHi+2;
        StatusLineColor(pal.bkFreeLineNT,pal.txtFreeLineNT,pal.bkFreeLineST,pal.txtFreeLineST,x,y+1,nm);{}
        cmPrint(pal.bkRama,pal.txtRama,posx,y+1,'║'); cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,y+1,'║');
       end;
     END;
  trdPanel,fdiPanel,fddPanel:
     BEGIN
      if infolines>2 then
       begin
        byt:=zxdisk.free;
        stemp:=strr(byt);
        nm:='~`'+stemp+'~` block'+eb(byt)+' free~`';
        stemp:=nm+'~`';
        i:=PanelW div 2-(length(without(stemp,'~`'))div 2); if i<0 then i:=0;
        nm:=space(i)+stemp; nm:=nm+space(abs(PanelW-CClen(nm))); if CClen(nm)>PanelW then delete(nm,PanelW+1+8,10);
        x:=posx+1; if InfoLines<=1 then y:=PutFrom+PanelHi+1 else y:=PutFrom+PanelHi+2;
        StatusLineColor(pal.bkFreeLineNT,pal.txtFreeLineNT,pal.bkFreeLineST,pal.txtFreeLineST,x,y+1,nm);{}
        cmPrint(pal.bkRama,pal.txtRama,posx,y+1,'║'); cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,y+1,'║');
       end;
     END;
  sclPanel:
     BEGIN
      if infolines>2 then
       begin
        stemp:=strr(scltfiles-1);
        nm:='Total ~`'+stemp+'~` file'+eb(vall(stemp))+'~`';
        stemp:=nm+'~`';
        i:=PanelW div 2-(length(without(stemp,'~`'))div 2); if i<0 then i:=0;
        nm:=space(i)+stemp; nm:=nm+space(abs(PanelW-CClen(nm))); if CClen(nm)>PanelW then delete(nm,PanelW+1+8,10);
        StatusLineColor(pal.bkFreeLineNT,pal.txtFreeLineNT,pal.bkFreeLineST,pal.txtFreeLineST,x,y+1,nm);{}
        cmPrint(pal.bkRama,pal.txtRama,posx,y+1,'║'); cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,y+1,'║');
       end;
     END;
  tapPanel:
     BEGIN
      if infolines>2 then
       begin
        byt:=taptfiles-1; m:=0;
        for i:=2 to taptfiles do if trddir^[i].tapflag=0 then inc(m);
        stemp:=strr(byt-m);
        if (lp.PanelType=tapPanel)and(rp.PanelType=tapPanel) then stemp:=strr(byt);
        nm:='Total ~`'+stemp+'~` file'+eb(vall(stemp))+'~`';
        if (lp.PanelType=tapPanel)and(rp.PanelType=tapPanel) then
        nm:='Total ~`'+stemp+'~` item'+eb(vall(stemp))+'~`';
        stemp:=nm+'~`';
        i:=PanelW div 2-(length(without(stemp,'~`'))div 2); if i<0 then i:=0;
        nm:=space(i)+stemp; nm:=nm+space(abs(PanelW-CClen(nm))); if CClen(nm)>PanelW then delete(nm,PanelW+1+8,10);
        StatusLineColor(pal.bkFreeLineNT,pal.txtFreeLineNT,pal.bkFreeLineST,pal.txtFreeLineST,x,y+1,nm);{}
        cmPrint(pal.bkRama,pal.txtRama,posx,y+1,'║'); cmPrint(pal.bkRama,pal.txtRama,posx+PanelW+1,y+1,'║');
       end;
     END;
  End;
  UpdateScreen(false);
 End;


if (pos('i',LowerCase(parts))<>0)or(pos('A',parts)<>0) then
 Begin
  Case lp.PanelType of
   pcPanel:  if rp.PanelType=infPanel then pcInfoPanel(left);
   trdPanel: if rp.PanelType=infPanel then trdInfoPanel(left);
   fdiPanel: if rp.PanelType=infPanel then trdInfoPanel(left);
   sclPanel: if rp.PanelType=infPanel then trdInfoPanel(left);
   tapPanel: if rp.PanelType=infPanel then trdInfoPanel(left);
   fddPanel: if rp.PanelType=infPanel then trdInfoPanel(left);
   zxzPanel: if rp.PanelType=infPanel then trdInfoPanel(left);
   flpPanel: if rp.PanelType=infPanel then trdInfoPanel(left);
  End;
  Case rp.PanelType of
   pcPanel:  if lp.PanelType=infPanel then pcInfoPanel(right);
   trdPanel: if lp.PanelType=infPanel then trdInfoPanel(right);
   fdiPanel: if lp.PanelType=infPanel then trdInfoPanel(right);
   sclPanel: if lp.PanelType=infPanel then trdInfoPanel(right);
   tapPanel: if lp.PanelType=infPanel then trdInfoPanel(right);
   fddPanel: if lp.PanelType=infPanel then trdInfoPanel(right);
   zxzPanel: if lp.PanelType=infPanel then trdInfoPanel(right);
   flpPanel: if lp.PanelType=infPanel then trdInfoPanel(right);
  End;
    UpdateScreen(false);
 End;

End;



{============================================================================}
Function  TPanel.GetTreeC(path:string):byte;
Begin
TreeC:=length(path)-length(without(path,PathDelim));
GetTreeC:=TreeC;
End;



{============================================================================}
Function  TPanel.Insed:word;
Var
   i,m:word;
Begin
m:=0;
Case PanelType of
 pcPanel:
   BEGIN
    for i:=1 to pctdirs+pctfiles do if pcDir^[i].mark then inc(m);
   END;
 trdPanel:
   BEGIN
    for i:=1 to trdtfiles do if trdDir^[i].mark then inc(m);
   END;
 fdiPanel:
   BEGIN
    for i:=1 to fditfiles do if trdDir^[i].mark then inc(m);
   END;
 sclPanel:
   BEGIN
    for i:=1 to scltfiles do if trdDir^[i].mark then inc(m);
   END;
 tapPanel:
   BEGIN
    for i:=1 to taptfiles do if trdDir^[i].mark then inc(m);
   END;
 fddPanel:
   BEGIN
    for i:=1 to fddtfiles do if trdDir^[i].mark then inc(m);
   END;
 zxzPanel:
   BEGIN
    for i:=1 to zxztfiles do if trdDir^[i].mark then inc(m);
   END;
End;
Insed:=m;
End;



{============================================================================}
Procedure TPanel.Inside;
Begin
Case PanelType of
 pcPanel:
   BEGIN
     tdirs:=pctdirs;
     tfiles:=pctfiles;
     f:=pcf;
     from:=pcfrom;
   END;
 trdPanel:
   BEGIN
     tdirs:=0;
     tfiles:=trdtfiles;
     f:=trdf;
     from:=trdfrom;
   END;
 fdiPanel:
   BEGIN
     tdirs:=0;
     tfiles:=fditfiles;
     f:=fdif;
     from:=fdifrom;
   END;
 fddPanel:
   BEGIN
     tdirs:=0;
     tfiles:=fddtfiles;
     f:=fddf;
     from:=fddfrom;
   END;
 tapPanel:
   BEGIN
     tdirs:=0;
     tfiles:=taptfiles;
     f:=tapf;
     from:=tapfrom;
   END;
 sclPanel:
   BEGIN
     tdirs:=0;
     tfiles:=scltfiles;
     f:=sclf;
     from:=sclfrom;
   END;
 zxzPanel:
   BEGIN
     tdirs:=0;
     tfiles:=zxztfiles;
     f:=zxzf;
     from:=zxzfrom;
   END;
 flpPanel:
   BEGIN
     tdirs:=0;
     tfiles:=flptfiles;
     f:=flpf;
     from:=flpfrom;
   END;
End;
End;



{============================================================================}
Procedure TPanel.Outside;
Var PT:byte;
Begin
PT:=PanelType;
if PT=noPanel then PT:=LastPanelType;
if PT=infPanel then PT:=clLastPanelType;
Case PT of
 pcPanel:
   BEGIN
     pctdirs:=tdirs;
     pctfiles:=tfiles;
     pcf:=f;
     pcfrom:=from;
   END;
 trdPanel:
   BEGIN
     trdtfiles:=tfiles;
     trdf:=f;
     trdfrom:=from;
   END;
 fdiPanel:
   BEGIN
     fditfiles:=tfiles;
     fdif:=f;
     fdifrom:=from;
   END;
 fddPanel:
   BEGIN
     fddtfiles:=tfiles;
     fddf:=f;
     fddfrom:=from;
   END;
 tapPanel:
   BEGIN
     taptfiles:=tfiles;
     tapf:=f;
     tapfrom:=from;
   END;
 sclPanel:
   BEGIN
     scltfiles:=tfiles;
     sclf:=f;
     sclfrom:=from;
   END;
 zxzPanel:
   BEGIN
     zxztfiles:=tfiles;
     zxzf:=f;
     zxzfrom:=from;
   END;
 flpPanel:
   BEGIN
     flptfiles:=tfiles;
     flpf:=f;
     flpfrom:=from;
   END;
End;
End;



{============================================================================}
Function TPanel.Index:word;
Begin
 Index:=from+f-1;
End;





{============================================================================}
Function TPanel.TrueName(ind:word):string;
Var
    s:string;
Begin
  case PanelType of
    trdPanel, sclPanel: begin
      s := Trim(string(trdDir^[ind].name));
      if trdDir^[ind].typ <> ' ' then
        s := s + '.' + trdDir^[ind].typ;
    end;
    tapPanel: begin
      s := Trim(string(trdDir^[ind].name));
      if trdDir^[ind].tapflag = 0 then
        case trdDir^[ind].taptyp of
          0: s := s + ' [P]';
          1: s := s + ' [N]';
          2: s := s + ' [C]';
          3: s := s + ' [B]';
        end;
    end;
  else
    s := string(pcDir^[ind].fullname);
  end;
  TrueName := s;
End;







{============================================================================}
Procedure TPanel.TrueCur;
Var
  fnd: boolean;
  st: string;
  i: integer;
Begin
  fnd := false;
 Case panelType of
    pcPanel: begin
      for i := 1 to pctdirs + pctfiles do begin
        if string(pcDir^[i].fullname) <> '' then
          st := LowerCase(string(pcDir^[i].fullname))
        else begin
          st := string(pcDir^[i].fname);
          if (Length(st) > 0) and (st[1] = ' ') then Delete(st, 1, 1);
          if Trim(string(pcDir^[i].fext)) <> '' then
            st := LowerCase(st + '.' + string(pcDir^[i].fext))
          else
            st := LowerCase(st);
     end;
        if st = LowerCase(Trim(string(pcnn))) then begin
          fnd := true;
          break;
       end;
     end;
      if fnd then begin
        pcf := 1; pcfrom := 1;
        while pcfrom + pcf - 1 < i do begin
          Inc(pcf);
          if pcf > PanelHi * Columns then begin
            pcf := PanelHi * Columns;
            Inc(pcfrom);
       end;
     end;
       end;
      while pcfrom + pcf - 1 > pctdirs + pctfiles do begin
        Dec(pcfrom);
        if pcfrom < 1 then begin pcfrom := 1; Dec(pcf); end;
     end;
      if pcf < 1 then pcf := 1;
    end;
    trdPanel: begin
      if trdfrom + trdf - 1 <> 1 then begin
        for i := 1 to trdtfiles do begin
          st := string(trdDir^[i].name) + '.' + trdDir^[i].typ;
          if st = trdnn then begin fnd := true; break; end;
       end;
        if fnd then begin
          trdf := 1; trdfrom := 1;
          while trdfrom + trdf - 1 < i do begin
            Inc(trdf);
            if trdf > PanelHi * Columns then begin
              trdf := PanelHi * Columns; Inc(trdfrom);
         end;
   END;
       end;
        while trdfrom + trdf - 1 > trdtfiles do begin
          Dec(trdfrom);
          if trdfrom < 1 then begin trdfrom := 1; Dec(trdf); end;
       end;
        if trdf < 1 then trdf := 1;
     end;
       end;
    fdiPanel: begin
      if fdifrom + fdif - 1 <> 1 then begin
        for i := 1 to fditfiles do begin
          st := string(trdDir^[i].name) + '.' +
            trdDir^[i].typ;
          if st = fdinn then begin
            fnd := true; break;
     end;
   END;
        if fnd then begin
          fdif := 1; fdifrom := 1;
          while fdifrom + fdif - 1 < i do begin
            Inc(fdif);
            if fdif > PanelHi * Columns then begin
              fdif := PanelHi * Columns;
              Inc(fdifrom);
         end;
       end;
       end;
        while fdifrom + fdif - 1 > fditfiles do begin
          Dec(fdifrom);
          if fdifrom < 1 then begin
            fdifrom := 1; Dec(fdif);
     end;
   END;
        if fdif < 1 then fdif := 1;
         end;
       end;
    sclPanel: begin
      if sclfrom + sclf - 1 <> 1 then begin
        for i := 1 to scltfiles do begin
          st := string(trdDir^[i].name) + '.' + trdDir^[i].typ;
          if st = sclnn then begin fnd := true; break; end;
       end;
        if fnd then begin
          sclf := 1; sclfrom := 1;
          while sclfrom + sclf - 1 < i do begin
            Inc(sclf);
            if sclf > PanelHi * Columns then begin
              sclf := PanelHi * Columns; Inc(sclfrom);
         end;
   END;
       end;
        while sclfrom + sclf - 1 > scltfiles do begin
          Dec(sclfrom);
          if sclfrom < 1 then begin sclfrom := 1; Dec(sclf); end;
       end;
        if sclf < 1 then sclf := 1;
     end;
       end;
    fddPanel: begin
      if fddfrom + fddf - 1 <> 1 then begin
        for i := 1 to fddtfiles do begin
          st := string(trdDir^[i].name) + '.' +
            trdDir^[i].typ;
          if st = fddnn then begin
            fnd := true; break;
     end;
   END;
        if fnd then begin
          fddf := 1; fddfrom := 1;
          while fddfrom + fddf - 1 < i do begin
            Inc(fddf);
            if fddf > PanelHi * Columns then begin
              fddf := PanelHi * Columns;
              Inc(fddfrom);
         end;
       end;
       end;
        while fddfrom + fddf - 1 > fddtfiles do begin
          Dec(fddfrom);
          if fddfrom < 1 then begin
            fddfrom := 1; Dec(fddf);
     end;
   END;
        if fddf < 1 then fddf := 1;
       end;
    end;
    zxzPanel: begin
      if zxzfrom + zxzf - 1 <> 1 then begin
        for i := 1 to zxztfiles do begin
          st := string(trdDir^[i].name) + '.' +
            trdDir^[i].typ;
          if st = zxznn then begin
            fnd := true; break;
          end;
        end;
        if fnd then begin
          zxzf := 1; zxzfrom := 1;
          while zxzfrom + zxzf - 1 < i do begin
            Inc(zxzf);
            if zxzf > PanelHi * Columns then begin
              zxzf := PanelHi * Columns;
              Inc(zxzfrom);
         end;
       end;
       end;
        while zxzfrom + zxzf - 1 > zxztfiles do begin
          Dec(zxzfrom);
          if zxzfrom < 1 then begin
            zxzfrom := 1; Dec(zxzf);
     end;
       end;
        if zxzf < 1 then zxzf := 1;
         end;
       end;
    tapPanel: begin
      if tapfrom + tapf - 1 <> 1 then begin
        while tapfrom + tapf - 1 > taptfiles do begin
          Dec(tapfrom);
          if tapfrom < 1 then begin tapfrom := 1; Dec(tapf); end;
        end;
        if tapf < 1 then tapf := 1;
       end;
     end;

 End;
End;

{============================================================================}
Procedure TPanel.Enter;
Var
  fullPath, ext, stemp: string;
  i: word;
  oldDevId: Int64;
Begin
Case PanelType of
    pcPanel: begin
      if pcDir^[Index].flength < 0 then begin
        fullPath := string(pcDir^[Index].fullname);
        if fullPath = '' then begin
          fullPath := string(pcDir^[Index].fname);
          if (Length(fullPath) > 0) and (fullPath[1] = ' ') then
            Delete(fullPath, 1, 1);
        end;        if fullPath = '..' then begin
          CtrlPgUp;
      Exit;
     end;
        fullPath := IncludeTrailingPathDelimiter(pcnd) + fullPath;
        oldDevId := devId;
        inc(treec); pcfrom := 1; pcf := 1;
        pcMDF(fullPath);
        Inside;
        if devId <> oldDevId then
          Info('csfi')
        else
          Info('csi');
        pcPDF(pcfrom);
        exit;
      end;
      fullPath := pcnd + TrueName(Index);

      if (Index > tdirs) and
         itHobeta(fullPath, hobetainfo) then begin
        scputwin(pal.bkdRama, pal.txtdRama,
          HalfMaxX - 24, HalfMaxY - 4,
          HalfMaxX + 25, HalfMaxY - 3 + 6);
        cmcentre(pal.bkdRama, pal.txtdRama,
          HalfMaxY - 4, '═ Information ');
        StatusLineColor(
          pal.bkdLabelST, pal.txtdLabelST,
          pal.bkdLabelNT, pal.txtdLabelNT,
          HalfMaxX - 21, HalfMaxY - 2,
          'Name       Type     Start'
          + '      Length Blocks');

        stemp := '~`' + hobetainfo.name + '   ';
        if TRDOS3 then
          stemp := stemp + hobetainfo.typ
            + chr(lo(hobetainfo.start))
            + chr(hi(hobetainfo.start))
        else
          stemp := stemp + '<' + hobetainfo.typ + '>';
        stemp := stemp
          + space(11 - length(
              changechar(extnum(strr(hobetainfo.start)),
                ' ', ',')))
          + changechar(extnum(strr(hobetainfo.start)),
              ' ', ',')
          + space(11 - length(
              changechar(extnum(strr(hobetainfo.length)),
                ' ', ',')))
          + changechar(extnum(strr(hobetainfo.length)),
              ' ', ',')
          + '  (' + strr(hobetainfo.totalsec) + ')~`';
        StatusLineColor(
          pal.bkdLabelST, pal.txtdLabelST,
          pal.bkdLabelNT, pal.txtdLabelNT,
          HalfMaxX - 21, HalfMaxY - 1, stemp);

        colour(pal.bkdLabelNT, pal.txtdLabelNT);
        cbutton(pal.bkdButtonA, pal.txtdButtonA,
          pal.bkdButtonShadow, pal.txtdButtonShadow,
          HalfMaxX - 4, HalfMaxY + 1, '    OK    ', true);

      rpause;
      restscr;
     end;


      ext := LowerCase(ExtractFileExt(TrueName(Index)));
      if ext = '.trd' then begin
        PanelType := trdPanel;
        trdFile   := fullPath;
        trdMDFs(trdFile);
        trdfrom := 1; trdf := 1;
        Inside;
        Build('012');
      reInfo('cbdnsfi');
        trdPDFs(trdfrom);
      Exit;
     end;

      if ext = '.scl' then begin
        PanelType := sclPanel;
        sclFile   := fullPath;
        sclMDFs(sclFile);
        sclfrom := 1; sclf := 1;
        Inside;
        Build('012');
        reInfo('cbdnsfi');
        sclPDFs(sclfrom);
        exit;
      end;

      if ext = '.tap' then begin
        PanelType := tapPanel;
        tapFile   := fullPath;
        tapMDFs(tapFile);
        tapfrom := 1; tapf := 1;
        Inside;
        Build('012');
        reInfo('cbdnsfi');
        tapPDFs(tapfrom);
        exit;
      end;

      if place = left then begin
        if (ext = '.fdi') and isFDI(lp, fullPath) then begin
          PanelType := fdiPanel;
          fdiFile   := fullPath;
        fdiMDFs(fdifile);
          fdifrom := 1; fdif := 1;
          Inside;
          Build('012');
        reInfo('cbdnsfi');
        fdiPDFs(fdifrom);
        Exit;
       end;
      end else begin
        if (ext = '.fdi') and isFDI(rp, fullPath) then begin
          PanelType := fdiPanel;
          fdiFile   := fullPath;
        fdiMDFs(fdifile);
          fdifrom := 1; fdif := 1;
          Inside;
          Build('012');
        reInfo('cbdnsfi');
        fdiPDFs(fdifrom);
        Exit;
       end;
     END;

      if ext = '.fdd' then begin
        PanelType := fddPanel;
        fddFile   := fullPath;
      fddMDFs(fddfile);
        fddfrom := 1; fddf := 1;
        Inside;
        Build('012');
      reInfo('cbdnsfi');
      fddPDFs(fddfrom);
      Exit;
     End;

      if ext = '.zxz' then begin
        PanelType := zxzPanel;
        zxzFile   := fullPath;
        zxzMDFs(zxzFile);
        zxzfrom := 1; zxzf := 1;
      Inside;
        Build('012');
      reInfo('cbdnsfi');
      zxzPDFs(zxzfrom);
        exit;
     end;
   END;
    trdPanel, fdiPanel, sclPanel, tapPanel,
    fddPanel, zxzPanel, flpPanel: begin

      if Index = 1 then begin

        trdfile:=''; fdifile:=''; sclfile:=''; tapfile:=''; fddfile:='';

      for i:=1 to 257 do Begin trdIns^[i].crc16:=0; trdDir^[i].name[1]:=#0; end;
      if PanelType=tapPanel then CheckTapInsed;
      PanelType:=pcPanel;
      MDF;
      TrueCur;
      Inside;
        Build('012');
        reInfo('A');
        rePDF;
      Exit;
     end;
   END;
End;
End;




{============================================================================}
Procedure TPanel.CtrlPgUp;
Var
    stemp:string; i:word;
    oldDevId: Int64;
Begin
Case PanelType of
 pcPanel:
   BEGIN
    if TreeC>1 then
     Begin
      oldDevId := devId;
      Dec(TreeC);      stemp:=ExcludeTrailingPathDelimiter(pcnd);
      pcnn:=ExtractFileName(stemp);
      stemp:=ExtractFilePath(stemp);
      if (Length(stemp)>0)and(stemp[Length(stemp)]<>PathDelim) then
        stemp:=stemp+PathDelim;
      pcMDF(stemp);
      TrueCur;
      Inside;
      if devId <> oldDevId then
        Info('csfi')
      else
        Info('csi');
      pcPDF(pcfrom);{}
     End;
   END;
 trdPanel,fdiPanel,sclPanel,tapPanel,fddPanel,zxzPanel,flpPanel:
   BEGIN
      for i:=1 to 257 do Begin trdIns^[i].crc16:=0; trdDir^[i].name[1]:=#0; end;
      if PanelType=tapPanel then CheckTapInsed;
      trdfile:=''; fdifile:=''; sclfile:=''; tapfile:=''; fddfile:=''; zxzfile:='';
      PanelType:=pcPanel;
      reMDF;
      TrueCur;
      Inside;
      Build('012');
      reInfo('cbdnsfi');
      rePDF;
   END;
End;
End;




{============================================================================}
Procedure TPanel.CtrlPgDn;
Var
    stemp:string;
    oldDevId: Int64;
Begin
Case PanelType of
 pcPanel:
   BEGIN
    oldDevId := devId;
    if Index<=tdirs then
     begin
      if NoSpace(pcnn)='..' then
       begin
        CtrlPgUp;
       Exit;
       end
      else
       begin
        inc(treec); pcfrom:=1; pcf:=1;
        stemp:=pcnd+pcnn+PathDelim;
        pcMDF(stemp);
       end;
     end;
    Inside;
    if devId <> oldDevId then
      Info('csfi')
    else
      Info('csi');
    pcPDF(pcfrom);{}
   END;
End;
End;




{============================================================================}
{$push}{$hints off}
procedure TPanel.AltF1F2(ps: byte);
{$IFNDEF WINDOWS}
begin
end;
{$ELSE}
var
  p: ^TPanel;
  i, sel, dcnt, topRow, row: byte;
  winX1, winX2, winY1, winY2: word;
  firstVisible, visibleCount: byte;
  key: word;
  ch: char;
  drives: array[1..26] of char;
  driveNums: array[1..26] of byte;
  driveNames: array[1..26] of string;
  freeB: int64;
  root: string;
  lineW: integer;
  driveNo: byte;

  function DriveDisplayName(letter: char; driveNum: byte): string;
  {$IFDEF WINDOWS}
  var
    volName: array[0..255] of AnsiChar;
    fsName: array[0..255] of AnsiChar;
    serial, maxCompLen, flags: DWORD;
    dtype: UINT;
    ok: BOOL;
  {$ENDIF}
  begin
    DriveDisplayName := letter + '_DRIVE';
    {$IFDEF WINDOWS}
    dtype := GetDriveTypeA(PAnsiChar(AnsiString(letter + ':\')));
    if dtype = DRIVE_RAMDISK then DriveDisplayName := 'RAMDISK'
    else if dtype = DRIVE_CDROM then DriveDisplayName := 'CDROM'
    else if dtype = DRIVE_REMOVABLE then DriveDisplayName := 'REMOVABLE'
    else begin
      FillChar(volName, SizeOf(volName), 0);
      FillChar(fsName, SizeOf(fsName), 0);
      ok := GetVolumeInformationA(
        PAnsiChar(AnsiString(letter + ':\')),
        @volName[0], SizeOf(volName),
        @serial, maxCompLen, flags,
        @fsName[0], SizeOf(fsName));
      if ok and (Trim(StrPas(@volName[0])) <> '') then
        DriveDisplayName := StrPas(@volName[0]);
    end;
    {$ELSE}
    if driveNum = driveNum then ;
    {$ENDIF}
  end;

  function DriveIndexByLetter(c: char): byte;
  var
    k: byte;
  begin
    for k := 1 to dcnt do
      if drives[k] = c then begin
        DriveIndexByLetter := k;
        exit;
      end;
    DriveIndexByLetter := 0;
  end;

  procedure DrawMenu;
  var
    k, idx: byte;
    diskInfo, diskSize: string;
  begin
    Colour(pal.bkdRama, pal.txtdRama);
    DrawBox(pal.bkdRama, pal.txtdRama, winX1, winY1, winX2, winY2);
    CMPrint(pal.bkdRama, pal.txtdRama,
      winX1 + (winX2 - winX1 + 1 - 4) div 2, winY1 + 1, 'Disk');

    if firstVisible > 1 then
      CMPrint(pal.bkdRama, pal.txtdRama, winX1 + lineW, topRow, '↑');
    if firstVisible + visibleCount - 1 < dcnt then
      CMPrint(pal.bkdRama, pal.txtdRama, winX1 + lineW,
        topRow + visibleCount - 1, '↓');

    for k := 1 to visibleCount do begin
      idx := firstVisible + k - 1;
      row := topRow + k - 1;
      freeB := DiskFreePath(drives[idx] + ':\');
      diskSize := ChangeChar(FormatFreeBytes(freeB), '.', ',');
      diskInfo := ' ' + drives[idx] + ': Local   '
        + RightPad(diskSize, 7) + '  ' + driveNames[idx];
      if Length(diskInfo) > lineW - 1 then
        diskInfo := Copy(diskInfo, 1, lineW - 1);
      while Length(diskInfo) < lineW - 1 do
        diskInfo := diskInfo + ' ';
      if idx = sel then
        CMPrint(pal.bkdPoleST, pal.txtdPoleST, winX1 + 1, row, diskInfo)
      else
        CMPrint(pal.bkdPoleNT, pal.txtdPoleNT, winX1 + 1, row, diskInfo);
    end;
    UpdateScreen(false);
  end;

begin
  if ps = Left then p := @lp else p := @rp;
  dcnt := 0;
  for i := 1 to 26 do begin
    driveNo := i;
    root := Chr(Ord('A') + i - 1) + ':\';
    if DiskStatus(driveNo) = 0 then begin
      Inc(dcnt);
      drives[dcnt] := Chr(Ord('A') + i - 1);
      driveNums[dcnt] := driveNo;
      driveNames[dcnt] := DriveDisplayName(drives[dcnt], driveNo);
    end;
  end;
  if dcnt = 0 then begin
    for i := Ord('A') to Ord('Z') do begin
      root := Chr(i) + ':\';
      if DirectoryExists(root) then begin
        Inc(dcnt);
        drives[dcnt] := Chr(i);
        driveNums[dcnt] := i - Ord('A') + 1;
        driveNames[dcnt] := DriveDisplayName(drives[dcnt], driveNums[dcnt]);
      end;
    end;
  end;

  if dcnt = 0 then begin
    ErrorMessage('No drives found');
    exit;
  end;

  CurOff;
  sel := 1;
  lineW := p^.PanelW - 3;
  if lineW > 34 then lineW := 34;
  if lineW < 20 then lineW := 20;
  winX1 := p^.PosX + 1;
  winX2 := winX1 + lineW + 1;
  if winX2 > p^.PosX + p^.PanelW then winX2 := p^.PosX + p^.PanelW;
  winY1 := p^.PutFrom + 1;
  visibleCount := p^.PanelHi - 4;
  if visibleCount < 3 then visibleCount := 3;
  if visibleCount > dcnt then visibleCount := dcnt;
  winY2 := winY1 + visibleCount + 2;
  if winY2 > GmaxY - 1 then winY2 := GmaxY - 1;
  topRow := winY1 + 2;
  lineW := winX2 - winX1 - 1;
  firstVisible := 1;

  Main.CancelSB;
  scPutWin(pal.bkdRama, pal.txtdRama, winX1, winY1, winX2, winY2);
  while true do begin
    DrawMenu;
    key := rKey;
    if key = _Esc then begin RestScr; exit; end;
    if (key = _Enter) or (key = PadEnter) then break;
    if (key = _Up) or (key = Pad8) then begin
      if sel > 1 then Dec(sel) else sel := dcnt;
      if sel < firstVisible then firstVisible := sel;
      if sel >= firstVisible + visibleCount then
        firstVisible := sel - visibleCount + 1;
      continue;
    end;
    if (key = _Down) or (key = Pad2) then begin
      if sel < dcnt then Inc(sel) else sel := 1;
      if sel < firstVisible then firstVisible := sel;
      if sel >= firstVisible + visibleCount then
        firstVisible := sel - visibleCount + 1;
      continue;
    end;
    ch := UpCase(Chr(Lo(key)));
    if (ch >= 'A') and (ch <= 'Z') then begin
      i := DriveIndexByLetter(ch);
      if i <> 0 then begin
        sel := i;
        if sel < firstVisible then firstVisible := sel;
        if sel >= firstVisible + visibleCount then
          firstVisible := sel - visibleCount + 1;
        break;
      end;
    end;
  end;
  RestScr;
  Main.GlobalRedraw;

  p^.PanelType := pcPanel;
  p^.pcnd := drives[sel] + ':\';
  p^.pcnn := '';
  p^.pcfrom := 1;
  p^.pcf := 1;
  p^.pcMDF(p^.pcnd);
  p^.TrueCur;
  p^.Inside;
  GlobalRedraw;
end;
{$ENDIF}
{$pop}



{============================================================================}
{$push}{$hints off}
procedure TPanel.CtrlLeftRightDoIt(stemp: char); begin end;
{$pop}


{============================================================================}
Procedure TPanel.Insert;
Begin
Case PanelType of
 pcPanel:
   BEGIN
    if pcDir^[Index].fname<>' ..' then pcDir^[Index].mark:=not pcDir^[Index].mark;
    inc(f);
   END;

 trdPanel,fdiPanel,sclPanel,fddPanel,zxzPanel,flpPanel:
   BEGIN
    if from+f-1>1 then
      if (ord(trddir^[from+f-1].name[1])<>1)and(ord(trddir^[from+f-1].name[1])<>0) then
    trddir^[from+f-1].mark:=not trddir^[from+f-1].mark;
    inc(f);
   END;
 tapPanel:
   BEGIN
    if from+f-1>1 then
    if PanelTypeOf(oFocus)=tapPanel then
     begin
       trddir^[from+f-1].mark:=not trddir^[from+f-1].mark;
     end
    else
     begin
      if trddir^[from+f-1].tapflag<>0 then
       trddir^[from+f-1].mark:=not trddir^[from+f-1].mark;
     end;
    inc(f);
   END;

End;
Info('si')
End;




{============================================================================}
Procedure TPanel.Star(ctrled:boolean);
Var
    b,i:word;
Begin
Case PanelType of
 pcPanel:
   BEGIN
    if Ctrled then b:=1 else b:=pctdirs+1;
    for i:=b to pctdirs+pctfiles do if pcDir^[i].fname<>' ..' then pcDir^[i].mark:=not pcDir^[i].mark;
   END;
 trdPanel,fdiPanel,sclPanel,fddPanel,zxzPanel,flpPanel:
   BEGIN
    for i:=2 to tfiles do if (ord(trddir^[i].name[1])<>1)and(ord(trddir^[i].name[1])<>0) then
     trddir^[i].mark:=not trddir^[i].mark;
   END;
 tapPanel:
   BEGIN
    for i:=2 to taptfiles do
     begin
      if PanelTypeOf(oFocus)=tapPanel then
       begin
         trddir^[i].mark:=not trddir^[i].mark;
       end
      else
       begin
        if trddir^[i].tapflag<>0 then
         trddir^[i].mark:=not trddir^[i].mark;
       end;
     end;
   END;
End;
Info('si');
End;





{============================================================================}
Procedure TPanel.Plus(ctrled:boolean);
Var
    a,b,i:word; s,stemp:string;
Begin
Case PanelType of
 pcPanel:
   BEGIN
    if Ctrled then
     begin a:=1; b:=pctdirs; s:='*.*'; end
    else
     begin
      a:=pctdirs+1; b:=pctdirs+pctfiles;
      stemp:=' Select ';
      plusmask:=nospace(GetWildMask(stemp,plusmask));
      if scanf_esc then exit;
      s:=plusmask;
     end;
    for i:=a to b do if pcDir^[i].fname<>' ..' then
     Begin
      if nospace(pcdir^[i].fext)=''
        then stemp:=nospace(pcdir^[i].fname+'.!!!')
        else stemp:=nospace(pcdir^[i].fname+'.'+pcdir^[i].fext);
      if wild(stemp,s,true) then pcDir^[i].mark:=true;
     End;
   END;
 trdPanel,fdiPanel,sclPanel,fddPanel,zxzPanel,flpPanel:
   BEGIN
    stemp:=' Select ';
    plusmask:=nospaceLR(GetWildMask(stemp,plusmask));
    if scanf_esc then exit;
    for i:=2 to tfiles do if (ord(trddir^[i].name[1])<>1)and(ord(trddir^[i].name[1])<>0) then
     begin
      stemp:=nospaceLR(trddir^[i].name)+'.'+trddir^[i].typ;
      if TRDOS3 then stemp:=stemp+chr(lo(trddir^[i].start))+chr(hi(trddir^[i].start));
      if wild(stemp,plusmask,false) then trddir^[i].mark:=true;
     end;
   END;
 tapPanel:
   BEGIN
    for i:=2 to taptfiles do
     begin
      if PanelTypeOf(oFocus)=tapPanel then
       begin
         trddir^[i].mark:=true;
       end
      else
       begin
        if trddir^[i].tapflag<>0 then
         trddir^[i].mark:=true;
       end;
     end;
   END;
End;
Info('si');
End;





{============================================================================}
Procedure TPanel.Minus(ctrled:boolean);
Var
    a,b,i:word; stemp:string;
Begin
Case PanelType of
 pcPanel:
   BEGIN
    if Ctrled then
      begin a:=1; b:=pctdirs; end
    else
     begin
      a:=pctdirs+1; b:=pctdirs+pctfiles;
      stemp:=' Cancel ';
      minusmask:=nospace(GetWildMask(stemp,minusmask));
      if scanf_esc then exit;
     end;
    for i:=a to b do if pcDir^[i].fname<>' ..' then
     Begin
      if nospace(pcdir^[i].fext)=''
        then stemp:=nospace(pcdir^[i].fname+'.!!!')
        else stemp:=nospace(pcdir^[i].fname+'.'+pcdir^[i].fext);
      if wild(stemp,minusmask,true) then pcDir^[i].mark:=false;
     End;
   END;
 trdPanel,fdiPanel,sclPanel,fddPanel,zxzPanel,flpPanel:
   BEGIN
    stemp:=' Cancel ';
    minusmask:=nospaceLR(GetWildMask(stemp,minusmask));
    if scanf_esc then exit;
    for i:=2 to tfiles do if (ord(trddir^[i].name[1])<>1)and(ord(trddir^[i].name[1])<>0) then
     begin
      stemp:=nospaceLR(trddir^[i].name)+'.'+trddir^[i].typ;
      if TRDOS3 then stemp:=stemp+chr(lo(trddir^[i].start))+chr(hi(trddir^[i].start));
      if wild(stemp,minusmask,false) then trddir^[i].mark:=false;
     end;
   END;
 tapPanel:
   BEGIN
    for i:=2 to taptfiles do
     begin
      if PanelTypeOf(oFocus)=tapPanel then
       begin
         trddir^[i].mark:=false;
       end
      else
       begin
        if trddir^[i].tapflag<>0 then
         trddir^[i].mark:=false;
       end;
     end;
   END;
End;
Info('si');
End;





{============================================================================}
Function TPanel.FirstMarked:word;
Var
    i:word; fnd:boolean;
Begin
fnd:=false;
Case PanelType of
 pcPanel:
   BEGIN
    for i:=1 to pctdirs+pctfiles do if pcDir^[i].mark then begin fnd:=true; break; end;
   END;
 trdPanel:
   BEGIN
    for i:=1 to trdtfiles do if trdDir^[i].mark then begin fnd:=true; break; end;
   END;
 fdiPanel:
   BEGIN
    for i:=1 to fditfiles do if trdDir^[i].mark then begin fnd:=true; break; end;
   END;
 sclPanel:
   BEGIN
    for i:=1 to scltfiles do if trdDir^[i].mark then begin fnd:=true; break; end;
   END;
 tapPanel:
   BEGIN
    for i:=1 to taptfiles do if trdDir^[i].mark then begin fnd:=true; break; end;
   END;
 fddPanel:
   BEGIN
    for i:=1 to fddtfiles do if trdDir^[i].mark then begin fnd:=true; break; end;
   END;
 zxzPanel:
   BEGIN
    for i:=1 to zxztfiles do if trdDir^[i].mark then begin fnd:=true; break; end;
   END;
End;
if fnd then FirstMarked:=i else FirstMarked:=0;
End;






{============================================================================}
Procedure TPanel.Del;
var
  n: word;
  nm, s: string;
  i: integer;
  fm: word;
Begin
  if PanelType = pcPanel then begin
    n := Insed;
    if n = 0 then begin
      if Trim(TrueName(Index)) = '..' then exit;
End;

    if n = 0 then begin
      nm := TrueName(Index);
      if Index <= pctdirs then
        s := 'Do you wish to delete' + #255
           + 'directory ' + nm + ' ?'
      else
        s := 'Do you wish to delete' + #255
           + 'file "' + nm + '" ?';
    end else
      s := 'Do you wish to delete' + #255
         + 'this files ?';

    CancelSB;
    if not CQuestion(s, Eng) then exit;

    if n = 0 then
      pcDir^[Index].mark := true;

    for i := 1 to pctdirs + pctfiles do begin
      if not pcDir^[i].mark then continue;
      pcDeleteEntry(
        IncludeTrailingPathDelimiter(string(pcnd)) +
        string(pcDir^[i].fullname));
    end;
    if Place = Left then begin
      lp.pcMDF(lp.pcnd);
      if rp.PanelType = pcPanel then
        rp.pcMDF(rp.pcnd);
    end else begin
      rp.pcMDF(rp.pcnd);
      if lp.PanelType = pcPanel then
        lp.pcMDF(lp.pcnd);
    end;

    reTrueCur;
    reInside;
    reInfo('cbdnsfi');
    rePDF;
    exit;
  end;

  if PanelType = zxzPanel then exit;

  n := Insed;
  if (n = 0) and (Index <= 1) then exit;
  if (n = 0) and
     ((Ord(trdDir^[Index].name[1]) = 1) or
      (Ord(trdDir^[Index].name[1]) = 0)) then exit;

  if n = 0 then
    s := trdDir^[Index].name + '.' + TRDOSe3(Self, Index);
  if n = 1 then begin
    fm := FirstMarked;
    s := trdDir^[fm].name + '.' + TRDOSe3(Self, fm);
  end;

  if PanelType = tapPanel then begin
    if (n = 0) and (PanelTypeOf(oFocus) <> tapPanel) and
       (trdDir^[Index].tapflag = 0) then exit;
    if n = 0 then begin
      if PanelTypeOf(oFocus) = tapPanel then begin
        if trdDir^[Index].tapflag = 0 then
          s := trdDir^[Index].name
        else
          s := 'codes';
      end else begin
        if Index > 2 then begin
          if trdDir^[Index - 1].tapflag <> 0 then
            s := 'less'
          else
            s := trdDir^[Index - 1].name;
        end else
          s := 'less';
      end;
    end;
    if n = 1 then begin
      fm := FirstMarked;
      if PanelTypeOf(oFocus) = tapPanel then begin
        if trdDir^[fm].tapflag = 0 then
          s := trdDir^[fm].name
        else
          s := 'codes';
      end else begin
        if fm > 2 then begin
          if trdDir^[fm - 1].tapflag <> 0 then
            s := 'less'
          else
            s := trdDir^[fm - 1].name;
        end else
          s := 'less';
      end;
    end;
    if PanelTypeOf(oFocus) = tapPanel then begin
      s := 'Do you wish to delete' + #255
         + 'item "' + s + '" ?';
      if n > 1 then
        s := 'Do you wish to delete' + #255
           + 'this items ?';
    end else begin
      s := 'Do you wish to delete' + #255
         + 'file "' + s + '" ?';
      if n > 1 then
        s := 'Do you wish to delete' + #255
           + 'this files ?';
    end;
  end else begin
    s := 'Do you wish to delete' + #255
       + 'file "' + s + '" ?';
    if n > 1 then
      s := 'Do you wish to delete' + #255
         + 'this files ?';
  end;

  CancelSB;
  if not CQuestion(s, Eng) then exit;

  if n = 0 then
    trdDir^[Index].mark := true;

  case PanelType of
    trdPanel: begin
      if Place = Left  then trdDel(lp)
      else                  trdDel(rp);
    end;
    sclPanel: begin
      if Place = Left  then sclDel(lp)
      else                  sclDel(rp);
    end;
    tapPanel: begin
      if Place = Left  then tapDel(lp)
      else                  tapDel(rp);
    end;
    fdiPanel: begin
      if Place = Left  then fdiDel(lp)
      else                  fdiDel(rp);
    end;
    fddPanel: begin
      if Place = Left  then fddDel(lp)
      else                  fddDel(rp);
    end;
  end;

  reMDF;
  lp.TrueCur; lp.InSide;
  rp.TrueCur; rp.InSide;
  reInfo('cbdnsfi');
  rePDF;
end;


{============================================================================}
{$push}{$hints off}{$notes off}



{============================================================================}
Procedure TPanel.fCopy;
Var
    i:word; n,s:string; was:longint;
Begin
if (PanelTypeOf(Focus)=pcPanel)and(PanelTypeOf(oFocus)=pcPanel)
 then pc2pc(_F5)
 else snCopier(_F5,PanelTypeOf(Focus),PanelTypeOf(oFocus));
End;
{$pop}



{============================================================================}
{$push}{$hints off}{$notes off}



{============================================================================}
Procedure TPanel.fMove;
Var
    i:word; n,s:string;
    skip:boolean;
    TargetPath:string;
Begin
Case PanelType of
 pcPanel:
   BEGIN
    Case PanelTypeOf(oFocus) of
     pcPanel: pc2pc(_F6);
     trdPanel,fdiPanel,fddPanel,tapPanel,sclPanel:
      begin
       snCopier(_F6,PanelTypeOf(Focus),PanelTypeOf(oFocus));
      end;
    End;
   END;
 trdPanel: trdRename;
 fdiPanel: fdiRename;
 fddPanel: fddRename;
 tapPanel: tapRename;
 sclPanel: sclRename;
End;

End;
{$pop}



{$push}{$hints off}





{============================================================================}
Procedure TPanel.Rename;
Begin
Case PanelType of
 pcPanel: pcRename;
 trdPanel: trdRename;
 fdiPanel: fdiRename;
 fddPanel: fddRename;
 tapPanel: tapRename;
 sclPanel: sclRename;
End;

End;
{$pop}





{============================================================================}
Procedure TPanel.Edit;
Begin
Case PanelType of
 trdPanel,fdiPanel,fddPanel,flpPanel:
 BEGIN
    if place=left then zxEditParam(lp,Index) else zxEditParam(rp,Index);
   END;
 zxzPanel:
   BEGIN
     if place=left then zxzExtract(lp) else zxzExtract(rp);
   END;
End;
End;



{============================================================================}
procedure TPanel.MkDir;
var
  d: string;
  cy: word;
       begin
  if PanelType <> pcPanel then exit;
  CurOff;
  cy := HalfMaxY;
  Colour(pal.bkdRama, pal.txtdRama);
  scPutWin(pal.bkdRama, pal.txtdRama,
    HalfMaxX - 23, cy - 3, HalfMaxX + 24, cy);
  cmCentre(pal.bkdRama, pal.txtdRama, cy - 3, ' Make directory ');
  CMPrint(pal.bkdLabelST, pal.txtdLabelST,
    HalfMaxX - 20, cy - 2, 'Directory name');
  CMPrint(pal.bkdInputNT, pal.txtdInputNT,
    HalfMaxX - 21, cy - 1, Space(44));
  Colour(pal.bkdInputNT, pal.txtdInputNT);
  CurOn;
  d := scanf(HalfMaxX - 20, cy - 1, '', 42, 42, 1);
  CurOff;
  RestScr;
  if scanf_esc or (Trim(d) = '') then exit;
  if (Pos(':', d) = 0) and
     ((Length(d) = 0) or (d[1] <> PathDelim)) then
    d := IncludeTrailingPathDelimiter(string(pcnd)) + d;
  if not ForceDirectories(d) then exit;
  pcnn := GetOf(d, _name);
  reMDF;
  TrueCur;
  Inside;
  reInfo('cdsfi');
rePDF;
     end;


{============================================================================}
function TPanel.View(sys: boolean): int64;
var
  i: word;
  total, size: int64;
  UserOut: boolean;
  path: string;
 begin
  UserOut := false;
  total := 0;
  size := 0;
  if PanelType = pcPanel then begin
  if not sys then
      if Index > pctdirs then begin
        if InternalView or AltF3Pressed then begin
          path := IncludeTrailingPathDelimiter(string(pcnd))
            + TrueName(Index);
          IntView(path);
          GlobalRedraw;
   end;
        View := 0;
        exit;
   end;
    if Insed = 0 then begin
      path := TrueName(Index);
      if nospace(path) = '..' then
        path := string(pcnd)
       else
        path := IncludeTrailingPathDelimiter(string(pcnd))
          + path;
      if DirSize(path, pcDir^[Index].priory,
                 size, UserOut, sys) then
        if sys then
          Inc(total, size)
        else
          pcDir^[Index].flength := size;
    end;
    for i := 1 to pctdirs + pctfiles do
      if pcDir^[i].mark then begin
        if sys then
          if UserOut then break;
        if DirSize(
             IncludeTrailingPathDelimiter(string(pcnd))
               + TrueName(i),
             pcDir^[i].priory, size,
             UserOut, sys) then
          if sys then
            Inc(total, size)
          else
            pcDir^[i].flength := size;
   end;
    View := total;
  reInfo('s');
  end else begin
    View := 0;
     end;
   end;





{============================================================================}
procedure TPanel.LocalFind;
var
    a,kb:word;
    fname,t,s:string;
    i:byte;
    fnd:boolean;
label loop,fin;
Begin
 CancelSB;
 w_shadow:=false;
 scPutWin(pal.bkdRama,pal.txtdRama,posx+9,gmaxy-3,posx+32,gmaxy-1);
 cmprint(pal.bkdLabelST,pal.txtdLabelST,posx+11,gmaxy-2,'Find:');
 printself(pal.bkdInputNT,pal.txtdInputNT,posx+18,gmaxy-2,13);
 colour(pal.bkdInputNT,pal.txtdInputNT);
 s:='';

loop:
 cmprint(pal.bkdInputNT,pal.txtdInputNT,posx+18,gmaxy-2,s+space(13-length(s)));
 gotoXY(posx+18+length(nospace(s)),gmaxy-2);
 CurOn;
 UpdateScreen(false);

 kb:=rKey;
 if (kb=_ESC)or(kb=_ENTER)or(kb=_Tab) then goto fin;

 if kb=_HOME then
  begin   from:=1; f:=1;
   Outside; Inside; rePDF; s:='';
  end;

 if chr(lo(kb)) in [#8] then begin
   delete(s,length(s),1);
   from:=1; f:=1;
   Outside; Inside;
   if length(s)>0 then begin
     for a:=1 to tdirs+tfiles do begin
       if PanelType=pcPanel
         then fname:=TrueName(a)
         else fname:=nospaceLR(trdDir^[a].name)+
                     '.'+TRDOSe3(Self,a);
       if length(fname)<length(s) then continue;
       t:=fill(length(fname),'?');
       for i:=1 to length(s) do t[i]:=s[i];
       if wild(fname,t,false) then begin
         inc(f,abs(integer(a)-Index));
         if f>PanelHi*Columns then begin
           inc(from,(f-PanelHi*Columns));
           f:=PanelHi*Columns;
         end;
         Outside; Inside;
         break;
       end;
     end;
   end;
   rePDF;
 end;

 if (chr(lo(kb)) in [#32..#254])and(length(s)<13) then
            begin

   s:=s+chr(lo(kb));
   for a:=Index to tdirs+tfiles do
    begin
     if PanelType=pcPanel
       then fname:=TrueName(a)
       else fname:=nospaceLR(trdDir^[a].name)+'.'+TRDOSe3(Self,a);

     if length(fname)<length(s) then continue;
     t:=fill(length(fname),'?');
     for i:=1 to length(s) do t[i]:=s[i];
     fnd:=false;
     if wild(fname,t,false) then
      begin       inc(f,abs(integer(a)-Index));
       if f>PanelHi*Columns then
        begin
         inc(from,(f-PanelHi*Columns));
         f:=PanelHi*Columns;
            end;
       Outside; Inside;
       rePDF;
       fnd:=true;
       break;
      end;
    end;
   if not fnd then delete(s,length(s),1);
  end;
goto loop;

fin:
 w_shadow:=true;
 CurOff;
 RestScr;
End;



{============================================================================}
Procedure TPanel.Navigate;
Var
  kb: word;
  n: integer;
  s: string;
Begin
reInfo('cbdnsfi');
rePDF;
  while true do begin
Inside;
    cStatusBar(Pal.BkSBarNT, Pal.TxtSBarNT,
               Pal.BkSBarST, Pal.TxtSBarST,
               0, sBar[Lang, PanelType]);
    UpdateScreen(false);

    kb := rKey;

if (kb=kbd.sn_kb1_TAB)or(kb=kbd.sn_kb2_TAB) then
                    begin snKernelExitCode:=9; Exit; end;
if kb=_CtrlEnd then begin snKernelExitCode:=9; Exit; end;

if (kb=kbd.sn_kb1_EXIT)or(kb=kbd.sn_kb2_EXIT) then
                    snDone(false);
if kb=_Esc then     snDone(false);

if (kb=kbd.sn_kb1_CLEAN)or(kb=kbd.sn_kb2_CLEAN) then
                    if place=left then AltCPressed(lp) else AltCPressed(rp);
if (kb=kbd.sn_kb1_PACK)or(kb=kbd.sn_kb2_PACK) then
                    if place=left then AltPPressed(lp) else AltPPressed(rp);
if (kb=kbd.sn_kb1_HHAR)or(kb=kbd.sn_kb2_HHAR) then
                    if place=left then AltRPressed(lp) else AltRPressed(rp);

if (kb=kbd.sn_kb1_TRDOS3)or(kb=kbd.sn_kb2_TRDOS3) then
                    Begin TRDOS3:=not TRDOS3; rePDF; reInfo('c'); End;

    if kb= _AltM then errormessage('Free avail memory: '
      + strr(GetFPCHeapStatus.CurrHeapFree));
    if (kb=kbd.sn_kb1_ABOUT)or(kb=kbd.sn_kb2_ABOUT) then About;

if (kb=kbd.sn_kb1_VIDEO1)or(kb=kbd.sn_kb2_VIDEO1) then
                    AltF10Pressed;
if (kb=kbd.sn_kb1_LPANEL)or(kb=kbd.sn_kb2_LPANEL) then
                    AltF1F2(left);
if (kb=kbd.sn_kb1_RPANEL)or(kb=kbd.sn_kb2_RPANEL) then
                    AltF1F2(right);
if kb= _CtrlHome then AltF1F2(focus);
    if kb= _CtrlBkSlash then begin
      if PanelType = pcPanel then begin
        if treec > 1 then begin
          s := Copy(pcnd, 2, 255);
          n := Pos(PathDelim, s);
          if n > 0 then
            pcnn := Copy(s, 1, n - 1)
          else
            pcnn := s;
        end else
          pcnn := '';
        pcnd := ExtractFileDrive(string(pcnd)) + PathDelim;
        reMDF;
             TrueCur; Inside; reInfo('cdsfi');
            END;
          End;

if (kb=kbd.sn_kb1_INSERT)or(kb=kbd.sn_kb2_INSERT) then
                    Insert;{}
if (kb=PadStar)or(kb=$002A) then Star(false);
if (kb=PadPlus)or(kb=$002B) then Plus(false);
if (kb=PadMinus)or(kb=$002D) then Minus(false);
if kb=  CtrlPadStar then Star(true);
if kb=  CtrlPadPlus then Plus(true);
if kb=  CtrlPadMinus then Minus(true);

if (kb=kbd.sn_kb1_SBYNAME)or(kb=kbd.sn_kb2_SBYNAME) then
                     Begin SortType:=NameType; GlobalSort(255); TrueCur; Inside; rePDF; End;
if (kb=kbd.sn_kb1_SBYEXT)or(kb=kbd.sn_kb2_SBYEXT) then
                     Begin SortType:=ExtType; GlobalSort(255); TrueCur; Inside; rePDF; End;
if (kb=kbd.sn_kb1_SBYLEN)or(kb=kbd.sn_kb2_SBYLEN) then
                     Begin SortType:=LenType; GlobalSort(255); TrueCur; Inside; rePDF; End;
if (kb=kbd.sn_kb1_SBYNON)or(kb=kbd.sn_kb2_SBYNON) then
                     Begin SortType:=NonType; reMDF; GlobalSort(255); TrueCur; Inside; rePDF; End;
if (kb=kbd.sn_kb1_INFO)or(kb=kbd.sn_kb2_INFO) then
                     CtrlLPressed;

if (kb=kbd.sn_kb1_REREAD)or(kb=kbd.sn_kb2_REREAD) then
                     begin
                      reMDF; reInfo('cdnsfi');
                      reTrueCur;
                      reInside;
                      rePDF;
                     end;

if kb= _F3 then      View(false);
if kb= _AltF3 then   Begin AltF3Pressed:=true; View(false); AltF3Pressed:=false; End;
if kb= _F4 then      Edit;{}
if kb= _F5 then      Begin AltF5Pressed:=false; fCopy; End;
if kb= _AltF5 then   Begin AltF5Pressed:=true; fCopy; AltF5Pressed:=false; End;
if kb= _F6 then      fMove;
if kb= _AltF6 then   Rename;
if kb= _ShF6 then    hobRename;
if kb= _F7 then      Begin
           Case PanelType of
              pcPanel:  MkDir;
              trdPanel: trdMove(Self);
              fdiPanel: fdiMove(Self);
              fddPanel: fddMove(Self);
           End;
          End;

if (kb=kbd.sn_kb1_LFIND)or(kb=kbd.sn_kb2_LFIND) then
                     LocalFind;
if (kb=kbd.sn_kb1_GFIND)or(kb=kbd.sn_kb2_GFIND) then
                     GlobalFind;

if kb= _F8 then      Del;
if kb= _Del then     begin if Del_F8 then Del; end;

if kb= _F9 then      Begin
           Case PanelType of
              pcPanel:  MakeImages(Self);
            trdPanel: trdLabel;
            fdiPanel: fdiLabel;
            fddPanel: fddLabel;
          End;
          End;

if kb= _Up then Dec(f);
if kb= _Down then Inc(f);
if kb= _Left then Dec(f,PanelHi);
if kb= _Right then Inc(f,PanelHi);
if kb= _PgUp then Dec(f,PanelHi*Columns-1);
if kb= _PgDn then Inc(f,PanelHi*Columns-1);
if kb= _Home then begin from:=1; f:=1; end;
if kb= _End then begin
              f:=Columns*PanelHi;
           from:=tdirs+tfiles-Columns*PanelHi+1;
          End;

if kb= _Enter then Enter;


if kb= _CtrlPgUp then CtrlPgUp;
if kb= _BkSp     then CtrlPgUp;
if kb= _CtrlPgDn then CtrlPgDn;
if kb= _Space then begin Insert; kb:=0; end;

    if (kb=kbd.sn_kb1_PCOLUMNS) or
       (kb=kbd.sn_kb2_PCOLUMNS) then begin
      if Columns >= 3 then Columns := 1
      else Inc(Columns);
      Outside;
      Build('012d');
      Inside;
      rePDF;
    end;

    if tdirs + tfiles > Columns * PanelHi then
      n := Columns * PanelHi
    else
      n := tdirs + tfiles;
    if n < 1 then n := 1;
    if f > n then begin Inc(from, f - n); f := n; end;
    if f < 1 then begin Dec(from, 1 - f); f := 1; end;
    if from > tdirs + tfiles - Columns * PanelHi + 1 then
      from := tdirs + tfiles - Columns * PanelHi + 1;
    if from < 1 then from := 1;

Outside;
Info('bn');
PDF;
  end;
End;


Begin
lp.posx:=1; rp.posx:=GmaxX div 2+1;
lp.posy:=1; rp.posy:=1;

lp.Columns:=3; rp.Columns:=3;
lp.InfoLines:=3; rp.InfoLines:=3;

lp.NameLine:=true; rp.NameLine:=true;

lp.PanelType:=pcPanel; rp.PanelType:=pcPanel;
lp.SortType:=extType; rp.SortType:=extType;

lp.focused:=false;
rp.focused:=false;

lp.f:=1; lp.from:=1;
rp.f:=1; rp.from:=1;

lp.pcf:=1; lp.pcfrom:=1;
rp.pcf:=1; rp.pcfrom:=1;

lp.Place:=left;
rp.Place:=right;
End.Begin
lp.posx:=1; rp.posx:=GmaxX div 2+1;
lp.posy:=1; rp.posy:=1;

lp.Columns:=3; rp.Columns:=3;
lp.InfoLines:=3; rp.InfoLines:=3;

lp.NameLine:=true; rp.NameLine:=true;

lp.PanelType:=pcPanel; rp.PanelType:=pcPanel;
lp.SortType:=extType; rp.SortType:=extType;

lp.focused:=false;
rp.focused:=false;

lp.f:=1; lp.from:=1;
rp.f:=1; rp.from:=1;

lp.pcf:=1; lp.pcfrom:=1;
rp.pcf:=1; rp.pcfrom:=1;

lp.Place:=left;
rp.Place:=right;
End.