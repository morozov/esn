{$O+,F+}
Unit TRD_Ovr;
Interface
Uses
     Dos,Crt,RV,sn_Obj, Vars, Main, Main_Ovr,
     PC,PC_Ovr,TRD;
function  trdLoad(var p:TPanel; ind:word):boolean;
function  trdSave(var p:TPanel):boolean;
function  trdDel(var p:TPanel):boolean;
function  zxSNscanf(scanf_posx, scanf_posy:byte;scanf_str:string; t:char):string;
function  trdRename:boolean;
function  trdMove(var p:Tpanel):boolean;
procedure mtscanf(scanf_str,scanf_str2:string; var scanf_str_out,scanf_str2_out:string);
function  trdLabel:boolean;
procedure trdMakeImage(var p:TPanel; BootOnly:boolean);

procedure AltCPressed(var p:TPanel);
procedure AltPPressed(var p:TPanel);
procedure AltRPressed(var p:TPanel);


Procedure snCopier(flag:word; SourcePanel,DestPanel:byte);
Procedure snEraser(var p:TPanel);
{Procedure snPacker(var p:TPanel);{}

{Procedure zxViewFile(var p:TPanel);{}

Procedure zxEditParam(p:TPanel; ind:integer);



Implementation

Uses palette,
FDI_Ovr, SCL, SCL_Ovr, FDD_Ovr, FDD, TAP_Ovr, ZXZIP, FLP_Ovr, FLP, trdos,
mouse, ZXVIEW, snViewer;

Var
     noHobCopyBlockSize:byte;
     noHobCopyBlockSizeSet:boolean;


{============================================================================}
function  trdLoad(var p:TPanel; ind:word):boolean;
Var f:file;
Begin
HobetaInfo.name:=p.trdDir^[ind].name;
HobetaInfo.typ:=p.trdDir^[ind].typ;
HobetaInfo.start:=p.trdDir^[ind].start;
HobetaInfo.length:=p.trdDir^[ind].length;
HobetaInfo.param2:=p.trdDir^[ind].length{};
if HobetaInfo.typ<>'B' then HobetaInfo.param2:=32768;
HobetaInfo.totalsec:=p.trdDir^[ind].totalsec;

trdLoad:=false;
{$I-}
GetMem(HobetaInfo.body,256*HobetaInfo.totalsec);
assign(f,p.trdfile); filemode:=0; reset(f,1);
seek(f,bpos(p.trdDir^[ind].n1tr,p.trdDir^[ind].n1sec));
blockread(f,HobetaInfo.body^,256*HobetaInfo.totalsec);
close(f);
{$I+}
if ioresult=0 then trdLoad:=true else FreeMem(HobetaInfo.body,256*HobetaInfo.totalsec);
End;



{============================================================================}
function  trdSave(var p:TPanel):boolean;
Var f:file; i,b:byte; buf:array[0..15]of byte;
Begin
trdSave:=false;
{$I-}
assign(f,p.trdfile); filemode:=2; reset(f,1);

seek(f,bpos(p.zxDisk.nTr1FreeSec,p.zxDisk.n1FreeSec));
blockwrite(f,HobetaInfo.body^,256*HobetaInfo.totalsec);

inc(p.zxdisk.files);
dec(p.zxdisk.free,hobetainfo.totalsec);

p.trdDir^[p.zxdisk.files].name:=HobetaInfo.name;
p.trdDir^[p.zxdisk.files].typ:=HobetaInfo.typ;
p.trdDir^[p.zxdisk.files].start:=HobetaInfo.start;
p.trdDir^[p.zxdisk.files].length:=HobetaInfo.length;
p.trdDir^[p.zxdisk.files].totalsec:=HobetaInfo.totalsec;
p.trdDir^[p.zxdisk.files].n1tr:=p.zxDisk.nTr1FreeSec;
p.trdDir^[p.zxdisk.files].n1sec:=p.zxDisk.n1FreeSec;

for i:=1 to hobetainfo.totalsec do
 begin
  inc(p.zxdisk.n1freesec);
  if p.zxdisk.n1freesec>15 then begin p.zxdisk.n1freesec:=0; inc(p.zxdisk.ntr1freesec); end;
 end;

seek(f,$8e1); b:=p.zxdisk.n1freesec;   blockwrite(f,b,1);
seek(f,$8e2); b:=p.zxdisk.ntr1freesec; blockwrite(f,b,1);
seek(f,$8e4); b:=p.zxdisk.files;       blockwrite(f,b,1);
seek(f,$8e5); b:=lo(p.zxdisk.free);    blockwrite(f,b,1);
seek(f,$8e6); b:=hi(p.zxdisk.free);    blockwrite(f,b,1);

for i:=1 to 8 do buf[i-1]:=ord(p.trddir^[p.zxdisk.files].name[i]);
buf[8]:=ord(p.trddir^[p.zxdisk.files].typ);
buf[9]:=lo(p.trddir^[p.zxdisk.files].start);
buf[10]:=hi(p.trddir^[p.zxdisk.files].start);
buf[11]:=lo(p.trddir^[p.zxdisk.files].length);
buf[12]:=hi(p.trddir^[p.zxdisk.files].length);
buf[13]:=p.trddir^[p.zxdisk.files].totalsec;
buf[14]:=p.trddir^[p.zxdisk.files].n1sec;
buf[15]:=p.trddir^[p.zxdisk.files].n1tr;
seek(f,16*(p.zxdisk.files-1)); blockwrite(f,buf,16);

FreeMem(HobetaInfo.body,256*HobetaInfo.totalsec);
close(f);
{$I+}
if ioresult=0 then trdSave:=true;
End;



{============================================================================}
function trdDel(var p:TPanel):boolean;
type hbuft=array[0..15] of byte; var i,io:byte; hbuf:hbuft; fs:file;
begin
trdDel:=false;
  {$I-}
  assign(fs,p.trdfile); filemode:=2; reset(fs,1);

  for i:=1 to p.tfiles do if p.trddir^[i].mark then
   begin
    inc(p.zxdisk.delfiles); seek(fs,$8f4); blockwrite(fs,p.zxdisk.delfiles,1);
    p.trddir^[i].name[1]:=chr(ord('1')-48);
    for io:=1 to 8 do hbuf[io-1]:=ord(p.trddir^[i].name[io]);
    hbuf[8]:=ord(p.trddir^[i].typ);
    hbuf[9]:=lo(p.trddir^[i].start);
    hbuf[10]:=hi(p.trddir^[i].start);
    hbuf[11]:=lo(p.trddir^[i].length);
    hbuf[12]:=hi(p.trddir^[i].length);
    hbuf[13]:=p.trddir^[i].totalsec;
    hbuf[14]:=p.trddir^[i].n1sec;
    hbuf[15]:=p.trddir^[i].n1tr;
    seek(fs,16*(i-2)); blockwrite(fs,hbuf,16);
    p.trddir^[i].mark:=false;
   end;

  close(fs);
  {$I+}
  if ioresult=0 then trdDel:=true;
  if AutoMove then
   begin
    trdautomove:=true;
    trdMove(p);
    trdautomove:=false;
   end;
end;





{============================================================================}
function zxSNscanf(scanf_posx, scanf_posy:byte;scanf_str:string; t:char):string;
var
     scanf_kod:char;
     scanf_x:byte;
     scanf_str_old:string;
     out:byte;
label loop;
begin
scanf_esc:=false;
scanf_str_old:=scanf_str;
scanf_x:=1;
{scanf_str:=scanf_str+space(12-length(scanf_str));{}
loop:
mprint(scanf_posx,scanf_posy,scanf_str);
gotoxy(scanf_posx+scanf_x-1,scanf_posy);
scanf_kod:=readkey;
if (scanf_kod in[' '..#127])and(scanf_x<=length(scanf_str)) then
 begin
  scanf_str[scanf_x]:=scanf_kod;
  inc(scanf_x);
  if scanf_x=9 then inc(scanf_x);
  if scanf_x=10 then inc(scanf_x);
 end;

if scanf_kod=#0 then
 begin
  scanf_kod:=readkey;
  if scanf_kod=#77 then
   begin
    inc(scanf_x);
    if scanf_x=9 then inc(scanf_x);
    if (TRDOS3)and(t<>'B') then else if scanf_x=10 then inc(scanf_x);
   end;
  if scanf_kod=#75 then
   begin
    dec(scanf_x);
    if (TRDOS3)and(t<>'B') then else if scanf_x=10 then dec(scanf_x);
    if scanf_x=9 then dec(scanf_x);
   end;
  if scanf_kod=#80 then scanf_kod:=#13;
  if scanf_kod=#72 then scanf_kod:=#13;
 end;

{}
if scanf_kod=#27 then begin zxsnscanf:=scanf_str_old; scanf_esc:=true; exit; end;
if scanf_kod=#13 then begin zxsnscanf:=scanf_str; exit; end;


if scanf_x<1 then scanf_x:=1;
if (TRDOS3)and(t<>'B') then out:=12 else out:=11;
if scanf_x>out then begin scanf_x:=out; end;
goto loop;
end;





{============================================================================}
function  trdRename:boolean;
type hbuft=array[0..15] of byte;
var i,io:integer;
    stemp,s:string;
    fs:file;
    xc,yc,b:byte;
    hbuf:hbuft;
    p:TPanel;
label fin;
Begin
trdRename:=false;
Case focus of left:p:=lp; right:p:=rp; End;
if p.Index<=1 then exit;
CancelSB;
colour(pal.bkCurNT,pal.txtCurNT);
stemp:=p.trddir^[p.Index].name+'.'+TRDOSe3(p,p.Index);
s:=stemp;
GetCurXYOf(focus,xc,yc);
curon; SetCursor(400); stemp:=zxsnscanf(xc,yc,stemp,p.trddir^[p.Index].typ); curoff;
if not scanf_esc then
 begin
  {$I-}
  assign(fs,p.trdfile); filemode:=2; reset(fs,1);
  i:=p.Index;
  if (TRDOS3)and(p.trddir^[p.Index].typ<>'B') then p.trddir^[i].start:=256*ord(stemp[12])+ord(stemp[11]);
  if (s[1]=chr(ord('1')-48))or(s[1]=chr(ord('0')-48)) then
   if (stemp[1]<>chr(ord('1')-48))and(stemp[1]<>chr(ord('0')-48))
   then dec(p.zxdisk.delfiles);
  seek(fs,$8f4); b:=p.zxdisk.delfiles;  blockwrite(fs,b,1);
  for io:=1 to 8 do hbuf[io-1]:=ord(stemp[io]);
  if (TRDOS3)and(p.trddir^[p.Index].typ<>'B') then hbuf[8]:=ord(stemp[10]) else hbuf[8]:=ord(stemp[11]);
  hbuf[9]:=lo(p.trddir^[i].start);
  hbuf[10]:=hi(p.trddir^[i].start);
  hbuf[11]:=lo(p.trddir^[i].length);
  hbuf[12]:=hi(p.trddir^[i].length);
  hbuf[13]:=p.trddir^[i].totalsec;
  hbuf[14]:=p.trddir^[i].n1sec;
  hbuf[15]:=p.trddir^[i].n1tr;
  seek(fs,16*(i-2));
  blockwrite(fs,hbuf,16);
  close(fs);
  {$I+}
  if ioresult=0 then trdRename:=true;
 end;
fin:
reMDF; reInfo('cbdnsfi'); rePDF;
End;




{============================================================================}
function trdMove(var p:Tpanel):boolean;
type hbuft=array[1..2] of byte;
var fr,t:word;
    c,i,a,m:integer; fs:file; buf:^hbuft; nr,nw:word; hbuf:array[0..15] of byte;
    b:byte;
    stemp:string;
begin
trdMove:=false;
if p.zxdisk.delfiles=0 then exit;
CancelSB;
stemp:='Do you wish to move'#255'this disk ?';
if not trdautomove then
if not cquestion(stemp,lang) then exit;
if checkdirfile(p.trdfile)<>0 then
 begin
  errormessage('File '+strlo(getof(p.trdfile,_name))+'.trd not found');
  p.paneltype:=pcpanel;
  p.pcMDF(p.pcnd);
  p.truecur;
  p.inside;
  p.Info('cbdnsfi');
  p.pcPDF(p.pcfrom);
  exit;
 end;
p.trdMDFs(p.trdfile);
fr:=0; t:=0;
for i:=1 to p.trdtfiles do fr:=fr+p.trddir^[i].totalsec;
inc(fr,p.zxdisk.free);
for i:=1 to p.trdtfiles do
 if (ord(p.trddir^[i].name[1])<>1)and(ord(p.trddir^[i].name[1])<>0) then
  t:=t+p.trddir^[i].totalsec;
  p.zxdisk.free:=fr-t;

  for i:=1 to p.trdtfiles do
   if (ord(p.trddir^[i].name[1])=1)or(ord(p.trddir^[i].name[1])=0) then break;
  p.zxdisk.n1freesec:=p.trddir^[i].n1sec;
  p.zxdisk.ntr1freesec:=p.trddir^[i].n1tr;
  for c:=i to p.trdtfiles do
   if (ord(p.trddir^[c].name[1])<>1)and(ord(p.trddir^[c].name[1])<>0) then break;
  {$I-}
  assign(fs,p.trdfile); filemode:=2; reset(fs,1);

  for a:=c to p.trdtfiles do
  if (ord(p.trddir^[a].name[1])<>1)and(ord(p.trddir^[a].name[1])<>0) then
   begin
    getmem(buf,p.trddir^[a].totalsec*256);
    seek(fs,bpos(p.trddir^[a].n1tr,p.trddir^[a].n1sec));
    blockread(fs,buf^,p.trddir^[a].totalsec*256,nr);
    seek(fs,bpos(p.zxdisk.ntr1freesec,p.zxdisk.n1freesec));
    blockwrite(fs,buf^,nr,nw);
    freemem(buf,p.trddir^[a].totalsec*256);

    p.trddir^[i].n1tr:=p.zxdisk.ntr1freesec;
    p.trddir^[i].n1sec:=p.zxdisk.n1freesec;
    p.trddir^[i].name:=p.trddir^[a].name;
    p.trddir^[i].typ:=p.trddir^[a].typ;
    p.trddir^[i].start:=p.trddir^[a].start;
    p.trddir^[i].length:=p.trddir^[a].length;
    p.trddir^[i].totalsec:=p.trddir^[a].totalsec;
    for m:=1 to p.trddir^[a].totalsec do
     begin
      inc(p.zxdisk.n1freesec);
      if p.zxdisk.n1freesec>15 then begin p.zxdisk.n1freesec:=0; inc(p.zxdisk.ntr1freesec); end;
     end;

    for m:=1 to 8 do hbuf[m-1]:=ord(p.trddir^[i].name[m]);
    hbuf[8]:=ord(p.trddir^[i].typ);
    hbuf[9]:=lo(p.trddir^[i].start);
    hbuf[10]:=hi(p.trddir^[i].start);
    hbuf[11]:=lo(p.trddir^[i].length);
    hbuf[12]:=hi(p.trddir^[i].length);
    hbuf[13]:=p.trddir^[i].totalsec;
    hbuf[14]:=p.trddir^[i].n1sec;
    hbuf[15]:=p.trddir^[i].n1tr;
    seek(fs,16*(i-2)); blockwrite(fs,hbuf,16);

    inc(i);
   end;
  for m:=i-1 to 128 do begin seek(fs,16*(m-1)); b:=0; blockwrite(fs,b,1); end;
  seek(fs,$8e1); b:=p.zxdisk.n1freesec;   blockwrite(fs,b,1);
  seek(fs,$8e2); b:=p.zxdisk.ntr1freesec; blockwrite(fs,b,1);
  seek(fs,$8e4); b:=i-2;                  blockwrite(fs,b,1);
  seek(fs,$8f4); b:=0;                    blockwrite(fs,b,1);

  seek(fs,$8e5); b:=lo(p.zxdisk.free);    blockwrite(fs,b,1);
  seek(fs,$8e6); b:=hi(p.zxdisk.free);    blockwrite(fs,b,1);

  close(fs);
  {$I+}
if ioresult=0 then trdMove:=true;

p.trdMDFs(p.trdfile);
if trdAutoMove then exit;
p.TrueCur; p.Inside;
reInfo('cbdnsfi');
rePDF;
end;



{============================================================================}
function trdLabel:boolean;
var s:string; fs:file of byte; b:byte; p:TPanel;
label fin;
begin
trdLabel:=false; Case focus of left:p:=lp; right:p:=rp; End;
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
  {$I-}
  assign(fs,p.trdfile); filemode:=2; reset(fs);
  seek(fs,$8f5); for i:=1 to 8 do begin b:=ord(s[i]); write(fs,b); end;
  close(fs);
  {$I+}
  if ioresult=0 then trdLabel:=true;
  reMDF; rePDF;
 end;
fin:
reInfo('cbdnsfi');
end;





{============================================================================}
procedure mtscanf(scanf_str,scanf_str2:string; var scanf_str_out,scanf_str2_out:string);
var
     scanf_kod:char;
     scanf_x, scanf_x2:byte;
     scanf_total,scanf_total2, scanf_visible,scanf_visible2:byte;
     scanf_str_old:string;
label loop,loop2;
begin
scanf_esc:=false;
scanf_total:=8; scanf_total2:=3;
scanf_visible:=8; scanf_visible2:=3;
scanf_str:=scanf_str+space(scanf_total-length(scanf_str));{}
scanf_str2:=scanf_str2+space(scanf_total2-length(scanf_str2));{}
scanf_x:=1; scanf_x2:=1;
if scanf_visible>length(scanf_str) then scanf_visible:=length(scanf_str);

loop:
mprint(42,halfmaxy-2,scanf_str);
mprint(47,halfmaxy-0,scanf_str2);
gotoxy(42+scanf_x-1,halfmaxy-2);
scanf_kod:=readkey;
if scanf_kod=#27 then begin scanf_esc:=true; exit; end;
if scanf_kod=#13 then
 begin
  if (vall(nospace(scanf_str2))=40)or
     ((vall(nospace(scanf_str2))>=80)and(vall(nospace(scanf_str2))<=128)) then
   begin
    scanf_str_out:=scanf_str; scanf_str2_out:=scanf_str2;
    exit;
   end
  else
   begin
    scanf_str2:=nospace(scanf_str2);
    if (vall(scanf_str2)>=0)and(vall(scanf_str2)<=40) then scanf_str2:='40';
    if (vall(scanf_str2)>=41)and(vall(scanf_str2)<=80) then scanf_str2:='80';
    if vall(scanf_str2)>128 then scanf_str2:='128';
    scanf_str2:=scanf_str2+space(scanf_total2-length(scanf_str2));{}
   end;
 end;

if ((scanf_kod)>=' ')and((scanf_kod)<='я')and(scanf_x<=length(scanf_str)) then
 begin
  scanf_str:=copy(scanf_str,1,scanf_x-1)+scanf_kod+copy(scanf_str,scanf_x,length(scanf_str));
  scanf_str:=copy(scanf_str,1,length(scanf_str)-1);
  inc(scanf_x);
  if scanf_x>length(scanf_str)+1 then scanf_x:=length(scanf_str)+1;
 end;

if scanf_kod=#8 then
 begin
  scanf_str:=copy(scanf_str,1,scanf_x-2)+copy(scanf_str,scanf_x,length(scanf_str));
  dec(scanf_x);
  if scanf_x<1 then scanf_x:=1 else scanf_str:=scanf_str+' ';
  if scanf_x<1 then scanf_x:=1;
 end;

if scanf_kod=#9 then
 begin
loop2:
  mprint(42,halfmaxy-2,scanf_str);
  mprint(47,halfmaxy-0,scanf_str2);
  gotoxy(47+scanf_x2-1,halfmaxy-0);
  scanf_kod:=readkey;
  if scanf_kod=#9 then goto loop;
  if scanf_kod=#13 then
   begin
    if (vall(nospace(scanf_str2))=0)or
       (vall(nospace(scanf_str2))=40)or
       ((vall(nospace(scanf_str2))>=80)and(vall(nospace(scanf_str2))<=128)) then
     begin
      scanf_str_out:=scanf_str; scanf_str2_out:=scanf_str2;
      exit;
     end
    else
     begin
      scanf_str2:=nospace(scanf_str2);
      if (vall(scanf_str2)>0)and(vall(scanf_str2)<=40) then scanf_str2:='40';
      if (vall(scanf_str2)>=41)and(vall(scanf_str2)<=80) then scanf_str2:='80';
      if vall(scanf_str2)>128 then scanf_str2:='128';
      scanf_str2:=scanf_str2+space(scanf_total2-length(scanf_str2));{}
     end;
   end;
  if scanf_kod=#27 then begin scanf_esc:=true; exit; end;
  if scanf_kod=#8 then
   begin
    scanf_str2:=copy(scanf_str2,1,scanf_x2-2)+copy(scanf_str2,scanf_x2,length(scanf_str2));
    dec(scanf_x2);
    if scanf_x2<1 then scanf_x2:=1 else scanf_str2:=scanf_str2+' ';
    if scanf_x2<1 then scanf_x2:=1;
   end;
  if (scanf_kod in['1'..'9','0',' '])and(scanf_x2<=length(scanf_str2)) then
   begin
    scanf_str2[scanf_x2]:=scanf_kod;
    inc(scanf_x2);
    if scanf_x2>length(scanf_str2)+1 then scanf_x2:=length(scanf_str2)+1;
   end;
  if scanf_kod=#0 then
   begin
    scanf_kod:=readkey;
    if scanf_kod=#71 then begin scanf_x2:=1; end;
    if scanf_kod=#79 then begin scanf_x2:=length(scanf_str2); end;
    if scanf_kod=#83 then scanf_str2:=copy(scanf_str2,1,scanf_x2-1)+copy(scanf_str2,scanf_x2+1,length(scanf_str2))+' ';
    if scanf_kod=#77 then inc(scanf_x2);
    if scanf_kod=#75 then dec(scanf_x2);
    if scanf_x2<1 then scanf_x2:=1;
    if scanf_x2>length(scanf_str2)+1 then begin scanf_x2:=length(scanf_str2)+1; end;
   end;

  goto loop2;
 end;

if scanf_kod=#25 then
 begin
  scanf_str:=space(scanf_total);
  scanf_x:=1;
 end;

if scanf_kod=#0 then
 begin
  scanf_kod:=readkey;
  if scanf_kod=#71 then begin scanf_x:=1; end;
  if scanf_kod=#79 then begin scanf_x:=length(scanf_str); end;
  if scanf_kod=#83 then scanf_str:=copy(scanf_str,1,scanf_x-1)+copy(scanf_str,scanf_x+1,length(scanf_str))+' ';
  if scanf_kod=#77 then inc(scanf_x);
  if scanf_kod=#75 then dec(scanf_x);
  if scanf_x<1 then scanf_x:=1;
  if scanf_x>length(scanf_str)+1 then begin scanf_x:=length(scanf_str)+1; end;
 end;

goto loop;
end;



{============================================================================}
procedure trdMakeImage(var p:TPanel; BootOnly:boolean);
var name:string; stemp,tr:string;
    buf:array[1..8192] of byte;
    i:word;
    ff:file;
    fb:file of byte;
    ft:text;
    b:byte;
    pp:TPanel;
begin
 CancelSB;

if BootOnly then else
BEGIN
 colour(pal.bkdRama,pal.txtdRama);
 scputwin(pal.bkdRama,pal.txtdRama,27,halfmaxy-4,54,halfmaxy+2);
 if makeboot
  then cmcentre(pal.bkdRama,pal.txtdRama,halfmaxy-4,' New TRD-file + boot ')
  else cmcentre(pal.bkdRama,pal.txtdRama,halfmaxy-4,' New TRD-file ');

 cmprint(pal.bkdLabelST,pal.txtdLabelST,31,halfmaxy-2,'File name:');
 cmprint(pal.bkdLabelST,pal.txtdLabelST,31,halfmaxy-0,'Tracks on disk:');
 printself(pal.bkdInputNT,pal.txtdInputNT,42,halfmaxy-2,8);
 printself(pal.bkdInputNT,pal.txtdInputNT,47,halfmaxy-0,3);
 colour(pal.bkdInputNT,pal.txtdInputNT);
 curon;
 mtscanf('','80',name,tr);
 curoff;
 restscr;

name:=nospace(name); tr:=nospace(tr);
if (name='com1')or(name='com2')or(name='com3')or(name='com4')or
   (name='lpt1')or(name='lpt2')or(name='lpt3')or(name='lpt4')or
   (name='con')or(name='nul')or(name='prn')or(name='aux') then
    begin errormessage('Error while create TRD-file'); exit; end;

if scanf_esc then exit;
if nospace(name)<>'' then
 begin
 {$I-}
  scputwin(pal.bkdRama,pal.txtdRama,27,halfmaxy-4,54,halfmaxy+2);
  cmprint(pal.bkdLabelST,pal.txtdLabelST,30,halfmaxy-2,'Formating...');
  cmprint(7,0,30,halfmaxy-1,fill(23,#177));

  stemp:='File '+getof(name,_name)+'.trd'+' alredy exist.'+#255+' Overwrite?';
  if checkdirfile(p.pcnd+getof(name,_name)+'.trd')=0 then
   if not cquestion(stemp,lang) then begin restscr; exit; end;
  filemode:=2;
  p.pcnn:=getof(name,_name)+'.trd';
  assign(ff,p.pcnd+getof(name,_name)+'.trd'); rewrite(ff,1);
  for i:=1 to sizeof(buf) do buf[i]:=0;
  if vall(tr)=0 then blockwrite(ff,buf,4096) else
  for i:=1 to vall(tr) do
   begin
    blockwrite(ff,buf,sizeof(buf));
    ProcessBar(0,round(100*i/vall(tr)),22,'');
    cmprint(7,0,49,halfmaxy-0,strr(round(100*i/vall(tr))-1)+'%');
   end;
  close(ff);

  if vall(tr)=0 then tr:='80';
  i:=(vall(tr)*2-1)*16;
  assign(fb,p.pcnd+getof(name,_name)+'.trd'); reset(fb);
  seek(fb,$8e1); b:=0; write(fb,b);
  seek(fb,$8e2); b:=1; write(fb,b);
  seek(fb,$8e3); if vall(nospace(tr))=40 then b:=$17 else b:=$16; write(fb,b);
  seek(fb,$8e4); b:=0; write(fb,b);
  seek(fb,$8e5); b:=lo(i); write(fb,b);
  seek(fb,$8e6); b:=hi(i); write(fb,b);
  seek(fb,$8e7); b:=$10; write(fb,b);
  seek(fb,$8f4); b:=0; write(fb,b);
  name:=name+space(8-length(name));
  seek(fb,$8f5);
  for i:=0 to 7 do begin b:=byte(name[i+1]); write(fb,b); end;
  close(fb);
  {$I+}
  i:=ioresult;
  if i<>0 then errormessage('Error '+strr(i)+' while create TRD-file');
  RestScr;
 end;

END;
makeboot:=false;
end;




{============================================================================}
procedure AltCPressed(var p:TPanel);
type
    tmas=array[1..1] of byte;
var
    ff:file; fb:file of byte;
    buf:^tmas;
    nw,m:word;
    rest:integer;
    stemp:string;
    l:longint; b1,b:byte;

begin
if istrd(p.pcnd+p.pcnn) then
 begin
  CancelSB;
  stemp:='Function: TRD clean'#255'Do you wish zero not used sectors?';
  if cquestion(stemp,lang) then
   begin
    trdMove(p);
{$I-}
    assign(fb,p.pcnd+p.pcnn); filemode:=2; reset(fb);
    seek(fb,$8e1); read(fb,b); p.zxdisk.n1FreeSec:=b;
    seek(fb,$8e2); read(fb,b); p.zxdisk.ntr1FreeSec:=b;
    seek(fb,$8e4); read(fb,b); p.zxdisk.files:=b;
    seek(fb,$8e5); read(fb,b1);
    seek(fb,$8e6); read(fb,b); p.zxdisk.free:=b1+256*b;
    close(fb);

    rest:=p.zxdisk.free;

    getmem(buf,65280);
    for m:=1 to 65280 do buf^[m]:=0;
    assign(ff,p.pcnd+p.pcnn); filemode:=2; reset(ff,1);
    seek(ff,bpos(p.zxdisk.nTr1freeSec,p.zxdisk.n1freeSec));

    for m:=1 to (rest div 255) do blockwrite(ff,buf^,65280);
    freemem(buf,65280);

    nw:=rest-255*(rest div 255);
    getmem(buf,256*nw);
    for m:=1 to 256*nw do buf^[m]:=0;
    blockwrite(ff,buf^,256*nw);
    freemem(buf,256*nw);

    nw:=16*(128-p.zxdisk.files);
    getmem(buf,nw);
    for m:=1 to nw do buf^[m]:=0;
    seek(ff,(16*p.zxdisk.files));
    blockwrite(ff,buf^,nw);

    seek(ff,bpos(0,8)); blockwrite(ff,buf^,225);
    seek(ff,bpos(0,9)); blockwrite(ff,buf^,7*256);

    freemem(buf,nw);
    close(ff);
{$I+}
    if ioresult<>0 then;

    reMDF;
    p.TrueCur; p.Inside;{}
    reInfo('cbdnsfi');
    rePDF;
   end;
 end;
end;




{============================================================================}
procedure AltPPressed(var p:TPanel);
var ff:file of byte; stemp:string;
begin

if istrd(p.pcnd+p.pcnn) then
 begin
  CancelSB;
  stemp:='Function: TRD pack'#255'Do you wish remove not used sectors?';
  if cquestion(stemp,lang) then
   begin
    p.trdfile:=p.pcnd+p.pcnn;
    trdautomove:=true;
    trdMove(p);
    trdautomove:=AutoMove;
{$I-}
    assign(ff,p.pcnd+p.pcnn); filemode:=2; reset(ff);

seek(ff,$8e1); read(ff,p.zxdisk.n1freesec);
seek(ff,$8e2); read(ff,p.zxdisk.ntr1freesec);

    seek(ff,bpos(p.zxdisk.nTr1freeSec,p.zxdisk.n1freeSec));
    truncate(ff);
    close(ff);
{$I+}
    if ioresult<>0 then;
    reMDF;
    p.TrueCur; p.Inside;{}
    reInfo('cbdnsfi');
    rePDF;
   end;
 end;
end;





{============================================================================}
procedure AltRPressed(var p:TPanel);
type
    tbuf=array[1..1] of byte;
var
    a,b,i:integer; ss,t:string;
    buf:^tbuf;
    ff:file;
    hbuf:array[1..17] of byte;
    nr,nw:word;
    h:byte;
begin
case p.paneltype of
 pcPanel:
   begin
    if p.pcfrom+p.pcf-1<=p.pctdirs then exit;
    ss:=p.pcnd+p.pcdir^[p.pcfrom+p.pcf-1].fname+'.'+p.pcdir^[p.pcfrom+p.pcf-1].fext;
    if ss[length(ss)]='.' then delete(ss,length(ss),1);
    if ithobeta(ss,hobetainfo) then
     begin
      t:='Function: Remove HOBETA Header'#255'Continue?';
      if not cquestion(t,lang) then exit;
{$I-}
      getmem(buf,p.pcdir^[p.pcfrom+p.pcf-1].flength);
      assign(ff,ss); filemode:=2; reset(ff,1); seek(ff,17);
      blockread(ff,buf^,p.pcdir^[p.pcfrom+p.pcf-1].flength,nr);
      seek(ff,0);
      blockwrite(ff,buf^,nr,nw);
      if hobetainfo.typ='B' then seek(ff,hobetainfo.length+4) else seek(ff,hobetainfo.length);
      truncate(ff);
      close(ff);
      if TRDOS3
        then t:=getof(ss,_name)+'.'+hobetainfo.typ+chr(lo(hobetainfo.start))+chr(hi(hobetainfo.start))
        else
         begin
          t:=getof(ss,_name)+nospace(getof(ss,_ext)+'!');
          if hobetainfo.length=6912 then t:=getof(ss,_name)+'.scr';
          if hobetainfo.length=18432 then t:=getof(ss,_name)+'.xpc';
          if (hobetainfo.typ='Z')and(hobetainfo.start=20553) then t:=getof(ss,_name)+'.zxz';
         end;
      rename(ff,p.pcnd+t);
      freemem(buf,p.pcdir^[p.pcfrom+p.pcf-1].flength);
{$I+}
      if ioresult<>0 then;
      p.pcnn:=strlo(nospace(t));

      reMDF;
      p.TrueCur; p.Inside;{}
      reInfo('cbdnsfi');
      rePDF;
     end
    else
     begin
      if p.pcdir^[p.pcfrom+p.pcf-1].flength<=65280 then
       begin
        t:='Function: Add HOBETA Header'#255'Continue?';
        if not cquestion(t,lang) then exit;
{$I-}
        hbuf[15]:=p.pcdir^[p.pcfrom+p.pcf-1].flength div 256;
        if 256*hbuf[15]<lp.pcdir^[p.pcfrom+p.pcf-1].flength then inc(hbuf[15]);

        getmem(buf,256*hbuf[15]); for nr:=1 to 256*hbuf[15] do buf^[nr]:=0;
        assign(ff,ss); filemode:=2; reset(ff,1);
        blockread(ff,buf^,p.pcdir^[p.pcfrom+p.pcf-1].flength,nr);
        close(ff); erase(ff);

        t:=strlo(p.pcdir^[p.pcfrom+p.pcf-1].fname); t:=t+space(8-length(t));
        for b:=1 to 8 do hbuf[b]:=ord(t[b]);
         if TRDOS3 then
          begin
           hbuf[9]:=ord(dncase(p.pcdir^[p.pcfrom+p.pcf-1].fext[1]));
           hbuf[10]:=ord(dncase(p.pcdir^[p.pcfrom+p.pcf-1].fext[2]));
           hbuf[11]:=ord(dncase(p.pcdir^[p.pcfrom+p.pcf-1].fext[3]));
          end
         else
          begin
           hbuf[9]:=ord('C');
           hbuf[10]:=lo(HobetaStartAddr);
           hbuf[11]:=hi(HobetaStartAddr);
           if p.pcDir^[p.Index].flength=6912 then
            begin
             hbuf[10]:=lo(16384);
             hbuf[11]:=hi(16384);
            end;
           if strlo(p.pcDir^[p.Index].fext)='zxz' then
            begin
             hbuf[9]:=ord('Z');
             hbuf[10]:=lo(20553);
             hbuf[11]:=hi(20553);
            end;
          end;
         hbuf[12]:=lo(p.pcdir^[p.pcfrom+p.pcf-1].flength);
         hbuf[13]:=hi(p.pcdir^[p.pcfrom+p.pcf-1].flength);
         hbuf[14]:=0;
         if (buf^[p.pcdir^[p.pcfrom+p.pcf-1].flength-3]=$80)and(buf^[p.pcdir^[p.pcfrom+p.pcf-1].flength-2]=$AA) then
          begin
           hbuf[9]:=ord('B');
           hbuf[10]:=lo(p.pcdir^[p.pcfrom+p.pcf-1].flength-4);
           hbuf[11]:=hi(p.pcdir^[p.pcfrom+p.pcf-1].flength-4);
           hbuf[12]:=lo(p.pcdir^[p.pcfrom+p.pcf-1].flength-4);
           hbuf[13]:=hi(p.pcdir^[p.pcfrom+p.pcf-1].flength-4);
          end;
         nw:=0; for b:=1 to 15 do nw:=nw+257*hbuf[b]+(b-1);
         hbuf[16]:=lo(nw);
         hbuf[17]:=hi(nw);

         if TRDOS3
          then t:=p.pcdir^[p.pcfrom+p.pcf-1].fname+'.$'+p.pcdir^[p.pcfrom+p.pcf-1].fext[1]
          else
           begin
            t:=p.pcdir^[p.pcfrom+p.pcf-1].fname+'.$c';
            if hbuf[9]=ord('Z') then t:=p.pcdir^[p.pcfrom+p.pcf-1].fname+'.$z';
            if hbuf[9]=ord('B') then t:=p.pcdir^[p.pcfrom+p.pcf-1].fname+'.$b';
           end;
         assign(ff,p.pcnd+t);
         filemode:=2; rewrite(ff,1);

         blockwrite(ff,hbuf,17,nw);{}
         blockwrite(ff,buf^,256*hbuf[15],nw);
{         seek(ff,256*hbuf[15]-1+17); h:=0; blockwrite(ff,h,1,nw);{}
         close(ff);
         freemem(buf,256*hbuf[15]);
{$I+}
         if ioresult<>0 then;
         p.pcnn:=strlo(nospace(t));

         reMDF;
         p.TrueCur; p.Inside;{}
         reInfo('cbdnsfi');
         rePDF;
     end;
   end;
end;
end;
end;


{============================================================================}
Var  UserOut:boolean;
     AllSectors:word;


{============================================================================}
function noHobCopy(flag,i:word; sp,dp:TPanel):boolean;
var totalsec:word; s:string;
{----------------------------------------------------------------------------}
function pscanf2(scanf_posx, scanf_posy:byte;
               scanf_str:string;
               scanf_total, scanf_visible,
               scanf_cur:byte):string;
var
     scanf_kod:char;
     scanf_x, scanf_from:byte;
     scanf_str_old:string;
label loop,loop2;
begin
scanf_esc:=false;
scanf_str_old:=scanf_str;
scanf_str:=scanf_str+space(scanf_total-length(scanf_str));
scanf_x:=scanf_cur;
scanf_from:=1;
if scanf_visible>length(scanf_str) then scanf_visible:=length(scanf_str);

loop:
mprint(scanf_posx,scanf_posy,copy(scanf_str,scanf_from,scanf_visible));
gotoxy(scanf_posx+scanf_x-scanf_from,scanf_posy);
scanf_kod:=readkey;
if scanf_kod=#27 then begin pscanf2:=scanf_str_old; scanf_esc:=true; exit; end;
if scanf_kod=#13 then
 begin
  if vall(nospace(scanf_str))>255 then Begin scanf_str:='255 '; scanf_x:=4; goto loop; End;
  if vall(nospace(scanf_str))<1 then   Begin scanf_str:='1   '; scanf_x:=2; goto loop; End;

  pscanf2:=scanf_str;
  exit;
 end;

if ((scanf_kod)>=' ')and((scanf_kod)<='я')and(scanf_x<=length(scanf_str)) then
 begin
  scanf_str[scanf_x]:=scanf_kod;
  inc(scanf_x);
  if scanf_x-scanf_from>scanf_visible then inc(scanf_from);
  if scanf_x>length(scanf_str)+1 then scanf_x:=length(scanf_str)+1;
 end;

if scanf_kod=#8 then
 begin
  scanf_str:=copy(scanf_str,1,scanf_x-2)+copy(scanf_str,scanf_x,length(scanf_str));
  dec(scanf_x);
  if scanf_x<scanf_from then dec(scanf_from);
  if scanf_x<1 then scanf_x:=1 else scanf_str:=scanf_str+' ';
  if scanf_from<1 then scanf_from:=1;
  if scanf_x<1 then scanf_x:=1;
 end;
{}
if scanf_kod=#25 then
 begin
  scanf_str:=space(scanf_total);
  scanf_from:=1;
  scanf_x:=1;
 end;

if scanf_kod=#0 then
 begin
  scanf_kod:=readkey;
  if scanf_kod=#71 then begin scanf_from:=1; scanf_x:=1; end;
  if scanf_kod=#79 then begin scanf_from:=scanf_total-scanf_visible+1; scanf_x:=length(nospaceLR(scanf_str))+1; end;
  if scanf_kod=#83 then scanf_str:=copy(scanf_str,1,scanf_x-1)+copy(scanf_str,scanf_x+1,length(scanf_str))+' ';{}
  if scanf_kod=#77 then
   begin
    inc(scanf_x);
    if scanf_x-scanf_from>scanf_visible then inc(scanf_from);
   end;
  if scanf_kod=#75 then
   begin
    dec(scanf_x);
    if scanf_x<scanf_from then dec(scanf_from);
   end;

  if scanf_from<1 then scanf_from:=1;
  if scanf_x<1 then scanf_x:=1;
  if scanf_x>length(scanf_str)+1 then begin scanf_x:=length(scanf_str)+1; dec(scanf_from); end;
  if scanf_posx+scanf_x>gmaxx then scanf_x:=gmaxx-scanf_posx;
 end;

goto loop;
end;
{----------------------------------------------------------------------------}
Var
    wtf:word; tff,ts1f:byte; l:longint; k,w:word;
    f:file;
Begin
noHobCopy:=false;
if itHobeta(pcndOf(focus)+TrueNameOf(focus,i),HobetaInfo) then exit;
if i<=sp.pctdirs then exit;

if not noHobCopyBlockSizeSet then
Begin
CancelSB; colour(pal.bkdRama,pal.txtdRama);
scputwin(pal.bkdRama,pal.txtdRama,23,halfmaxy-5,57,halfmaxy-3+6);
cmcentre(pal.bkdRama,pal.txtdRama,halfmaxy-5,' Confirmation ');
StatusLineColor(pal.bkdLabelST,pal.txtdLabelST,pal.bkdLabelNT,pal.txtdLabelNT,27,halfmaxy-3,
                                 'Copy not Hobeta file');
s:=(TrueNameOf(focus,i));
StatusLineColor(pal.bkdLabelST,pal.txtdLabelST,pal.bkdLabelNT,pal.txtdLabelNT,40-(length(s)div 2),halfmaxy-2,
                ''+s+'');
StatusLineColor(pal.bkdLabelST,pal.txtdLabelST,pal.bkdLabelNT,pal.txtdLabelNT,27,halfmaxy-1,
                                 'blocks size of      sectors ');
colour(pal.bkdLabelNT,pal.txtdLabelNT);
cbutton(pal.bkdButtonA,pal.txtdButtonA,pal.bkdButtonShadow,pal.txtdButtonShadow,36,halfmaxy+1,'    OK    ',true);
colour(pal.bkdInputNT,pal.txtdInputNT); curon;
s:=strhi(nospace(pscanf2(42,halfmaxy-1,strr(noHobCopyBlockSize),4,4,1))); curoff; restscr;
ts1f:=vall(nospace(s));
noHobCopyBlockSize:=ts1f;
End else ts1f:=noHobCopyBlockSize;


if scanf_esc then exit;

totalsec:=sp.pcDir^[i].flength div 256; l:=totalsec; l:=256*l;
tff:=totalsec div ts1f;

if sp.pcDir^[i].flength-l>0 then inc(totalsec);

if (dp.PanelType=trdPanel)or(dp.PanelType=fddPanel)or(dp.PanelType=fdiPanel)or(dp.PanelType=flpPanel) then
if totalsec>dp.zxdisk.free then
 begin
  errormessage('Not enough space for this file');
  UserOut:=true;
  exit;
 end;

wtf:=totalsec div ts1f;
if totalsec-wtf*ts1f>0 then inc(wtf);

if dp.zxdisk.files+wtf>128 then
 begin
  errormessage('It would be to many files');
  UserOut:=true;
  exit;
 end;

{$I-}
assign(f,sp.pcnd+sp.TrueName(i)); filemode:=0; reset(f,1);

w:=0;


if sp.pcDir^[i].flength<>l then
for k:=1 to tff do
 Begin
  getmem(HobetaInfo.body,256*ts1f);

  blockRead(f,HobetaInfo.body^,256*ts1f);
  HobetaInfo.name:=strlo(sp.pcDir^[i].fname);
  s:=LZZ(w);
  if dp.PanelType=tapPanel then
   Begin
    HobetaInfo.name:=sRexpand(HobetaInfo.name,10);
    HobetaInfo.name[10]:=s[3];
    HobetaInfo.name[9]:=s[2];
    HobetaInfo.name[8]:=s[1];
   End
  else
   Begin
    HobetaInfo.name:=sRexpand(HobetaInfo.name,8);
    if noHobNaming=0 then
     Begin
      HobetaInfo.name[8]:=s[3];
      HobetaInfo.name[7]:=s[2];
      HobetaInfo.name[6]:=s[1];
     End;
   End;
  if TRDOS3 then
   Begin
    HobetaInfo.typ:=DnCase(sp.pcDir^[i].fext[1]);
    HobetaInfo.start:=ord(DnCase(sp.pcDir^[i].fext[2]))+256*ord(DnCase(sp.pcDir^[i].fext[3]));
    if (w>0)and(noHobNaming=1) then HobetaInfo.typ:=chr(w+47);
   End
  else
   Begin
    HobetaInfo.typ:='C'; HobetaInfo.start:=HobetaStartAddr;
    if (w>0)and(noHobNaming=1) then HobetaInfo.typ:=chr(w+47);
   End;
  HobetaInfo.totalsec:=ts1f;
  HobetaInfo.length:=256*ts1f;

  Case dp.PanelType of
   trdPanel: trdSave(dp);
   fdiPanel: fdiSave(dp);
   sclPanel: sclSave(dp);
   fddPanel: fddSave(dp);
   tapPanel: tapSave(dp);
   zxzPanel: zxzSave(dp);
   flpPanel: flpSave(dp,dp.flpDrive);
  End;

  inc(w);
 End;

  if sp.pcDir^[i].flength<>l then HobetaInfo.totalsec:=totalsec-tff*ts1f
                             else HobetaInfo.totalsec:=totalsec;
  getmem(HobetaInfo.body,256*HobetaInfo.totalsec);
  for k:=1 to 256*HobetaInfo.totalsec do HobetaInfo.body^[k]:=0;
  blockRead(f,HobetaInfo.body^,65280);
  HobetaInfo.name:=strlo(sp.pcDir^[i].fname);
  s:=LZZ(w);
  if dp.PanelType=tapPanel then
   Begin
    HobetaInfo.name:=sRexpand(HobetaInfo.name,10);
    if w>0 then
     begin
      HobetaInfo.name[10]:=s[3];
      HobetaInfo.name[9]:=s[2];
      HobetaInfo.name[8]:=s[1];
     end;
   End
  else
   Begin
    HobetaInfo.name:=sRexpand(HobetaInfo.name,8);
    if w>0 then
     begin
      if noHobNaming=0 then
       Begin
        HobetaInfo.name[8]:=s[3];
        HobetaInfo.name[7]:=s[2];
        HobetaInfo.name[6]:=s[1];
       End;
     end;
   End;
  if TRDOS3 then
   Begin
    HobetaInfo.typ:=DnCase(sp.pcDir^[i].fext[1]);
    HobetaInfo.start:=ord(DnCase(sp.pcDir^[i].fext[2]))+256*ord(DnCase(sp.pcDir^[i].fext[3]));
    if (w>0)and(noHobNaming=1) then HobetaInfo.typ:=chr(w+47);
   End
  else
   Begin
    HobetaInfo.typ:='C'; HobetaInfo.start:=HobetaStartAddr;
    if (w>0)and(noHobNaming=1) then HobetaInfo.typ:=chr(w+47);
   End;
  if sp.pcDir^[i].flength<>l then HobetaInfo.length:=sp.pcDir^[i].flength-tff*(256*ts1f)
                             else HobetaInfo.length:=l;

close(f);

  Case dp.PanelType of
   trdPanel: trdSave(dp);
   fdiPanel: fdiSave(dp);
   sclPanel: sclSave(dp);
   fddPanel: fddSave(dp);
   tapPanel: tapSave(dp);
   zxzPanel: zxzSave(dp);
   flpPanel: flpSave(dp,dp.flpDrive);
  End;
{$I+}

if IOResult=0 then
 begin
  noHobCopy:=true; sp.pcDir^[i].mark:=false;
  if flag=_F6 then filedelete(sp.pcnd+sp.TrueName(i));{}
 end;

dp.MDF; reInfo('sf');{ rePDF;{}
End;



{============================================================================}
Procedure snCopier(flag:word; SourcePanel,DestPanel:byte);
Var
    TargetPath,stemp:string;
    skip:boolean;
    tc,wasc,i:word;
    loaded,saved,bool:boolean;
    q:char;
Label fin;
Begin
 noHobCopyBlockSizeSet:=false;
 noHobCopyBlockSize:=255;

 Case focus of
  left:  i:=lp.trdDir^[lp.Index].tapflag;
  right: i:=rp.trdDir^[rp.Index].tapflag;
 End;
 if (SourcePanel=tapPanel)and(DestPanel<>tapPanel)and(InsedOf(focus)=0)and(i=0) then exit;

 if WillCopyMove(flag,TargetPath,skip) then
  BEGIN

   if InsedOf(focus)=0 then
    if PanelTypeOf(focus)=pcPanel then
     Case focus of
      left:  lp.pcDir^[lp.Index].mark:=true;
      right: rp.pcDir^[rp.Index].mark:=true;
     End
    else
     Case focus of
      left:  lp.trdDir^[lp.Index].mark:=true;
      right: rp.trdDir^[rp.Index].mark:=true;
     End;


   if Moused then MouseOff;
   Colour(pal.bkdRama,pal.txtdRama); sPutWin(halfmaxx-20,halfmaxy-4,halfmaxx+21,halfmaxy+2);
   cmcentre(pal.bkdRama,pal.txtdRama,halfmaxy-4,' Copy ');

   AllSectors:=0;
   for i:=1 to tdirsfilesOf(focus) do
    begin
     if PanelTypeOf(focus)=pcPanel then bool:=pcDirMarkOf(focus,i) else bool:=trdDirMarkOf(focus,i);
     if bool then
      Begin
       if SourcePanel=pcPanel then
        begin
         stemp:=pcndOf(focus)+TrueNameOf(focus,i);
         if itHobeta(stemp,HobetaInfo) then Inc(AllSectors,HobetaInfo.totalsec)
         else
          begin
           Inc(AllSectors,(filelen(stemp)div 256));
           if filelen(stemp)>(256*(filelen(stemp)div 256)) then Inc(AllSectors);
          end;
        end
       else
        begin
         if focus=left then inc(AllSectors,lp.trdDir^[i].totalsec)
                       else inc(AllSectors,rp.trdDir^[i].totalsec);
        end;
      End;
    end;

   less:=0; wasc:=1;
   if focus=left then tc:=lp.Insed else tc:=rp.Insed;
   for i:=1 to tdirsfilesOf(focus) do
    begin

     if keypressed then
      begin
       q:=readkey;
       stemp:='Stop operation?';
       if q=#27 then if cquestion(stemp,lang) then begin userout:=true; break; end;
      end;

     if PanelTypeOf(focus)=pcPanel then bool:=pcDirMarkOf(focus,i) else bool:=trdDirMarkOf(focus,i);
     if bool then
      Begin

       CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,halfmaxy-0,
            '  Copying '+strr(wasc)+' of '+strr(tc)+'  '
                       );

       Case focus of
        left:
          BEGIN

           if SourcePanel=pcPanel then
           CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,halfmaxy-2,
               space(8)+TrueNameOf(left,i)+space(8)
                           )
                                  else
           CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,halfmaxy-2,
               lp.trdDir^[i].name+'.'+TRDOSe3(lp,i)
                           );

           loaded:=false; UserOut:=false;
           {What to LOAD?}
           Case SourcePanel of
            pcPanel:  if hobLoad(pcndOf(focus)+TrueNameOf(focus,i)) then loaded:=true;
            trdPanel: if trdLoad(lp,i) then loaded:=true;
            fdiPanel: if fdiLoad(lp,i) then loaded:=true;
            sclPanel: if sclLoad(lp,i) then loaded:=true;
            fddPanel: if fddLoad(lp,i) then loaded:=true;
            tapPanel: if tapLoad(lp,i) then loaded:=true;
            zxzPanel: if zxzLoad(lp,i) then loaded:=true;
            flpPanel: if flpLoad(lp,i,lp.flpDrive) then loaded:=true;
           End;
           {What to SAVE?}
           if (not loaded)and(SourcePanel=pcPanel)and(DestPanel<>pcPanel) then
            begin
             noHobCopy(flag,i,lp,rp);
             noHobCopyBlockSizeSet:=true;
             if UserOut then goto fin;
            end;
           if loaded then
            Begin
             UserOut:=false;
     {-->}   if (DestPanel<1)or(DestPanel>10) then
              begin
               if CheckDir(TargetPath)<>0 then CreateDir(TargetPath);
               hobSave(TargetPath,AltF5Pressed);
              end;
     {-->}   if (DestPanel=trdPanel)or(DestPanel=fdiPanel)or(DestPanel=fddPanel)or(DestPanel=flpPanel) then
              Begin
               if rp.zxdisk.files+1>128 then
                 begin errormessage('To many files'); UserOut:=true; end;
               if rp.zxdisk.free<HobetaInfo.totalsec then
                 begin errormessage('Disk full'); UserOut:=true; end;
              End;
     {-->}   if DestPanel=sclPanel then
              Begin
               if rp.zxdisk.files+1>128 then
                 begin errormessage('To many files'); UserOut:=true; end;
               if DiskFree(ord(UpCase(rp.sclfile[1]))-64)<256*HobetaInfo.totalsec then
                 begin errormessage('Disk full'); UserOut:=true; end;
              End;
     {-->}   if DestPanel=tapPanel then
              Begin
               if rp.zxdisk.files+1>256 then
                 begin errormessage('To many files'); UserOut:=true; end;
               if DiskFree(ord(UpCase(rp.tapfile[1]))-64)<HobetaInfo.length then
                 begin errormessage('Disk full'); UserOut:=true; end;
              End;

             if not UserOut then Case DestPanel of
              sclPanel: sclSave(rp);
              pcPanel:
                BEGIN
                 if CheckDir(TargetPath)<>0 then CreateDir(TargetPath);
                 if not hob2scl then hobSave(TargetPath,AltF5Pressed)
                            else
                             begin
                              if CheckDirFile(rp.sclfile)<>0 then
                               if not sclMakeImage(true) then
                                Begin
                                 FreeMem(HobetaInfo.body,256*HobetaInfo.totalsec);
                                 UserOut:=true;
                                 Break;
                                End else
                                begin
                                rp.sclMDFs(rp.sclfile);
                                end;
                              rp.pcnn:=strlo(GetOf(rp.sclfile,_name))+'.scl';
                              rp.PanelType:=sclPanel;
                              sclSave(rp);
                              rp.sclfrom:=1; rp.sclf:=1;
                             end;
                END;
              trdPanel: trdSave(rp);
              fdiPanel: fdiSave(rp);
              sclPanel: sclSave(rp);
              fddPanel: fddSave(rp);
              tapPanel: tapSave(rp);
              zxzPanel: zxzSave(rp);
              flpPanel: flpSave(rp,rp.flpDrive);
             End else FreeMem(HobetaInfo.body,256*HobetaInfo.totalsec);
             if UserOut then break;
             lp.pcDir^[i].mark:=false; lp.trdDir^[i].mark:=false;
             if flag=_F6 then filedelete(lp.pcnd+lp.TrueName(i));
            End;
          END;
        right:
          BEGIN
           if SourcePanel=pcPanel then
           CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,halfmaxy-2,
               space(8)+TrueNameOf(right,i)+space(8)
                           )
                                  else
           CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,halfmaxy-2,
               rp.trdDir^[i].name+'.'+TRDOSe3(rp,i)
                           );

           {What to LOAD?}
           loaded:=false; UserOut:=false;
           Case SourcePanel of
            pcPanel:  if hobLoad(pcndOf(focus)+TrueNameOf(focus,i)) then loaded:=true;
            trdPanel: if trdLoad(rp,i) then loaded:=true;
            fdiPanel: if fdiLoad(rp,i) then loaded:=true;
            sclPanel: if sclLoad(rp,i) then loaded:=true;
            fddPanel: if fddLoad(rp,i) then loaded:=true;
            tapPanel: if tapLoad(rp,i) then loaded:=true;
            zxzPanel: if zxzLoad(rp,i) then loaded:=true;
            flpPanel: if flpLoad(rp,i,rp.flpDrive) then loaded:=true;
           End;
           {What to SAVE?}
           if (not loaded)and(SourcePanel=pcPanel)and(DestPanel<>pcPanel) then
            begin
             noHobCopy(flag,i,rp,lp);
             noHobCopyBlockSizeSet:=true;
             if UserOut then goto fin;
            end;
           if loaded then
            Begin
             UserOut:=false;
     {-->}   if (DestPanel<1)or(DestPanel>10) then
              begin
               if CheckDir(TargetPath)<>0 then CreateDir(TargetPath);
               hobSave(TargetPath,AltF5Pressed);
              end;
     {-->}   if (DestPanel=trdPanel)or(DestPanel=fdiPanel)or(DestPanel=fddPanel)or(DestPanel=flpPanel) then
              Begin
               if lp.zxdisk.files+1>128 then
                 begin errormessage('To many files'); UserOut:=true; end;
               if lp.zxdisk.free<HobetaInfo.totalsec then
                 begin errormessage('Disk full'); UserOut:=true; end;
              End;
     {-->}   if DestPanel=sclPanel then
              Begin
               if lp.zxdisk.files+1>128 then
                 begin errormessage('To many files'); UserOut:=true; end;
               if DiskFree(ord(UpCase(lp.sclfile[1]))-64)<256*HobetaInfo.totalsec then
                 begin errormessage('Disk full'); UserOut:=true; end;
              End;
     {-->}   if DestPanel=tapPanel then
              Begin
               if lp.zxdisk.files+1>256 then
                 begin errormessage('To many files'); UserOut:=true; end;
               if DiskFree(ord(UpCase(lp.tapfile[1]))-64)<HobetaInfo.length then
                 begin errormessage('Disk full'); UserOut:=true; end;
              End;

             if not UserOut then Case DestPanel of
              pcPanel:
                BEGIN
                 if CheckDir(TargetPath)<>0 then CreateDir(TargetPath);
                 if not hob2scl then hobSave(TargetPath,AltF5Pressed)
                            else
                             begin
                              if CheckDirFile(lp.sclfile)<>0 then
                               if not sclMakeImage(true) then
                                Begin
                                 FreeMem(HobetaInfo.body,256*HobetaInfo.totalsec);
                                 UserOut:=true;
                                 Break;
                                End else
                                begin
                                lp.sclMDFs(lp.sclfile);
                                end;
                              lp.pcnn:=strlo(GetOf(lp.sclfile,_name))+'.scl';
                              lp.PanelType:=sclPanel;
                              sclSave(lp);
                              lp.sclfrom:=1; lp.sclf:=1;
                             end;
                END;
              trdPanel: trdSave(lp);
              fdiPanel: fdiSave(lp);
              sclPanel: sclSave(lp);
              fddPanel: fddSave(lp);
              tapPanel: tapSave(lp);
              zxzPanel: zxzSave(lp);
              flpPanel: flpSave(lp,lp.flpDrive);
             End else FreeMem(HobetaInfo.body,256*HobetaInfo.totalsec);
             if UserOut then break;
             rp.pcDir^[i].mark:=false; rp.trdDir^[i].mark:=false;
             if flag=_F6 then filedelete(rp.pcnd+rp.TrueName(i));
            End;
          END;
       End;

       if refresh then begin reInfo('sf'); end;
       inc(wasc);

      End;
    end;

fin:
   RestScr;
   reMDF; reTrueCur; lp.Inside; lp.Outside;  rp.Inside; rp.Outside;
   if focus=left then lp.Inside else rp.Inside;
   reInfo('cbdnsfi');  rePDF;
  END;
End;





{============================================================================}
procedure snEraser(var p:TPanel);
Var
    s:string;
Begin
if p.PanelType=zxzPanel then exit;

if (p.Insed=0)and(p.Index<=1) then exit;
if ((ord(p.trddir^[p.Index].name[1])=1)or(ord(p.trddir^[p.Index].name[1])=0))and(p.Insed=0) then exit;

if p.Insed=0 then s:=p.trddir^[p.Index].name+'.'+TRDOSe3(p,p.Index);
if p.Insed=1 then s:=p.trddir^[p.FirstMarked].name+'.'+TRDOSe3(p,p.FirstMarked);

if p.PanelType=tapPanel then
 Begin
  if (p.Insed=0)and(PanelTypeOf(oFocus)<>tapPanel)and(p.trdDir^[p.Index].tapflag=0) then exit;
  if p.Insed=0 then
   if PanelTypeOf(oFocus)=tapPanel
      then if p.trdDir^[p.Index].tapflag=0
              then s:=p.trdDir^[p.Index].name
              else s:='codes'
      else if p.Index>2
              then if p.trdDir^[p.Index-1].tapflag<>0
                      then s:='less'
                      else s:=p.trdDir^[p.Index-1].name
              else s:='less';

  if p.Insed=1 then
   if PanelTypeOf(oFocus)=tapPanel
      then if p.trdDir^[p.FirstMarked].tapflag=0
              then s:=p.trdDir^[p.FirstMarked].name
              else s:='codes'
      else if p.FirstMarked>2
              then if p.trdDir^[p.FirstMarked-1].tapflag<>0
                      then s:='less'
                      else s:=p.trdDir^[p.FirstMarked-1].name
              else s:='less';

  if PanelTypeOf(oFocus)=tapPanel then
   BEGIN
    s:='Do you wish to delete'#255'item "'+s+'" ?';

    if p.Insed>1 then s:='Do you wish to delete'#255'this items ?';
   END
  else
   BEGIN
    s:='Do you wish to delete'#255'file "'+s+'" ?';

    if p.Insed>1 then s:='Do you wish to delete'#255'this files ?';
  END;
 End
else
 Begin
  s:='Do you wish to delete'#255'file "'+s+'" ?';

  if p.Insed>1 then s:='Do you wish to delete'#255'this files ?';
 End;

CancelSB;
if cquestion(s,lang) then
 begin
  if p.Insed=0 then p.trddir^[p.Index].mark:=true;
  Case p.PanelType of
   trdPanel: trdDel(p);
   fdiPanel: fdiDel(p);
   fddPanel: fddDel(p);
   sclPanel: sclDel(p);
   tapPanel: tapDel(p);
   flpPanel: flpDel(p,p.flpDrive);
  End;
  reMDF;
  lp.TrueCur; lp.InSide;
  rp.TrueCur; rp.InSide;
  reInfo('cbdnsfi'); rePDF;
 end;
End;




{============================================================================}
Procedure zxEditParam(p:TPanel; ind:integer);
var i,y:integer; s0,s:string; EditFileParam:boolean;

type TEdit=record
            disklabel:string[8];
            files:string[3];
            delfiles:string[3];
            disktype:byte;
            free:string[4];
            nTr1FreeSec:string[3];
            n1FreeSec:string[3];

            name:string[8];
            typ:string[1];
            totalsec:string[3];
            start:string[5];
            len:string[5];
            line:string[4];
            n1tr:string[3];
            n1sec:string[3];
           end;
var  Edit:TEdit;


function BasLine(var p:TPanel; i:integer):word;
var f:file; w:word;
Begin
{$I-}
  GetMem(HobetaInfo.body,256*p.trdDir^[i].totalsec);
  if CheckDirFile(nospace(p.trdfile))<>0 then p.trdfile:=p.pcnd+p.pcnn;
  assign(f,p.trdfile); filemode:=0; reset(f,1);
  seek(f,bpos(p.trdDir^[i].n1tr,p.trdDir^[i].n1sec));
  blockread(f,HobetaInfo.body^,256*p.trdDir^[i].totalsec);
  close(f);
  if IOResult<>0 then;
{$I+}

  w:=256*HobetaInfo.body^[p.trdDir^[i].length+4]
        +HobetaInfo.body^[p.trdDir^[i].length+3];
  basline:=w;

  FreeMem(HobetaInfo.body,256*p.trdDir^[i].totalsec);
End;

procedure PutParams;
begin
  cmPrint(menu_bkNT,menu_txtNT,31,y-4,edit.disklabel);

  s:=edit.files; s:=fill(3-length(s),'0')+s;
  cmPrint(menu_bkNT,menu_txtNT,24,y-3,s);

Case edit.diskType of
 22: cmPrint(menu_bkNT,menu_txtNT,42,y-3,'80 Track D. Side');
 23: cmPrint(menu_bkNT,menu_txtNT,42,y-3,'80 Track S. Side');
 24: cmPrint(menu_bkNT,menu_txtNT,42,y-3,'40 Track D. Side');
 25: cmPrint(menu_bkNT,menu_txtNT,42,y-3,'40 Track S. Side');
End;

  s:=edit.delfiles; s:=fill(3-length(s),'0')+s;
  cmPrint(menu_bkNT,menu_txtNT,24,y-2,s);

  s:=edit.free; s:=fill(4-length(s),'0')+s;
  cmPrint(menu_bkNT,menu_txtNT,54,y-2,s);

  s:=edit.nTr1FreeSec; s:=fill(3-length(s),'0')+s;
  cmPrint(menu_bkNT,menu_txtNT,37,y-1,s);

  s:=edit.n1FreeSec; s:=fill(3-length(s),'0')+s;
  cmPrint(menu_bkNT,menu_txtNT,55,y-1,s);

if EditFileParam then
 Begin
  cmPrint(menu_bkNT,menu_txtNT,24,y+2,edit.name);
  cmPrint(menu_bkNT,menu_txtNT,33,y+2,'<'+edit.typ+'>');
  s:=edit.totalsec; s:=fill(3-length(s),'0')+s;
  cmPrint(menu_bkNT,menu_txtNT,37,y+2,s);
  s:=edit.start; s:=fill(5-length(s),'0')+s;
  cmPrint(menu_bkNT,menu_txtNT,41,y+2,s);
  s:=edit.len; s:=fill(5-length(s),'0')+s;
  cmPrint(menu_bkNT,menu_txtNT,48,y+2,s);
  s:=edit.line; s:=fill(4-length(s),'0')+s;
  cmPrint(menu_bkNT,menu_txtNT,54,y+2,s);

  s:=edit.n1Tr; s:=fill(3-length(s),'0')+s;
  cmPrint(menu_bkNT,menu_txtNT,34,y+3,s);

  s:=edit.n1Sec; s:=fill(3-length(s),'0')+s;
  cmPrint(menu_bkNT,menu_txtNT,52,y+3,s);
 End;
end;



function edit1(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
printself(pal.bkdInputNT,pal.txtdInputNT,31,y-4,8);
curon;
scanf_tab_enable:=true;
edit1:=scanf(31,y-4,str,8,8,1);
end;

function edit2(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
scanf_tab_enable:=true;
edit2:=scanf(24,y-3,str,3,3,1);
end;




function edit3:byte;
var i:integer;
begin
scanf_tab_enable:=true;
menu_name[1]:='80 Track D. Side';
menu_name[2]:='80 Track S. Side';
menu_name[3]:='40 Track D. Side';
menu_name[4]:='40 Track S. Side';
menu_total:=4;
case edit.disktype of
 $16: menu_f:=1;
 $17: menu_f:=2;
 $18: menu_f:=3;
 $19: menu_f:=4;
end;
menu_posx:=halfmaxx+2; menu_posy:=halfmaxy-3;
curoff;
i:=ChooseItem;
 Case i of
  1: edit.disktype:=$16;
  2: edit.disktype:=$17;
  3: edit.disktype:=$18;
  4: edit.disktype:=$19;
 End;
curon;
end;

function edit4(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
scanf_tab_enable:=true;
edit4:=scanf(24,y-2,str,3,3,1);
end;

function edit5(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
scanf_tab_enable:=true;
edit5:=scanf(54,y-2,str,4,4,1);
end;

function edit6(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
scanf_tab_enable:=true;
edit6:=scanf(37,y-1,str,3,3,1);
end;


function edit7(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
scanf_tab_enable:=true;
edit7:=scanf(55,y-1,str,3,3,1);
end;


function edit8(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
scanf_tab_enable:=true;
edit8:=scanf(24,y+2,str,8,8,1);
end;

function edit9(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
scanf_tab_enable:=true;
edit9:=scanf(34,y+2,str,1,1,1);
end;

function edit10(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
scanf_tab_enable:=true;
edit10:=scanf(37,y+2,str,3,3,1);
end;

function edit11(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
scanf_tab_enable:=true;
edit11:=scanf(41,y+2,str,5,5,1);
end;

function edit12(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
scanf_tab_enable:=true;
edit12:=scanf(48,y+2,str,5,5,1);
end;


function edit13(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
scanf_tab_enable:=true;
edit13:=scanf(54,y+2,str,4,4,1);
end;


function edit14(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
scanf_tab_enable:=true;
edit14:=scanf(34,y+3,str,3,3,1);
end;


function edit15(str:string):string;
begin
colour(pal.bkdInputNT,pal.txtdInputNT);
scanf_tab_enable:=true;
edit15:=scanf(52,y+3,str,3,3,1);
end;




Label loop,fin;
var ce:byte;

    fb:file of byte;
    io,k,b:byte;
    buf:array[0..15]of byte;

function CheckPut:boolean;
begin
  if scanf_tab then inc(ce); if scanf_shtab then dec(ce);
  if EditFileParam then begin if ce<1 then ce:=15; if ce>15 then ce:=1; end
                   else begin if ce<1 then ce:=7; if ce>7 then ce:=1; end;
  PutParams;
CheckPut:=scanf_esc;
end;


Begin
EditFileParam:=true; if ind=1 then EditFileParam:=false;
CurOff; if Moused then MouseOff; y:=halfmaxy;

if EditFileParam then i:=y+4 else i:=y-0;

Colour(pal.bkdRama,pal.txtdRama);
sPutWin(40-18,y-5,40+19,i);
mCentre(y-5,' System information ');

mPrint(24,y-4,'Title:'); mPrint(45,y-4,'Disk Drive: '+p.pcnd[1]);
mPrint(28,y-3,'File(s)');

mPrint(28,y-2,'Del. File(s)');
mPrint(42,y-2,'Free Sector ');

mPrint(24,y-1,'1st Free Tr.');
mPrint(41,y-1,'1st Free Sec.');

if EditFileParam then
 Begin
  mPrint(40-18,y-0,'╟────────────────────────────────────╢');
  mPrint(26,y+1,'File Name      Start Length Line');

  mPrint(24,y+3,'1st Track');
  mPrint(41,y+3,'1st Sector');
 End;


 edit.disklabel:=p.zxdisk.disklabel;
 edit.files:=strr(p.zxdisk.files);
 edit.delfiles:=strr(p.zxdisk.delfiles);
 edit.disktype:=p.zxdisk.disktyp;
 edit.free:=strr(p.zxdisk.free);
 edit.nTr1FreeSec:=strr(p.zxdisk.nTr1FreeSec);
 edit.n1FreeSec:=strr(p.zxdisk.n1FreeSec);

  edit.name:=p.trdDir^[ind].name;
  edit.typ:=p.trdDir^[ind].typ;
  edit.totalsec:=strr(p.trdDir^[ind].totalsec);
  edit.start:=strr(p.trdDir^[ind].start);
  edit.len:=strr(p.trdDir^[ind].length);
  edit.line:=strr(BasLine(p,ind));
  edit.n1tr:=strr(p.trdDir^[ind].n1tr);
  edit.n1sec:=strr(p.trdDir^[ind].n1sec);


ce:=1;

loop:
PutParams;
 if ce=1 then
  begin
   edit.disklabel:=   edit1(edit.disklabel);
   CheckPut;
   if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
   scanf_tab:=false; scanf_shtab:=false;
  end;
 if ce=2 then
  begin
   edit.files:=       strr(vall(edit2(edit.files)));
   CheckPut;
   if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
   scanf_tab:=false; scanf_shtab:=false;
 end;
 if ce=3 then
  begin
   edit3;
   if scanf_esc then scanf_tab:=true;
   CheckPut;
   if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
   scanf_tab:=false; scanf_shtab:=false;
  end;
 if ce=4 then
  begin
   edit.delfiles:=    strr(vall(edit4(edit.delfiles)));
   CheckPut;
   if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
   scanf_tab:=false; scanf_shtab:=false;
  end;
 if ce=5 then
  begin
   edit.free:=        strr(vall(edit5(edit.free)));
   CheckPut;
   if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
   scanf_tab:=false; scanf_shtab:=false;
  end;
 if ce=6 then
  begin
   edit.nTr1FreeSec:= strr(vall(edit6(edit.nTr1FreeSec)));
   CheckPut;
   if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
   scanf_tab:=false; scanf_shtab:=false;
  end;
 if ce=7 then
  begin
   edit.n1FreeSec:=   strr(vall(edit7(edit.n1FreeSec)));
   CheckPut;
   if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
   scanf_tab:=false; scanf_shtab:=false;
  end;

if EditFileParam then
 Begin
  if ce=8 then
   begin
    edit.name:=     edit8(edit.name);
    CheckPut;
    if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
    scanf_tab:=false; scanf_shtab:=false;
   end;
  if ce=9 then
   begin
    edit.typ:=      edit9(edit.typ);
    CheckPut;
    if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
    scanf_tab:=false; scanf_shtab:=false;
   end;
  if ce=10 then
   begin
    edit.totalsec:= strr(vall(edit10(edit.totalsec)));
    CheckPut;
    if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
    scanf_tab:=false; scanf_shtab:=false;
   end;
  if ce=11 then
   begin
    edit.start:=    strr(vall(edit11(edit.start)));
    CheckPut;
    if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
    scanf_tab:=false; scanf_shtab:=false;
   end;
  if ce=12 then
   begin
    edit.len:=      strr(vall(edit12(edit.len)));
    CheckPut;
    if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
    scanf_tab:=false; scanf_shtab:=false;
   end;
  if (ce=13) then
   begin
    edit.line:=     strr(vall(edit13(edit.line)));
    CheckPut;
    if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
    scanf_tab:=false; scanf_shtab:=false;
   end;
  if ce=14 then
   begin
    edit.n1tr:=     strr(vall(edit14(edit.n1tr)));
    CheckPut;
    if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
    scanf_tab:=false; scanf_shtab:=false;
   end;
  if ce=15 then
   begin
    edit.n1sec:=    strr(vall(edit15(edit.n1sec)));
    CheckPut;
    if (not scanf_tab)and(not scanf_shtab) then goto fin;{}
    scanf_tab:=false; scanf_shtab:=false;
   end;
 End;

goto loop;

fin:
RestScr;
CurOff;

s:='Do you wish save changed'#255'system information?';

if not scanf_esc then if cquestion(s,LANG) then
 begin
  Case p.PanelType of
   trdPanel:
    Begin
    {$I-}
     assign(fb,p.trdfile); filemode:=2; reset(fb);
     seek(fb,$8e1); b:=vall(edit.n1freesec);   write(fb,b);
     seek(fb,$8e2); b:=vall(edit.ntr1freesec); write(fb,b);
     seek(fb,$8e3); b:=edit.disktype;          write(fb,b);
     seek(fb,$8e4); b:=vall(edit.files);       write(fb,b);
     seek(fb,$8e5); b:=lo(vall(edit.free));    write(fb,b);
     seek(fb,$8e6); b:=hi(vall(edit.free));    write(fb,b);
     seek(fb,$8f4); b:=vall(edit.delfiles);    write(fb,b);
     seek(fb,$8F5);
     for i:=1 to 8 do begin b:=ord(edit.disklabel[i]); write(fb,b); end;
    if EditFileParam then
     Begin
      seek(fb,16*(p.Index-2));
      for i:=1 to 8 do begin b:=ord(edit.name[i]); write(fb,b); end;
      b:=ord(edit.typ[1]);      write(fb,b);
      b:=lo(vall(edit.start));  write(fb,b);
      b:=hi(vall(edit.start));  write(fb,b);
      b:=lo(vall(edit.len));    write(fb,b);
      b:=hi(vall(edit.len));    write(fb,b);
      b:=vall(edit.totalsec);   write(fb,b);
      b:=vall(edit.n1sec);      write(fb,b);
      b:=vall(edit.n1tr);       write(fb,b);
     End;
     close(fb);
    {$I+}
    End;

   fdiPanel:
    Begin
    {$I-}
     assign(fb,p.trdfile); filemode:=2; reset(fb);
     seek(fb,p.fdiRec.offData+$8e1); b:=vall(edit.n1freesec);   write(fb,b);
     seek(fb,p.fdiRec.offData+$8e2); b:=vall(edit.ntr1freesec); write(fb,b);
     seek(fb,p.fdiRec.offData+$8e3); b:=edit.disktype;          write(fb,b);
     seek(fb,p.fdiRec.offData+$8e4); b:=vall(edit.files);       write(fb,b);
     seek(fb,p.fdiRec.offData+$8e5); b:=lo(vall(edit.free));    write(fb,b);
     seek(fb,p.fdiRec.offData+$8e6); b:=hi(vall(edit.free));    write(fb,b);
     seek(fb,p.fdiRec.offData+$8f4); b:=vall(edit.delfiles);    write(fb,b);
     seek(fb,p.fdiRec.offData+$8F5);
     for i:=1 to 8 do begin b:=ord(edit.disklabel[i]); write(fb,b); end;
    if EditFileParam then
     Begin
      seek(fb,p.fdiRec.offData+16*(p.Index-2));
      for i:=1 to 8 do begin b:=ord(edit.name[i]); write(fb,b); end;
      b:=ord(edit.typ[1]);      write(fb,b);
      b:=lo(vall(edit.start));  write(fb,b);
      b:=hi(vall(edit.start));  write(fb,b);
      b:=lo(vall(edit.len));    write(fb,b);
      b:=hi(vall(edit.len));    write(fb,b);
      b:=vall(edit.totalsec);   write(fb,b);
      b:=vall(edit.n1sec);      write(fb,b);
      b:=vall(edit.n1tr);       write(fb,b);
     End;
     close(fb);
    {$I+}
    End;

   fddPanel:
    Begin
     fddReadSector(p.fddfile,0,9);
     fddSectorBuf[$e1]:=vall(edit.n1freesec);
     fddSectorBuf[$e2]:=vall(edit.ntr1freesec);
     fddSectorBuf[$e3]:=edit.disktype;
     fddSectorBuf[$e4]:=vall(edit.files);
     fddSectorBuf[$e5]:=lo(vall(edit.free));
     fddSectorBuf[$e6]:=hi(vall(edit.free));
     fddSectorBuf[$f4]:=vall(edit.delfiles);
     for i:=1 to 8 do begin fddSectorBuf[$f5+i-1]:=ord(edit.disklabel[i]);end;
     fddWriteSector(p.fddfile,0,9);
     if EditFileParam then
      Begin
       i:=p.Index-1; b:=(i div 16)+1; if (i mod 16)=0 then dec(b);
       fddReadSector(p.fddfile,0,b);
       for io:=0 to 7 do buf[io]:=ord(edit.name[io+1]);
       buf[8]:=ord(edit.typ[1]);
       buf[9]:=lo(vall(edit.start));
       buf[10]:=hi(vall(edit.start));
       buf[11]:=lo(vall(edit.len));
       buf[12]:=hi(vall(edit.len));
       buf[13]:=vall(edit.totalsec);
       buf[14]:=vall(edit.n1sec);
       buf[15]:=vall(edit.n1tr);
       k:=i-(i div 16)*16; if k=0 then k:=16; k:=(k-1)*16;
       for io:=0 to 15 do fddSectorBuf[k+io]:=buf[io];{}
       fddWriteSector(p.fddfile,0,b);
      End;
    End;

   flpPanel:
    Begin
     if not InitFDD(Ord(UpCase(p.FlpDrive))-Ord('A'),CheckMedia) then exit;
     zxSeek(Ord(UpCase(p.FlpDrive))-Ord('A'),0);
     ReadSector(Ord(UpCase(p.FlpDrive))-Ord('A'),0,0,9,1);
     FDCBuf[$e1]:=vall(edit.n1freesec);
     FDCBuf[$e2]:=vall(edit.ntr1freesec);
     FDCBuf[$e3]:=edit.disktype;
     FDCBuf[$e4]:=vall(edit.files);
     FDCBuf[$e5]:=lo(vall(edit.free));
     FDCBuf[$e6]:=hi(vall(edit.free));
     FDCBuf[$f4]:=vall(edit.delfiles);
     for i:=1 to 8 do begin FDCBuf[$f5+i-1]:=ord(edit.disklabel[i]);end;
     WriteSector(Ord(UpCase(p.FlpDrive))-Ord('A'),0,0,9,1);
     if EditFileParam then
      Begin
       i:=p.Index-1; b:=(i div 16)+1; if (i mod 16)=0 then dec(b);
       ReadSector(Ord(UpCase(p.FlpDrive))-Ord('A'),0,0,b,1);
       for io:=0 to 7 do buf[io]:=ord(edit.name[io+1]);
       buf[8]:=ord(edit.typ[1]);
       buf[9]:=lo(vall(edit.start));
       buf[10]:=hi(vall(edit.start));
       buf[11]:=lo(vall(edit.len));
       buf[12]:=hi(vall(edit.len));
       buf[13]:=vall(edit.totalsec);
       buf[14]:=vall(edit.n1sec);
       buf[15]:=vall(edit.n1tr);
       k:=i-(i div 16)*16; if k=0 then k:=16; k:=(k-1)*16;
       for io:=0 to 15 do FDCBuf[k+io]:=buf[io];{}
       WriteSector(Ord(UpCase(p.FlpDrive))-Ord('A'),0,0,b,1);
      End;
    End;

  End;

  if ioresult=0 then;
  reMDF; reInfo('A'); rePDF;
 end;
End;



End.