{$O+,F+}
Unit FLP_Ovr;
Interface
Uses
     RV,sn_Obj, Vars, Palette, Main, Main_Ovr,PC,PC_Ovr,FLP,TRD_Ovr,TRD;

Function  flpLoad(var p:TPanel; ind:word; What:char):boolean;
Function  flpSave(var p:TPanel; What:char):boolean;
function  flpDel(var p:TPanel; What:char):boolean;
function  flpRename(What:char):boolean;
function  flpLabel(What:char):boolean;
function  flpMove(var p:Tpanel; What:char):boolean;


Implementation

Uses trdos, mouse;

{============================================================================}
Function flpLoad(var p:TPanel; ind:word; What:char):boolean;
Var
    bufpos,i,k:word; t,s, t_old,t_,s_,h_:byte;
Begin
HobetaInfo.name:=p.trdDir^[ind].name;
HobetaInfo.typ:=p.trdDir^[ind].typ;
HobetaInfo.start:=p.trdDir^[ind].start;
HobetaInfo.length:=p.trdDir^[ind].length;
HobetaInfo.param2:=p.trdDir^[ind].length;
if HobetaInfo.typ<>'B' then HobetaInfo.param2:=32768;
HobetaInfo.totalsec:=p.trdDir^[ind].totalsec;

flpLoad:=false;
{$I-}
if not InitFDD(Ord(UpCase(What))-Ord('A'),CheckMedia) then exit;{}

GetMem(HobetaInfo.body,256*HobetaInfo.totalsec);

s:=p.trdDir^[ind].n1sec+1; t:=p.trdDir^[ind].n1tr; bufpos:=1;
t_old:=0;
for i:=1 to p.trdDir^[ind].totalsec do
 Begin
  t_:=t div 2;
  h_:=t-2*t_;
  s_:=s;
  if t_<>t_old then zxSeek(Ord(UpCase(What))-Ord('A'),t_);
  ReadSector(Ord(UpCase(What))-Ord('A'),t_,h_,s_,1);
  t_old:=t_;
  for k:=0 to 255 do begin HobetaInfo.body^[bufpos]:=FDCBuf[k]; inc(bufpos); end;
  inc(s); if s>16 then begin s:=1; inc(t); end;

{  CMPrint(pal.bkdStatic,pal.txtdStatic,70,halfmaxy-2,'100%');{}

 End;
{$I+}
if ioresult=0 then flpLoad:=true else FreeMem(HobetaInfo.body,256*HobetaInfo.totalsec);
End;


{============================================================================}
Function flpSave(var p:TPanel; What:char):boolean;
Var f:file; t_,h_,s_,k,i,b:byte; buf:array[0..15]of byte; m,bufpos:word;
    tot,t1,t2:integer;

    FOB:file;

Begin
flpSave:=false;
if not InitFDD(Ord(UpCase(What))-Ord('A'),CheckMedia) then exit;{}
{$I-}
inc(p.zxdisk.files);
dec(p.zxdisk.free,hobetainfo.totalsec);

p.trdDir^[p.zxdisk.files].name:=HobetaInfo.name;
p.trdDir^[p.zxdisk.files].typ:=HobetaInfo.typ;
p.trdDir^[p.zxdisk.files].start:=HobetaInfo.start;
p.trdDir^[p.zxdisk.files].length:=HobetaInfo.length;
p.trdDir^[p.zxdisk.files].totalsec:=HobetaInfo.totalsec;
p.trdDir^[p.zxdisk.files].n1tr:=p.zxDisk.nTr1FreeSec;
p.trdDir^[p.zxdisk.files].n1sec:=p.zxDisk.n1FreeSec;

bufpos:=1;
tot:=hobetainfo.totalsec;
t1:=16-p.zxDisk.n1freesec;
if tot<=t1 then t1:=tot;
{
  ERRORMESSAGE('TOT:'+STRR(hobetainfo.totalsec)+
        ' N1FREESEC:'+STRR(p.zxDisk.n1freesec)+
               ' T1:'+STRR(T1));

{}
  t_:=p.zxDisk.ntr1freesec div 2;
  h_:=p.zxDisk.ntr1freesec-2*t_;
  s_:=p.zxDisk.n1freesec+1;

  for m:=1 to t1*256 do begin FDCBuf[m-1]:=HobetaInfo.body^[bufpos]; inc(bufpos); end;
{ASSIGN(FOB,COPY(HobetaInfo.name,1,2)+STRR(T_)+'_'+STRR(H_)+'_'+STRR(S_)+'.A'+STRR(T1)); REWRITE(FOB,1);
BLOCKWRITE(FOB,FDCBUF,256*T1); CLOSE(FOB);{}
  zxSeek(Ord(UpCase(What))-Ord('A'),t_);
  WriteSector(Ord(UpCase(What))-Ord('A'),t_,h_,s_,t1);

  dec(tot,t1);

  while (tot>16) do
   begin
    s_:=1; if h_=0 then h_:=1 else begin h_:=0; inc(t_); end;

    for m:=1 to 16*256 do begin FDCBuf[m-1]:=HobetaInfo.body^[bufpos]; inc(bufpos); end;
{ASSIGN(FOB,COPY(HobetaInfo.name,1,2)+STRR(T_)+'_'+STRR(H_)+'_'+STRR(S_)+'.B'+STRR(16)); REWRITE(FOB,1);
BLOCKWRITE(FOB,FDCBUF,256*16); CLOSE(FOB);{}
    zxSeek(Ord(UpCase(What))-Ord('A'),t_);
    WriteSector(Ord(UpCase(What))-Ord('A'),t_,h_,s_,16);

    dec(tot,16);
   end;

  while (tot>0) do
   begin
    s_:=1; if h_=0 then h_:=1 else begin h_:=0; inc(t_); end;

    for m:=1 to 16*256 do begin FDCBuf[m-1]:=HobetaInfo.body^[bufpos]; inc(bufpos); end;
{ASSIGN(FOB,COPY(HobetaInfo.name,1,2)+STRR(T_)+'_'+STRR(H_)+'_'+STRR(S_)+'.C'+STRR(TOT)); REWRITE(FOB,1);
BLOCKWRITE(FOB,FDCBUF,256*TOT); CLOSE(FOB);{}
    zxSeek(Ord(UpCase(What))-Ord('A'),t_);
    WriteSector(Ord(UpCase(What))-Ord('A'),t_,h_,s_,TOT);

    t1:=tot;
    dec(tot,t1);
   end;

for i:=1 to hobetainfo.totalsec do
 Begin
  inc(p.zxDisk.n1freesec);
  if p.zxDisk.n1freesec>15 then begin p.zxDisk.n1freesec:=0; inc(p.zxDisk.ntr1freesec); end;
 End;

zxSeek(Ord(UpCase(What))-Ord('A'),0);
ReadSector(Ord(UpCase(What))-Ord('A'),0,0,9,1);
FDCBuf[$e1]:=p.zxdisk.n1freesec;
FDCBuf[$e2]:=p.zxdisk.ntr1freesec;
FDCBuf[$e4]:=p.zxdisk.files;
FDCBuf[$e5]:=lo(p.zxdisk.free);
FDCBuf[$e6]:=hi(p.zxdisk.free);
WriteSector(Ord(UpCase(What))-Ord('A'),0,0,9,1);

for i:=1 to 8 do buf[i-1]:=ord(p.trddir^[p.zxdisk.files].name[i]);
buf[8]:=ord(p.trddir^[p.zxdisk.files].typ);
buf[9]:=lo(p.trddir^[p.zxdisk.files].start);
buf[10]:=hi(p.trddir^[p.zxdisk.files].start);
buf[11]:=lo(p.trddir^[p.zxdisk.files].length);
buf[12]:=hi(p.trddir^[p.zxdisk.files].length);
buf[13]:=p.trddir^[p.zxdisk.files].totalsec;
buf[14]:=p.trddir^[p.zxdisk.files].n1sec;
buf[15]:=p.trddir^[p.zxdisk.files].n1tr;

b:=(p.zxdisk.files div 16)+1; if (p.zxdisk.files mod 16)=0 then dec(b);
ReadSector(Ord(UpCase(What))-Ord('A'),0,0,b,1);
k:=p.zxdisk.files-(p.zxdisk.files div 16)*16; if k=0 then k:=16; k:=(k-1)*16;
for i:=0 to 15 do FDCBuf[k+i]:=buf[i];{}
WriteSector(Ord(UpCase(What))-Ord('A'),0,0,b,1);

FreeMem(HobetaInfo.body,256*HobetaInfo.totalsec);
{$I+}
if ioresult=0 then flpSave:=true;
End;



{============================================================================}
function flpDel(var p:TPanel; What:char):boolean;
var df,b,k,io:byte; buf:array[0..15]of byte; fs:file;
begin
flpDel:=false;
if not InitFDD(Ord(UpCase(What))-Ord('A'),CheckMedia) then exit;{}
  {$I-}

    zxSeek(Ord(UpCase(What))-Ord('A'),0);
    ReadSector(Ord(UpCase(What))-Ord('A'),0,0,1,9);

  for i:=1 to p.tfiles do if p.trddir^[i].mark then
   begin
    df:=i-1; b:=(df div 16)+1; if (df mod 16)=0 then dec(b);

    p.trddir^[i].name[1]:=chr(ord('1')-48);
    for io:=0 to 7 do buf[io]:=ord(p.trddir^[i].name[io+1]);
    buf[8]:=ord(p.trddir^[i].typ);
    buf[9]:=lo(p.trddir^[i].start);
    buf[10]:=hi(p.trddir^[i].start);
    buf[11]:=lo(p.trddir^[i].length);
    buf[12]:=hi(p.trddir^[i].length);
    buf[13]:=p.trddir^[i].totalsec;
    buf[14]:=p.trddir^[i].n1sec;
    buf[15]:=p.trddir^[i].n1tr;

    k:=df-(df div 16)*16; if k=0 then k:=16; k:=(k-1)*16;
    for io:=0 to 15 do FDCBuf[256*(b-1)+k+io]:=buf[io];{}

    p.trddir^[i].mark:=false;
    inc(p.zxdisk.delfiles);
   end;
  {$I+}
FDCBuf[256*8+$f4]:=p.zxdisk.delfiles;
    WriteSector(Ord(UpCase(What))-Ord('A'),0,0,1,9);

if ioresult=0 then flpDel:=true;
end;



{============================================================================}
function flpRename(What:char):boolean;
var xc,yc,df,b,k,io:byte; buf:array[0..15]of byte; fs:file; s,stemp:string;
    p:tPanel;
begin
flpRename:=false;
if not InitFDD(Ord(UpCase(What))-Ord('A'),CheckMedia) then exit;{}

Case focus of left:p:=lp; right:p:=rp; End;
  {$I-}
if p.Index<=1 then exit;
CancelSB;
colour(pal.bkCurNT,pal.txtCurNT);
stemp:=p.trddir^[p.Index].name+'.'+TRDOSe3(p,p.Index);
s:=stemp; GetCurXYOf(focus,xc,yc);
curon; SetCursor(400); stemp:=zxsnscanf(xc,yc,stemp,p.trddir^[p.Index].typ); curoff;
if not scanf_esc then
BEGIN

i:=p.Index;

df:=i-1; b:=(df div 16)+1; if (df mod 16)=0 then dec(b);
zxSeek(Ord(UpCase(What))-Ord('A'),0);
ReadSector(Ord(UpCase(What))-Ord('A'),0,0,b,1);

    if (s[1]=chr(ord('1')-48))or(s[1]=chr(ord('0')-48)) then
      if (stemp[1]<>chr(ord('1')-48))and(stemp[1]<>chr(ord('0')-48))
      then dec(p.zxdisk.delfiles);

    p.trddir^[i].name:=stemp;
    for io:=0 to 7 do buf[io]:=ord(p.trddir^[i].name[io+1]);
    if (TRDOS3)and(p.trddir^[p.Index].typ<>'B') then buf[8]:=ord(stemp[10]) else buf[8]:=ord(stemp[11]);
    buf[9]:=lo(p.trddir^[i].start);
    buf[10]:=hi(p.trddir^[i].start);
    buf[11]:=lo(p.trddir^[i].length);
    buf[12]:=hi(p.trddir^[i].length);
    buf[13]:=p.trddir^[i].totalsec;
    buf[14]:=p.trddir^[i].n1sec;
    buf[15]:=p.trddir^[i].n1tr;

k:=df-(df div 16)*16; if k=0 then k:=16; k:=(k-1)*16;
for io:=0 to 15 do FDCBuf[k+io]:=buf[io];{}
WriteSector(Ord(UpCase(What))-Ord('A'),0,0,b,1);

ReadSector(Ord(UpCase(What))-Ord('A'),0,0,9,1);
FDCBuf[$f4]:=p.zxdisk.delfiles;
WriteSector(Ord(UpCase(What))-Ord('A'),0,0,9,1);
END;

  {$I+}
if ioresult=0 then flpRename:=true;
reMDF; reInfo('cbdnsfi'); rePDF;
end;




{============================================================================}
function flpLabel(What:char):boolean;
var s:string; fs:file of byte; b:byte; p:TPanel;
label fin;
begin
flpLabel:=false;
if not InitFDD(Ord(UpCase(What))-Ord('A'),CheckMedia) then exit;{}
{$I-}
Case focus of left:p:=lp; right:p:=rp; End;
CancelSB; colour(pal.bkCurST,pal.txtCurST);
s:=p.zxdisk.disklabel;
curon;
Case focus of
 left:  begin mprint(16,1,space(10)); s:=scanf(17,1,nospaceLR(s),8,8,1); end;
 right: begin mprint(56,1,space(10)); s:=scanf(57,1,nospaceLR(s),8,8,1); end;
End;
s:=copy(s,1,8)+space(8-length(copy(s,1,8)));
curoff;
if not scanf_esc then
 begin
  zxSeek(Ord(UpCase(What))-Ord('A'),0);
  ReadSector(Ord(UpCase(What))-Ord('A'),0,0,9,1);
  FDCBuf[$f4]:=p.zxdisk.delfiles;
  for i:=1 to 8 do FDCBuf[$f5+i-1]:=ord(s[i]);
  WriteSector(Ord(UpCase(What))-Ord('A'),0,0,9,1);
 end;
{$I+}
if ioresult=0 then flpLabel:=true;
reMDF; rePDF;
reInfo('cbdnsfi');
end;




{============================================================================}
function flpMove(var p:Tpanel; What:char):boolean;
var fr,t:word;
    r,c,i,a,m,k,io:word;
    b:byte;
    stemp:string;
begin
{$I-}
flpMove:=false;
if p.zxdisk.delfiles=0 then exit;

CancelSB;
stemp:='Do you wish to move'#255'this disk ?';
if not trdautomove then
if not cquestion(stemp,lang) then exit;

if not InitFDD(Ord(UpCase(What))-Ord('A'),CheckMedia) then exit;{}

if Moused then MouseOff;
Colour(pal.bkdRama,pal.txtdRama); sPutWin(halfmaxx-20,halfmaxy-4,halfmaxx+21,halfmaxy+2);
cmcentre(pal.bkdRama,pal.txtdRama,halfmaxy-4,' Move ');


flpMDF(p,p.flpDrive);
fr:=0; t:=0; r:=0;
for i:=2 to p.flptfiles do inc(fr,p.trddir^[i].totalsec); inc(fr,p.zxdisk.free);
for i:=2 to p.flptfiles do
 if (ord(p.trddir^[i].name[1])<>1)and(ord(p.trddir^[i].name[1])<>0)
   then inc(t,p.trddir^[i].totalsec);
p.zxdisk.free:=fr-t;

for i:=2 to p.flptfiles do
 if (ord(p.trddir^[i].name[1])=1)or(ord(p.trddir^[i].name[1])=0) then break;
p.zxdisk.n1freesec:=p.trddir^[i].n1sec;
p.zxdisk.ntr1freesec:=p.trddir^[i].n1tr;
p.zxdisk.files:=i-2;

for c:=i to p.flptfiles do
 if (ord(p.trddir^[c].name[1])<>1)and(ord(p.trddir^[c].name[1])<>0) then inc(r);

for c:=i to p.flptfiles do
 if (ord(p.trddir^[c].name[1])<>1)and(ord(p.trddir^[c].name[1])<>0) then break;

for a:=c to p.flptfiles do
if (ord(p.trddir^[a].name[1])<>1)and(ord(p.trddir^[a].name[1])<>0) then
 begin
  CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,halfmaxy-0,
       'Remained to trasfer - '+strr(r)+' ');

  CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,halfmaxy-2,
      'Loading '+p.trdDir^[a].name+'.'+TRDOSe3(p,a));
  flpLoad(p,a,p.flpDrive);

  CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,halfmaxy-2,
      'Saving '+p.trdDir^[a].name+'.'+TRDOSe3(p,a));
  flpSave(p,p.flpDrive);

  inc(p.zxdisk.free,p.trddir^[a].totalsec);{}
  dec(r);
 end;


InitFDD(Ord(UpCase(What))-Ord('A'),CheckMedia);{}

CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,halfmaxy-0,space(26));
CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,halfmaxy-2,space(26));

CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,halfmaxy-1,
   '   Updating directory...   ');
{}

zxSeek(Ord(UpCase(What))-Ord('A'),0);
ReadSector(Ord(UpCase(What))-Ord('A'),0,0,1,8);
for m:=p.zxdisk.files+2 to 128 do
 begin
  c:=m-1; b:=(c div 16)+1; if (c mod 16)=0 then dec(b);
  k:=c-(c div 16)*16; if k=0 then k:=16; k:=(k-1)*16;
  FDCBuf[256*(b-1)+k]:=0;
 end;
WriteSector(Ord(UpCase(What))-Ord('A'),0,0,1,8);

ReadSector(Ord(UpCase(What))-Ord('A'),0,0,9,1);
FDCBuf[$f4]:=p.zxdisk.delfiles;
FDCBuf[$e1]:=p.zxdisk.n1freesec;
FDCBuf[$e2]:=p.zxdisk.ntr1freesec;
FDCBuf[$e4]:=p.zxdisk.files;
FDCBuf[$f4]:=0;
FDCBuf[$e5]:=lo(p.zxdisk.free);
FDCBuf[$e6]:=hi(p.zxdisk.free);
WriteSector(Ord(UpCase(What))-Ord('A'),0,0,9,1);

if ioresult=0 then;

RestScr;

p.flpMDFs(p.flpDrive);
if trdAutoMove then exit;
p.TrueCur; p.Inside;
reInfo('cbdnsfi');
rePDF;

{$I+}
if ioresult=0 then flpMove:=true;
end;




End.