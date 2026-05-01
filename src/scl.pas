Unit SCL;
{$mode objfpc}{$H+}
Interface
Uses
     RV,sn_Obj, Vars, Palette, Main, TRD;

function  sclNameLine(var p:TPanel; a:word):string;
Function  isSCL(path:string):boolean;
Procedure sclMDF(var p:TPanel; path:string);
Procedure sclPDF(var p:TPanel; fr:integer);

Implementation
Uses
     Video;

{============================================================================}
function sclNameLine(var p:TPanel; a:word):string;
var nm,stemp:string;
begin
           p.sclnn:=p.trddir^[a].name+'.'+TRDOSe31(p,a);
           nm:=p.trddir^[a].name+' '+TRDOSe3(p,a);
           stemp:=extnum(strr(p.trddir^[a].start)); stemp:=changechar(stemp,' ',',');
           nm:=nm+space(9-length(stemp))+stemp;

           stemp:=extnum(strr(p.trddir^[a].length)); stemp:=changechar(stemp,' ',',');
           nm:=nm+space(9-length(stemp))+stemp;

           stemp:=strr(p.trddir^[a].totalsec);
           stemp:='('+space(4-length(stemp))+stemp+')';

           nm:=nm+space(8-length(stemp))+stemp;
sclNameLine:=nm;
end;


{============================================================================}
Function isSCL(path:string):boolean;
var
    ff:file;
    s:string;
    w,nr:word;
    buf:array[1..8] of byte;
Begin
isSCL:=false;
nr:=0;
for w:=1 to 8 do buf[w]:=0;
{$I-}
filemode := fmReadShared; assign(ff,path); reset(ff,1);
if ioresult<>0 then Exit;
BlockRead(ff,buf,8,nr);
if ioresult<>0 then; Close(ff);
{$I+}
if ioresult<>0 then Exit;
if nr<>8 then Exit;
s:=''; for w:=1 to 8 do s:=s+chr(buf[w]);
if s='SINCLAIR' then isSCL:=true;
end;




{============================================================================}
Procedure sclMDF(var p:TPanel; path:string);
var
    fb:file of byte;
    i,k,trdinsed:integer;
    buf:array[1..16] of byte;
    s:string[8];
    b:byte;
begin
// message(strr(checkdirfile(path))+' '+path);
if (checkdirfile(path)<>0)or(not isSCL(path)) then
 begin
  p.PanelType:=pcPanel;
  p.pcMDF(p.pcnd);
  p.Inside;
  Exit;
 end;

{$I-}
k:=0; for i:=1 to p.scltfiles do if p.trdDir^[i].mark then begin inc(k);
p.trdins^[k].crc16:=crc16(p.trddir^[i].name+TRDOSe3(p,i)); end; trdinsed:=k;

filemode := fmReadShared;
assign(fb,path); reset(fb);

seek(fb,$8); read(fb,b); p.scltfiles:=b;
p.zxdisk.files:=p.scltfiles; inc(p.scltfiles);
p.zxdisk.n1freesec:=0;
p.zxdisk.ntr1freesec:=0;
p.zxdisk.disktyp:=0;
p.zxdisk.free:=0;
p.zxdisk.trdoscode:=16;
p.zxdisk.delfiles:=0;
p.zxdisk.disklabel:='Hobeta98';

p.trddir^[1].name:='<<      ';
p.trddir^[1].typ:='-';
p.trddir^[1].start:=0;
p.trddir^[1].length:=0;
p.trddir^[1].totalsec:=0;
p.trddir^[1].n1sec:=0;
p.trddir^[1].n1tr:=0;
p.trddir^[1].mark:=false;

for i:=1 to p.scltfiles do
 begin
  seek(fb,9+14*(i-1));
  for k:=0 to 13 do read(fb,buf[k+1]);
  s:='';
  for k:=1 to 8 do s:=s+chr(buf[k]);
  p.trddir^[i+1].name:=s;
  p.trddir^[i+1].typ:=chr(buf[9]);
  p.trddir^[i+1].start:=buf[10]+256*buf[11];
  p.trddir^[i+1].length:=buf[12]+256*buf[13];
  p.trddir^[i+1].totalsec:=buf[14];
  p.trddir^[i+1].n1sec:=0;
  p.trddir^[i+1].n1tr:=0;
  p.trddir^[i+1].mark:=false;
 end;

(* Clear stale InOutRes from any in-loop read that ran past EOF —
   under I-suppressed scope, FPC's Close becomes a no-op when
   InOutRes is non-zero on entry, leaking the file descriptor. *)
if ioresult<>0 then;
close(fb);
{$I+}
if ioresult<>0 then;

for i:=1 to trdinsed do for k:=1 to p.scltfiles do
if p.trdIns^[i].crc16=crc16(p.trddir^[k].name+TRDOSe3(p,k)) then p.trdDir^[k].mark:=true;
End;



{============================================================================}
Procedure sclPDF(var p:TPanel; fr:integer);
var paper,ink,ii:byte;
    px,py,dx,ddx:word;
    i,n:integer;
    name:string; e:string[3];
Begin

if p.paneltype<>sclPanel then exit;

n:=p.scltfiles;
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
End;








initialization
sBar[eng,sclPanel]:='~`Alt+X~` Exit ~` F3~` View ~` F5~` Copy ~` F6~` Rename ~` F8~` Delete ';
End.
