{$mode objfpc}{$H+}
Unit pc;
Interface
Uses
     sn_Obj;

function  pcNameLine(var p:TPanel; m:word):string;
Procedure pcInfoPanel(w:byte);
Function  DirSize(path:string; priory:byte; var size:int64; var UserOut:boolean; sys:boolean):boolean;

function PcColumnEntry(const fname, fext: string;
                       dx, ddx: integer): string;

{ Display width of a UTF-8 byte string, in terminal cells. }
function dispWidth(const s: AnsiString): integer;

{ If display width of s exceeds triggerCells, return
  (first leadCells cells) + '...' + (last tailCells cells)
  truncated on grapheme-cluster boundaries.  Otherwise return s
  unchanged.  All measurements are in display cells, not bytes; safe
  for UTF-8 input that contains multi-byte sequences. }
function PathFit(const s: AnsiString;
                 triggerCells, leadCells, tailCells: integer): AnsiString;

{ Pick a path display fitting pw cells for the directory line of the
  PC info panel.  Wide enough for a meaningful lead-...-tail layout
  (pw >= 12) defers to PathFit; tighter panels drop the ellipsis and
  show the trailing path so the user still sees the leaf they are
  in, instead of '...' or an empty string. }
function FitInfoPath(const s: AnsiString; pw: integer): AnsiString;

Implementation
Uses
     SysUtils, UnicodeVideo, graphemebreakproperty, Keyboard, RV,
     Vars, Palette, Main,
     TRD;


{============================================================================}
{ Display width of a UTF-8 byte string, in terminal cells. Each
  grapheme cluster contributes the width of its first codepoint
  (CJK Wide → 2, ASCII/Cyrillic/Latin → 1), so surrogate pairs and
  combining marks are not counted twice. }
function dispWidth(const s: AnsiString): integer;
begin
  result := StringDisplayWidth(UTF8Decode(s));
end;

{ Return prefix of us occupying at most w display cells, on
  cluster boundary. }
function CellPrefix(const us: UnicodeString; w: integer): UnicodeString;
var
  egc: UnicodeString;
  acc, cw: integer;
begin
  acc := 0;
  result := '';
  for egc in TUnicodeStringExtendedGraphemeClustersEnumerator.Create(us) do
  begin
    cw := ExtendedGraphemeClusterDisplayWidth(egc);
    if acc + cw > w then break;
    result := result + egc;
    Inc(acc, cw);
  end;
end;

{ Return suffix of us occupying at most w display cells, on
  cluster boundary. }
function CellSuffix(const us: UnicodeString; w: integer): UnicodeString;
var
  clusters: array of UnicodeString;
  widths: array of integer;
  egc: UnicodeString;
  i, total, n: integer;
begin
  n := 0;
  for egc in TUnicodeStringExtendedGraphemeClustersEnumerator.Create(us) do
  begin
    SetLength(clusters, n + 1);
    SetLength(widths, n + 1);
    clusters[n] := egc;
    widths[n] := ExtendedGraphemeClusterDisplayWidth(egc);
    Inc(n);
  end;
  total := 0;
  i := n - 1;
  while (i >= 0) and (total + widths[i] <= w) do
  begin
    Inc(total, widths[i]);
    Dec(i);
  end;
  result := '';
  for i := i + 1 to n - 1 do
    result := result + clusters[i];
end;

function PathFit(const s: AnsiString;
                 triggerCells, leadCells, tailCells: integer): AnsiString;
var
  us: UnicodeString;
  budget: integer;
begin
  if dispWidth(s) <= triggerCells then
  begin
    PathFit := s;
    exit;
  end;
  if leadCells < 0 then leadCells := 0;
  if tailCells < 0 then tailCells := 0;
  us := UTF8Decode(s);
  { When trigger is too narrow for even "...", drop the ellipsis
    and clip to a plain cell prefix. }
  if triggerCells < 3 then
  begin
    PathFit := UTF8Encode(CellPrefix(us, triggerCells));
    exit;
  end;
  { Cap lead/tail so lead + 3 + tail <= triggerCells.  Lead wins
    when both can't fit; the remainder goes to tail. }
  budget := triggerCells - 3;
  if leadCells + tailCells > budget then
  begin
    if leadCells > budget then leadCells := budget;
    tailCells := budget - leadCells;
  end;
  PathFit := UTF8Encode(CellPrefix(us, leadCells)) + '...' +
             UTF8Encode(CellSuffix(us, tailCells));
end;

function FitInfoPath(const s: AnsiString; pw: integer): AnsiString;
begin
  if pw >= 12 then
    FitInfoPath := PathFit(s, pw - 9, 4, pw - 8)
  else if dispWidth(s) > pw then
    FitInfoPath := UTF8Encode(CellSuffix(UTF8Decode(s), pw))
  else
    FitInfoPath := s;
end;

function pcNameLine(var p:TPanel; m:word):string;
var nm,stemp:string;
begin
         p.pcnn:=p.pcDir^[m].fname;
         if (Length(p.pcnn)>0) and (p.pcnn[1]=' ') then delete(p.pcnn,1,1);
         if nospace(p.pcDir^[m].fext)<>'' then p.pcnn:=p.pcnn+'.'+p.pcDir^[m].fext;
         while dispWidth(p.pcnn)<12 do p.pcnn:=p.pcnn+' ';
         stemp:=extnum(strr(p.pcdir^[m].flength));
         if p.pcdir^[m].flength>9999999 then stemp:=extnum(strr(p.pcdir^[m].flength div 1000))+'K';
         if p.pcdir^[m].flength>999999999 then stemp:=extnum(strr(p.pcdir^[m].flength div 1000000))+'M';
         if (p.pcdir^[m].flength<0) then stemp:='►SUB-DIR◄';
         if (p.pcdir^[m].flength<0)and(nospace(p.pcnn)='..') then stemp:='◄SUB-DIR►';
         stemp:=changechar(stemp,' ',',');
         stemp:=space(10-dispWidth(stemp))+stemp;
         nm:=p.pcnn+' '+stemp;

         stemp:=LZ(p.pcdir^[m].fdt.day)+'-'+LZ(p.pcdir^[m].fdt.month)+'-'+copy(LZ(p.pcdir^[m].fdt.year),3,2);
         nm:=nm+' '+stemp;
         stemp:=LZ(p.pcdir^[m].fdt.hour)+':'+LZ(p.pcdir^[m].fdt.min);
         if stemp[1]='0' then stemp[1]:=' ';
         nm:=nm+' '+stemp;
pcNameLine:=nm;
end;

{============================================================================}
Procedure pcInfoPanel(w:byte);
Var
     s,s0:string; i,m:longint; l:int64;
     posx,posy,panellong,pw:word;
     treec:byte; pcnd:string; pctdirs,pctfiles:word;
     p:TPanel;
Begin
Case w of
 left:
   BEGIN
    posx:=rp.posx;
    posy:=rp.posy;
    panellong:=rp.panellong;
    pw:=rp.PanelW;
    treec:=lp.treec;
    pcnd:=lp.pcnd;
    pctdirs:=lp.pctdirs;
    pctfiles:=lp.pctfiles;
    p:=lp;
   END;
 right:
   BEGIN
    posx:=lp.posx;
    posy:=lp.posy;
    panellong:=lp.panellong;
    pw:=lp.PanelW;
    treec:=rp.treec;
    pcnd:=rp.pcnd;
    pctdirs:=rp.pctdirs;
    pctfiles:=rp.pctfiles;
    p:=rp;
   END;
End;

cmPrint(pal.bkRama,pal.txtRama,posx,posy+PanelLong-2,'║'+space(pw)+'║');
cmPrint(pal.bkRama,pal.txtRama,posx,posy+PanelLong-1,'╚'+fill(pw,'═')+'╝');

InfoLine(pal.bkDiskInfoNT,pal.txtDiskInfoNT,pal.bkDiskInfoST,pal.txtDiskInfoST,
  posx+1,2,'Current directory: ',pw);


s0:=pcnd;
if treec<>1 then s0:=copy(pcnd,1,length(pcnd)-1);
{ Cast pw to integer before passing so a tiny PanelW doesn't
  underflow word arithmetic. }
s0:=FitInfoPath(s0, integer(pw));
s0:='~`'+s0+'~`';
InfoLine(pal.bkDiskInfoNT,pal.txtDiskInfoNT,pal.bkDiskInfoST,pal.txtDiskInfoST,
  posx+1,3,s0,pw);

m:=0;
for i:=1 to pctdirs+pctfiles do
 begin
  if w=left then l:=lp.pcdir^[i].flength else l:=rp.pcdir^[i].flength;
  if w=left then s:=lp.pcdir^[i].fname else s:=rp.pcdir^[i].fname;
  if (l>=0)and(s<>' ..') then inc(m,l);
 end;
if treec=1 then i:=pctdirs+pctfiles else i:=pctdirs+pctfiles-1;
s0:='~`'+strr(i)+'~` file'+efiles(i)+' with ~`'+changechar(extnum(strr(m)),' ',',')+'~` bytes';
InfoLine(pal.bkDiskInfoNT,pal.txtDiskInfoNT,pal.bkDiskInfoST,pal.txtDiskInfoST,
  posx+1,4,s0,pw);

StatusLineColor(pal.bkDiskInfoNT,pal.txtDiskInfoNT,pal.bkDiskInfoST,pal.txtDiskInfoST,posx+1,5,space(pw));

s0:='~`'+changechar(extnum(strr(disksize(0))),' ',',')+'~` total bytes on disk';
InfoLine(pal.bkDiskInfoNT,pal.txtDiskInfoNT,pal.bkDiskInfoST,pal.txtDiskInfoST,
  posx+1,6,s0,pw);

m:=diskfree(0); s:=extnum(strr(m));
if m>999999999 then s:=extnum(strr(m div 1000000))+'G';
s0:='~`'+changechar(s,' ',',')+'~` free bytes on disk';
InfoLine(pal.bkDiskInfoNT,pal.txtDiskInfoNT,pal.bkDiskInfoST,pal.txtDiskInfoST,
  posx+1,7,s0,pw);

for i:=8 to 12 do
  StatusLineColor(pal.bkDiskInfoNT,pal.txtDiskInfoNT,pal.bkDiskInfoST,pal.txtDiskInfoST,posx+1,i,space(pw));

InfoLine(pal.bkDiskInfoNT,pal.txtDiskInfoNT,pal.bkDiskInfoST,pal.txtDiskInfoST,
  posx+1,13,fill(16,'─'),pw);

for i:=14 to 19 do
  StatusLineColor(pal.bkDiskInfoNT,pal.txtDiskInfoNT,pal.bkDiskInfoST,pal.txtDiskInfoST,posx+1,i,space(pw));

i:=0; l:=0;
for m:=pctdirs+1 to pctdirs+pctfiles do
 if p.pcdir^[m].mark then
  begin
   if ithobeta(pcnd+p.pcdir^[m].fname+'.'+p.pcdir^[m].fext, hobetainfo) then
    begin
     inc(i,hobetainfo.totalsec);
     inc(l);
    end;
  end;

if i>0 then
 begin
  InfoLine(pal.bkDiskInfoNT,pal.txtDiskInfoNT,pal.bkDiskInfoST,pal.txtDiskInfoST,
    posx+1,19,fill(16,'─'),pw);
  s0:='~`'+strr(i)+'~` block'+eb(i)+' selected in ~`'+strr(l)+'~` Hob file'+ewfiles(l);
  i:=p.putfrom+p.panelhi+1+(p.InfoLines-2);
  StatusLineColor(pal.bkSelectedNT,pal.txtSelectedNT,pal.bkSelectedST,pal.txtSelectedST,posx+1,i-1,space(pw));
  InfoLine(pal.bkSelectedNT,pal.txtSelectedNT,pal.bkSelectedST,pal.txtSelectedST,
    posx+1,i,s0,pw);
 end
else
 begin
  i:=p.putfrom+p.panelhi+1+(p.InfoLines-2);
  StatusLineColor(pal.bkSelectedNT,pal.txtSelectedNT,pal.bkSelectedST,pal.txtSelectedST,posx+1,i-1,space(pw));
  StatusLineColor(pal.bkSelectedNT,pal.txtSelectedNT,pal.bkSelectedST,pal.txtSelectedST,posx+1,i,space(pw));
 end;
End;






{============================================================================}
function PcColumnEntry(const fname, fext: string;
                       dx, ddx: integer): string;
Var
  baseU, fitU, egc: UnicodeString;
  base, ext3: string;
  padTo, cw, fitW: integer;
 begin
  baseU := UTF8Decode(fname);
  if (Length(baseU) > 0) and (baseU[1] = ' ') then
    Delete(baseU, 1, 1);
  padTo := dx + integer(ddx) - 5;
  if padTo < 0 then padTo := 0;
  { Truncate to fit padTo display columns. Iterate by grapheme
    cluster so surrogate pairs (astral emoji) and modifier
    sequences (skin-tone, ZWJ) are admitted or rejected as one
    unit, never split mid-cluster. }
  fitW := 0; fitU := '';
  for egc in TUnicodeStringExtendedGraphemeClustersEnumerator.Create(baseU) do
  begin
    cw := ExtendedGraphemeClusterDisplayWidth(egc);
    if fitW + cw > padTo then break;
    fitU := fitU + egc;
    Inc(fitW, cw);
  end;
  while fitW < padTo do
  begin
    fitU := fitU + ' ';
    Inc(fitW);
  end;
  base := UTF8Encode(fitU);
  ext3 := Copy(fext, 1, 3);
  while Length(ext3) < 3 do ext3 := ext3 + ' ';
  PcColumnEntry := base + ' ' + ext3;
 end;

{============================================================================}
function DirSize(path: string; priory: byte;
                 var size: int64;
                 var UserOut: boolean;
                 sys: boolean): boolean;

  procedure FileScan(const scanPath: string);
Var
    sr: TUnicodeSearchRec;
    ke: TKeyEvent;
   begin
    if FindFirst(UnicodeString(IncludeTrailingPathDelimiter(scanPath))
                 + '*', faAnyFile, sr) = 0 then begin
      repeat
        if not sys then begin
          ke := PollKeyEvent;
          if ke <> 0 then begin
            ke := GetKeyEvent;
            if GetKeyEventChar(ke) = #27 then
              UserOut := true;
   end;
   end;
   if UserOut then break;
        {$push}{$warnings off}
        if (sr.Attr and (faDirectory or faVolumeId)) = 0 then
        {$pop}
          Inc(size, sr.Size);
      until FindNext(sr) <> 0;
      SysUtils.FindClose(sr);
  end;
end;

  procedure DirScan(const scanPath: string);
  var
    sr: TUnicodeSearchRec;
    ke: TKeyEvent;
    begin
    if FindFirst(UnicodeString(IncludeTrailingPathDelimiter(scanPath))
                 + '*', faAnyFile, sr) = 0 then begin
      repeat
        if ((sr.Attr and faDirectory) = faDirectory) and
           (sr.Name <> '.') and (sr.Name <> '..') then begin
          if not sys then begin
            ke := PollKeyEvent;
            if ke <> 0 then begin
              ke := GetKeyEvent;
              if GetKeyEventChar(ke) = #27 then
                UserOut := true;
  end;
end;
     if UserOut then break;
          DirScan(IncludeTrailingPathDelimiter(scanPath)
                  + UTF8Encode(sr.Name));
          FileScan(IncludeTrailingPathDelimiter(scanPath)
                   + UTF8Encode(sr.Name));
    end;
      until FindNext(sr) <> 0;
      SysUtils.FindClose(sr);
  end;
end;

 begin
  UserOut := false;
  DirSize := true;
  size := 0;
  if priory = 0 then begin
  DirScan(path);
  FileScan(path);
  end else
    size := FileLen(path);
  if UserOut then
    DirSize := false;
End;



initialization

sBar[eng,pcPanel]:='~`Alt+X~` Exit  ~`F3~` View  ~`F5~` Copy  ~`F6~` Rename/Move  ~`F7~` MkDir  ~`F8~` Delete  ~`F9~` New';
lp.pcfrom:=1; lp.pcf:=1;
rp.pcfrom:=1; rp.pcf:=1;

End.