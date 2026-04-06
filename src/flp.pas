{$O+,F+}
Unit FLP;
Interface
Uses
     crt,RV,sn_Obj, Vars, Palette, TRD, main, trdos;

function  flpNameLine(var p:TPanel; a:word):string;
function  isFLP(What:char):boolean;
procedure flpMDF(var p:TPanel; What:char);
procedure flpPDF(var p:TPanel; fr:integer);


Implementation


{============================================================================}
function  flpNameLine(var p:TPanel; a:word):string;
var nm,stemp:string;
Begin
           p.flpnn:=p.trddir^[a].name+'.'+TRDOSe31(p,a);
           nm:=p.trddir^[a].name+' '+TRDOSe3(p,a);
           stemp:=extnum(strr(p.trddir^[a].start)); stemp:=changechar(stemp,' ',',');
           nm:=nm+space(9-length(stemp))+stemp;

           stemp:=extnum(strr(p.trddir^[a].length)); stemp:=changechar(stemp,' ',',');
           nm:=nm+space(9-length(stemp))+stemp;

           stemp:=strr(p.trddir^[a].totalsec);
           stemp:='('+space(4-length(stemp))+stemp+')';

           nm:=nm+space(8-length(stemp))+stemp;
flpNameLine:=nm;
End;


{============================================================================}
function  isFLP(What:char):boolean;
var ff:file; s:string; i:integer; b:byte;
Begin
{isFLP:=true; exit;{}
isFLP:=false;
if (What<>'A')and(What<>'B') then exit;
Colour(7,0); sPutWin(25,halfmaxy-4,55,halfmaxy+0);
cmCentre(7,0,halfmaxy-2,'Wait, detecting media...');
if not InitFDD(Ord(UpCase(What))-Ord('A'),CheckMedia{})
then begin restscr; errormessage('TR-DOS sector not found'); exit; end;
restscr;
isFLP:=true;
Colour(7,0); sPutWin(22,halfmaxy-4,59,halfmaxy+0);
cmCentre(7,0,halfmaxy-2,'Reading information sector...');
zxSeek(Ord(UpCase(What))-Ord('A'),0);{}
ReadSector(Ord(UpCase(What))-Ord('A'),0,0,9,1);
if IOError<>0 then begin isFLP:=false; errormessage(ErrorStr(IOError)); end;
if not (FDCBuf[$e7] in [$10]) then begin isFLP:=false; errormessage('No TR-DOS'); end;
restscr;
End;




{============================================================================}
procedure flpMDF(var p:TPanel; What:char);
var ff:file; buf:array[1..8] of byte; indx:longint;
    sec,n:byte; s:string; FoundFiles,ffile,k,i,trdinsed:integer;
begin
if (What<>'A')and(What<>'B') then exit;

Colour(7,0); sPutWin(22,halfmaxy-4,59,halfmaxy+0);
cmCentre(7,0,halfmaxy-2,'Wait, reading disk information...');
if not InitFDD(Ord(UpCase(What))-Ord('A'),CheckMedia)
then begin restscr; errormessage('Error while initialization'); exit; end;
{}
k:=0; for i:=1 to p.flptfiles do if p.trdDir^[i].mark then begin inc(k);
p.trdins^[k].crc16:=crc16(p.trddir^[i].name+TRDOSe3(p,i)); end; trdinsed:=k;

zxSeek(Ord(UpCase(What))-Ord('A'),0);
i:=5; n:=255;
repeat
ReadSector(Ord(UpCase(What))-Ord('A'),0,0,9,1);
if FDCBuf[$e7]=$10 then begin n:=0; break; end;
dec(i);
until (i=0);
if n<>0 then
 begin
  errormessage('Error while reading disk information');
p.zxDisk.files      :=0;
p.zxDisk.n1freesec  :=0;
p.zxDisk.ntr1freesec:=0;
p.zxDisk.disktyp    :=0;
p.zxDisk.free       :=0;
p.zxDisk.trdoscode  :=0;
p.zxDisk.delfiles   :=0;
p.zxdisk.disklabel:='ERROR';
  restscr;
  exit;
 end;


p.zxDisk.files      :=FDCBuf[$e4];
p.zxDisk.n1freesec  :=FDCBuf[$e1];
p.zxDisk.ntr1freesec:=FDCBuf[$e2];
p.zxDisk.disktyp    :=FDCBuf[$e3];
p.zxDisk.free       :=FDCBuf[$e5]+256*FDCBuf[$e6];
p.zxDisk.trdoscode  :=FDCBuf[$e7];
p.zxDisk.delfiles   :=FDCBuf[$f4];
s:=''; for i:=1 to 8 do begin s:=s+chr(FDCBuf[$f5+i-1]); end;
p.zxdisk.disklabel:=s;

p.trddir^[1].name:='<<      ';
p.trddir^[1].typ:='-';
p.trddir^[1].start:=0;
p.trddir^[1].length:=0;
p.trddir^[1].totalsec:=0;
p.trddir^[1].n1sec:=0;
p.trddir^[1].n1tr:=0;
p.trddir^[1].mark:=false;

Colour(7,0); sPutWin(22,halfmaxy-4,59,halfmaxy+0);
cmCentre(7,0,halfmaxy-2,'Wait, reading TR-DOS catalogue...');
ffile:=2; FoundFiles:=0;
for sec:=1 to 8 do
 begin
  i:=5;
  repeat
  ReadSector(Ord(UpCase(What))-Ord('A'),0,0,sec,1);
  {message('sec:'+strr(sec)+' try:'+strr(i)+' err: '+errorstr(ioerror));{}
  dec(i);
  if ioerror=0 then break;{}
  until (I=0);

  if IOError<>0 then
   if sec=1 then begin if not Read1stSector(Ord(UpCase(What))-Ord('A'),0,0) then errormessage('Cant read 1st sector'); end
   else errormessage('Error read sector '+strr(sec)+', '+errorstr(ioerror));

  for n:=1 to 16 do
   begin
    if Cat9 then
     BEGIN
      s:=''; for i:=1 to 8 do s:=s+chr(FDCBuf[16*(n-1)+i-1]);
      p.trddir^[ffile].name    :=s+space(8-length(s));
      p.trddir^[ffile].typ     :=chr(FDCBuf[16*(n-1)+9-1]);
      p.trddir^[ffile].start   :=256*FDCBuf[16*(n-1)+11-1]+FDCBuf[16*(n-1)+10-1];
      p.trddir^[ffile].length  :=256*FDCBuf[16*(n-1)+13-1]+FDCBuf[16*(n-1)+12-1];
      p.trddir^[ffile].totalsec:=FDCBuf[16*(n-1)+14-1];
      p.trddir^[ffile].n1sec   :=FDCBuf[16*(n-1)+15-1];
      p.trddir^[ffile].n1tr    :=FDCBuf[16*(n-1)+16-1];
      p.trddir^[ffile].mark    :=false;
      Inc(ffile);
     END
    ELSE
     BEGIN
      if FDCBuf[16*(n-1)]<>0 then
       Begin
        s:=''; for i:=1 to 8 do s:=s+chr(FDCBuf[16*(n-1)+i-1]);
        p.trddir^[ffile].name    :=s+space(8-length(s));
        p.trddir^[ffile].typ     :=chr(FDCBuf[16*(n-1)+9-1]);
        p.trddir^[ffile].start   :=256*FDCBuf[16*(n-1)+11-1]+FDCBuf[16*(n-1)+10-1];
        p.trddir^[ffile].length  :=256*FDCBuf[16*(n-1)+13-1]+FDCBuf[16*(n-1)+12-1];
        p.trddir^[ffile].totalsec:=FDCBuf[16*(n-1)+14-1];
        p.trddir^[ffile].n1sec   :=FDCBuf[16*(n-1)+15-1];
        p.trddir^[ffile].n1tr    :=FDCBuf[16*(n-1)+16-1];
        p.trddir^[ffile].mark    :=false;
        Inc(ffile);
        Inc(FoundFiles);
       End;
     END;
   end;
 end;
restscr;
if not Cat9 then
 BEGIN
  if p.zxDisk.files<>FoundFiles then
   errormessage('Directory size is not equ 9th sector value');
  if p.zxDisk.files>FoundFiles then p.zxDisk.files:=FoundFiles;
 END;

p.flptfiles:=p.zxDisk.files; inc(p.flptfiles);

if IOResult=0 then;

for i:=1 to trdinsed do for k:=1 to p.fddtfiles do
if p.trdIns^[i].crc16=crc16(p.trddir^[k].name+TRDOSe3(p,k)) then p.trdDir^[k].mark:=true;
restscr;
End;





{============================================================================}
procedure flpPDF(var p:TPanel; fr:integer);
var px,py,py0,ph,paper,ink,pp,ii,dx,ddx:byte;
    i,n:integer;
    s,name:string; e:string[3];
Begin

if p.paneltype<>flpPanel then exit;

n:=p.flptfiles;
if n>fr-1+p.panelhi*p.Columns then n:=fr-1+p.panelhi*p.Columns;
px:=p.posx+1; py:=p.putfrom;
Case p.Columns of 1: dx:=13; 2: dx:=19; 3: dx:=13; End;
for i:=fr to n do
 begin
  if (px=21)or(px=61) then ddx:=1 else ddx:=0;
  name:=p.trdDir^[i].name;
  if i=1
    then name:='<<'+space(dx+ddx-3)
    else name:=name+space((dx+ddx-5)-length(name))+' '+TRDOSe3(p,i);

  paper:=pal.bkNT; ink:=pal.txtNT;
  e:=TRDOSe3(p,i);
  col(e,p.trdDir^[i].length,paper,ink);
  if (ord(p.trdDir^[i].name[1])=1)or(ord(p.trdDir^[i].name[1])=0) then begin paper:=pal.bkg4; ink:=pal.txtg4; end;
  if i=1 then begin paper:=pal.bkdir; ink:=pal.txtdir; end;
  pp:=paper; ii:=ink;
  if p.trddir^[i].mark then begin paper:=pal.bkST; ink:=pal.txtST; end;
  if p.focused and(i=p.from+p.f-1) then begin paper:=pal.bkCurNT; ink:=pal.txtCurNT; end;
  if p.focused and(i=p.from+p.f-1)and(p.trddir^[i].mark) then begin paper:=pal.bkCurST; ink:=pal.txtCurST; end;

  if p.trddir^[i].mark then name[(dx+ddx-4)]:=#251;
  cmprint(paper,ink,px,py,name);

  s:=space(25);
  if p.Columns=1 then
   begin
    cmprint(paper,ink,px+13,py,s); cmprint(paper,pal.TxtRama,px+12,py,'│');
   end;

  if ii=paper then ii:=ink;
  PrintSelf(paper,ii,px+(dx+ddx-5),py,1);

  inc(py);
  if py>p.panelhi+p.putfrom-1 then begin py:=p.putfrom; inc(px,dx); end;
 end;

for i:=n+1 to p.panelhi*p.Columns do
 begin
  if (px=21)or(px=61) then ddx:=1 else ddx:=0;
  name:=space(dx+ddx-1);
  cmprint(pal.bkNT,pal.txtNT,px,py,name);
  if p.Columns=1 then
   begin
    cmprint(pal.bkNT,pal.txtNT,px+13,py,space(25)); cmprint(pal.bkRama,pal.TxtRama,px+12,py,'│');
   end;
  inc(py);
  if py>p.panelhi+p.putfrom-1 then begin py:=p.putfrom; inc(px,dx); end;
 end;
End;




Begin
sBar[eng,flpPanel]:='~`Alt+X~` Exit ~` F3~` View ~` F5~` Copy ~` F6~` Rename ~` F7~` Move ~` F8~` Delete ~` F9~` Label ~`';
End.
