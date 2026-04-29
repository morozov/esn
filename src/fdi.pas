Unit FDI;
{$mode objfpc}{$H+}
Interface
Uses
     RV,sn_Obj, Vars, Palette, Main, TRD, Main_Ovr;

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


function  fdiNameLine(var p:TPanel; a:word):string;

function  isFDI(var p:TPanel; path:string):boolean;

procedure fdiMDF(var p:TPanel; path:string);
procedure fdiPDF(var p:TPanel; fr:integer);

{ Absolute byte offset in the FDI file of the first byte of sector
  (tr, sc), where tr = cyl*2 + head (0..159) and sc = sec_id - 1
  (0..15). The returned offset honours each sector's physical position
  as recorded in the FDI per-track header, so it is correct even for
  disks with rotational skew or non-linear sector layout. }
function  fdiSecAbs(var p:TPanel; tr,sc:byte):longint;

{ Absolute byte offset in the FDI file of `byteInTrack0` within
  cyl 0/head 0. Maps the byte to (sec_id, offset_in_sector) and looks
  the sector up via fdiSecAbs, so it is correct even when track 0 has
  shuffled sectors. }
function  fdiTrk0Abs(var p:TPanel; byteInTrack0:longint):longint;

{ Read `nsec` consecutive logical sectors starting at (tr, sc) into
  `buf` (which must have room for nsec*256 bytes). Walks the per-sector
  physical offsets, so works on FDIs with arbitrary layout. }
procedure fdiReadSectors(var f:file; var p:TPanel;
                         tr,sc:byte; nsec:word; var buf);

{ Mirror of fdiReadSectors for writes. }
procedure fdiWriteSectors(var f:file; var p:TPanel;
                          tr,sc:byte; nsec:word; const buf);

Implementation

Uses
     Video;

{============================================================================}
function fdiNameLine(var p:TPanel; a:word):string;
var nm,stemp:string;
begin
           p.fdinn:=p.trddir^[a].name+'.'+TRDOSe31(p,a);
           nm:=p.trddir^[a].name+' '+TRDOSe3(p,a);
           stemp:=extnum(strr(p.trddir^[a].start)); stemp:=changechar(stemp,' ',',');
           nm:=nm+space(9-length(stemp))+stemp;

           stemp:=extnum(strr(p.trddir^[a].length)); stemp:=changechar(stemp,' ',',');
           nm:=nm+space(9-length(stemp))+stemp;

           stemp:=strr(p.trddir^[a].totalsec);
           stemp:='('+space(4-length(stemp))+stemp+')';

           nm:=nm+space(8-length(stemp))+stemp;
fdiNameLine:=nm;
end;





type TFdiByteFile = file of byte;

{============================================================================}
{ Walk the FDI per-track headers, populate p.fdiSecOff^ with the
  absolute file offset of each sector. fb must already be open and
  p.fdiRec must already be filled in. }
procedure fdiBuildSecOff(var p:TPanel; var fb:TFdiByteFile);
var i,cyl,head,nsec,sec_id,size_code,sz:integer;
    tr:integer;
    pos,trackOff,offInTrack,bb:longint;
    a,b,c,d:byte;
begin
  if p.fdiSecOff=nil then exit;
  { Default everything to bpos-equivalent so missing tracks/sectors
    still produce sensible offsets if the FDI is malformed. }
  for i:=0 to FdiMaxSectors-1 do
    p.fdiSecOff^[i]:=longint(p.fdiRec.offData)
                    +(i div FdiSecsPerTrack)*4096
                    +(i mod FdiSecsPerTrack)*256;
  pos:=p.fdiRec.offHeaderCyl;
  {$I-}
  seek(fb,pos);
  for cyl:=0 to p.fdiRec.cyl-1 do
   for head:=0 to p.fdiRec.heads-1 do
    begin
      read(fb,a); read(fb,b); read(fb,c); read(fb,d);
      trackOff:=longint(a)+longint(b)shl 8
               +longint(c)shl 16+longint(d)shl 24;
      read(fb,a); read(fb,b); read(fb,a); nsec:=a;
      tr:=cyl*2+head;
      for i:=0 to nsec-1 do
        begin
          read(fb,a); read(fb,b); read(fb,a); sec_id:=a;
          read(fb,a); size_code:=a;
          read(fb,a);                       { flags — ignored }
          read(fb,a); read(fb,b);
          offInTrack:=longint(a)+longint(b)shl 8;
          sz:=128 shl size_code;
          if (tr<FdiMaxTracks)
             and (sec_id>=1) and (sec_id<=FdiSecsPerTrack)
             and (sz=256) then
            begin
              bb:=longint(p.fdiRec.offData)+trackOff+offInTrack;
              p.fdiSecOff^[tr*FdiSecsPerTrack+(sec_id-1)]:=bb;
            end;
        end;
    end;
  if ioresult<>0 then;
  {$I+}
end;

{============================================================================}
function isFDI(var p:TPanel; path:string):boolean;
var fb:file of byte;
    a,b:byte;
    s:string;
label fin,fin2;
begin
isFDI:=false;
{$I-}
filemode := fmReadShared;
assign(fb,path); reset(fb);

seek(fb,0); s:='';
read(fb,b); s:=s+chr(b); read(fb,b); s:=s+chr(b); read(fb,b); s:=s+chr(b);
if s<>'FDI' then goto fin;

read(fb,a); p.fdiRec.flag:=a;{3}
read(fb,a); read(fb,b); {4} p.fdiRec.cyl:=a+256*b;
read(fb,a); read(fb,b); {6} p.fdiRec.heads:=a+256*b;
read(fb,a); read(fb,b); {8} p.fdiRec.offText:=a+256*b;
read(fb,a); read(fb,b); {A} p.fdiRec.offData:=a+256*b;
read(fb,a); read(fb,b); {C} p.fdiRec.extDataLenHeader:=a+256*b;
read(fb,a); read(fb,b); {E} p.fdiRec.extDataLen:=a+256*b;
p.fdiRec.offHeaderCyl:=$E+p.fdiRec.extDataLen;

if p.fdiRec.heads<>2 then goto fin;

fdiBuildSecOff(p,fb);
seek(fb,fdiTrk0Abs(p,$8e7)); read(fb,b);
if not (b in [$10]) then goto fin;
isFDI:=true;
fin:
if ioresult<>0 then; close(fb);
{$I+}
fin2:
if ioresult<>0 then;
end;

{============================================================================}
function fdiSecAbs(var p:TPanel; tr,sc:byte):longint;
begin
  if (p.fdiSecOff<>nil)
     and (tr<FdiMaxTracks) and (sc<FdiSecsPerTrack) then
    fdiSecAbs:=p.fdiSecOff^[tr*FdiSecsPerTrack+sc]
  else
    fdiSecAbs:=longint(p.fdiRec.offData)+longint(tr)*4096+longint(sc)*256;
end;

{============================================================================}
function fdiTrk0Abs(var p:TPanel; byteInTrack0:longint):longint;
var sc:byte; offInSec:longint;
begin
  sc:=byteInTrack0 div 256;
  offInSec:=byteInTrack0 mod 256;
  fdiTrk0Abs:=fdiSecAbs(p,0,sc)+offInSec;
end;

{============================================================================}
(* I/O suppression on the seek/blockread is required: the helper is
   invoked from fdi_ovr.pas inside its own I-suppressed block, but the
   I/O directive is per-unit at compile time and does not carry across
   the call. Without this, a malformed FDI with sector offsets past
   EOF raises EInOutError instead of setting IOResult, propagating out
   of the caller's error path. *)
procedure fdiReadSectors(var f:file; var p:TPanel;
                         tr,sc:byte; nsec:word; var buf);
var i:word; cur_tr,cur_sc:byte; dst:pbyte; nr:word;
begin
  dst:=@buf; nr:=0;
  cur_tr:=tr; cur_sc:=sc;
  {$I-}
  for i:=1 to nsec do
    begin
      seek(f,fdiSecAbs(p,cur_tr,cur_sc));
      blockread(f,dst^,256,nr);
      inc(dst,256);
      inc(cur_sc);
      if cur_sc>=FdiSecsPerTrack then begin cur_sc:=0; inc(cur_tr); end;
    end;
  if ioresult<>0 then;
  {$I+}
end;

{============================================================================}
procedure fdiWriteSectors(var f:file; var p:TPanel;
                          tr,sc:byte; nsec:word; const buf);
var i:word; cur_tr,cur_sc:byte; src:pbyte; nw:word;
begin
  src:=pbyte(@buf); nw:=0;
  cur_tr:=tr; cur_sc:=sc;
  {$I-}
  for i:=1 to nsec do
    begin
      seek(f,fdiSecAbs(p,cur_tr,cur_sc));
      blockwrite(f,src^,256,nw);
      inc(src,256);
      inc(cur_sc);
      if cur_sc>=FdiSecsPerTrack then begin cur_sc:=0; inc(cur_tr); end;
    end;
  if ioresult<>0 then;
  {$I+}
end;
{============================================================================}
{============================================================================}
{============================================================================}
{============================================================================}
{============================================================================}
{============================================================================}



{============================================================================}
procedure fdiMDF(var p:TPanel; path:string);
var
    fb:file of byte;
    FoundFiles,i,k,trdinsed:integer;
    buf:array[1..16] of byte;
    s:string[8];
    b,b2:byte;
    stemp:string;
begin
if (checkdirfile(path)<>0)or(not isFDI(p,path)) then
 begin
  p.PanelType:=pcPanel;
  p.pcMDF(p.pcnd);
  p.Inside;
  Exit;
 end;

k:=0; for i:=1 to p.fditfiles do if p.trdDir^[i].mark then begin inc(k);
p.trdins^[k].crc16:=crc16(p.trddir^[i].name+TRDOSe3(p,i)); end; trdinsed:=k;

{$I-}
filemode := fmReadShared;
assign(fb,path); reset(fb);
seek(fb,4); read(fb,b); p.zxdisk.tracks:=b;

seek(fb,fdiTrk0Abs(p,$8e1)); read(fb,b); p.zxdisk.n1freesec:=b;
seek(fb,fdiTrk0Abs(p,$8e2)); read(fb,b); p.zxdisk.ntr1freesec:=b;
seek(fb,fdiTrk0Abs(p,$8e3)); read(fb,b); p.zxdisk.disktyp:=b;
seek(fb,fdiTrk0Abs(p,$8e4)); read(fb,b); p.zxdisk.files:=b;
seek(fb,fdiTrk0Abs(p,$8e5)); read(fb,b); read(fb,b2); p.zxdisk.free:=b+256*b2;
seek(fb,fdiTrk0Abs(p,$8e7)); read(fb,b); p.zxdisk.trdoscode:=b;
seek(fb,fdiTrk0Abs(p,$8f4)); read(fb,b); p.zxdisk.delfiles:=b;
seek(fb,fdiTrk0Abs(p,$8f5)); stemp:=''; for i:=1 to 8 do begin read(fb,b); stemp:=stemp+chr(b); end;
p.zxdisk.disklabel:=stemp;

p.trddir^[1].name:='<<      ';
p.trddir^[1].typ:='-';
p.trddir^[1].start:=0;
p.trddir^[1].length:=0;
p.trddir^[1].totalsec:=0;
p.trddir^[1].n1sec:=0;
p.trddir^[1].n1tr:=0;
p.trddir^[1].mark:=false;

if Cat9 then
BEGIN
for i:=1 to p.zxDisk.files do
 begin
  seek(fb,fdiTrk0Abs(p,16*(i-1)));
  for k:=0 to 15 do read(fb,buf[k+1]);
  s:=''; for k:=1 to 8 do s:=s+chr(buf[k]);
  p.trddir^[i+1].name:=s;
  p.trddir^[i+1].typ:=chr(buf[9]);
  p.trddir^[i+1].start:=buf[10]+256*buf[11];
  p.trddir^[i+1].length:=buf[12]+256*buf[13];
  p.trddir^[i+1].totalsec:=buf[14];
  p.trddir^[i+1].n1sec:=buf[15];
  p.trddir^[i+1].n1tr:=buf[16];
  p.trddir^[i+1].mark:=false;
 end;
END
ELSE
BEGIN
FoundFiles:=0; i:=1;
While i<=128 do
 begin
  seek(fb,fdiTrk0Abs(p,16*(i-1)));
  for k:=0 to 15 do read(fb,buf[k+1]);
  if buf[1]<>0 then
   Begin
    s:=''; for k:=1 to 8 do s:=s+chr(buf[k]);
    p.trddir^[i+1].name:=s;
    p.trddir^[i+1].typ:=chr(buf[9]);
    p.trddir^[i+1].start:=buf[10]+256*buf[11];
    p.trddir^[i+1].length:=buf[12]+256*buf[13];
    p.trddir^[i+1].totalsec:=buf[14];
    p.trddir^[i+1].n1sec:=buf[15];
    p.trddir^[i+1].n1tr:=buf[16];
    p.trddir^[i+1].mark:=false;
    Inc(FoundFiles);
   End else Break;
   inc(i);
 end;
if p.zxDisk.files<>FoundFiles then
 errormessage('Directory size is not equ 9th sector value');
if p.zxDisk.files>FoundFiles then p.zxDisk.files:=FoundFiles;
END;

p.fditfiles:=p.zxdisk.files; inc(p.fditfiles);

if ioresult<>0 then; close(fb);
{$I+}
if ioresult<>0 then;

for i:=1 to trdinsed do for k:=1 to p.fditfiles do
if p.trdIns^[i].crc16=crc16(p.trddir^[k].name+TRDOSe3(p,k)) then p.trdDir^[k].mark:=true;
end;



{============================================================================}
procedure fdiPDF(var p:TPanel; fr:integer);
var paper,ink,ii:byte;
    px,py,dx,ddx:word;
    i,n:integer;
    name:string; e:string[3];
begin

if p.paneltype<>fdiPanel then exit;

n:=p.fditfiles;

if n>fr-1+p.panelhi*3 then n:=fr-1+p.panelhi*3;
px:=p.posx+1; py:=p.putfrom;
dx:=(p.PanelW+1) div 3;
for i:=fr to n do
 begin
  ddx:=0;
  name:=p.trdDir^[i].name;
  if i=1
    then name:='<<'+space(dx+ddx-3)
    else name:=name+space((dx+ddx-5)-length(name))+' '+TRDOSe3(p,i);

  paper:=pal.bkNT; ink:=pal.txtNT;
  e:=TRDOSe3(p,i);
  col(e,p.trdDir^[i].length,paper,ink);
  if (ord(p.trdDir^[i].name[1])=1)or(ord(p.trdDir^[i].name[1])=0) then begin paper:=pal.bkg4; ink:=pal.txtg4; end;
  if i=1 then begin paper:=pal.bkdir; ink:=pal.txtdir; end;
  ii:=ink;
  if p.trddir^[i].mark then begin paper:=pal.bkST; ink:=pal.txtST; end;

  if p.focused and(i=p.from+p.f-1) then begin paper:=pal.bkCurNT; ink:=pal.txtCurNT; end;
  if p.focused and(i=p.from+p.f-1)and(p.trddir^[i].mark) then begin paper:=pal.bkCurST; ink:=pal.txtCurST; end;

  cmprint(paper,ink,px,py,name);
  if p.trddir^[i].mark then
    cmprint(paper, ink, px + dx + ddx - 5, py, '√');


  if ii=paper then ii:=ink;
  PrintSelf(paper,ii,px+(dx+ddx-5),py,1);

  inc(py);
  if py>p.panelhi+p.putfrom-1 then begin py:=p.putfrom; inc(px,dx); end;
 end;

for i:=n+1 to fr-1+p.panelhi*3 do
 begin
  ddx:=0;
  name:=space(dx+ddx-1);
  cmprint(pal.bkNT,pal.txtNT,px,py,name);
  inc(py);
  if py>p.panelhi+p.putfrom-1 then begin py:=p.putfrom; inc(px,dx); end;
 end;




UpdateScreen(false);
end;







Begin
sBar[eng,fdiPanel]:='~`Alt+X~` Exit ~` F3~` View ~` F5~` Copy ~` F6~` Rename ~` F7~` Move ~` F8~` Delete ~` F9~` Label ~`';
End.
