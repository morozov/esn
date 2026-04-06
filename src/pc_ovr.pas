{$O+,F+}
Unit PC_Ovr;
Interface
Uses Crt,Dos,sn_Obj;

Procedure pcF7Pressed(path:string; w:byte);
Procedure pcDelete(ndpath:string; nm:pathstr; priory:byte; attr:byte);
Procedure pcF8;

Procedure pc2pc(flag:word);

Procedure pcRename;
procedure hobRename;

Function  hobLoad(name:string):boolean;
Function  hobSave(path:string; AltF5flag:boolean):boolean;
procedure MakeImages(var p:TPanel);


Implementation
Uses Vars,RV,Main,Main_Ovr,Mouse,PC,TRD,FDI,FDD,TRD_Ovr,FDD_Ovr,FDI_Ovr,
     SCL_Ovr,TAP_Ovr,zxView,Palette,trdos,isdos;


{============================================================================}
procedure pcF7Pressed(path:string; w:byte);
var d:pathstr;
    i:integer;
    s:string[12];
function pcMakeDir:boolean;
begin
 CancelSB;
 colour(pal.bkdRama,pal.txtdRama);
 scputwin(pal.bkdRama,pal.txtdRama,17,halfmaxy-3,64,halfmaxy-3+3);
 cmcentre(pal.bkdRama,pal.txtdRama,halfmaxy-3,' Make directory ');
 cmprint(pal.bkdLabelST,pal.txtdLabelST,20,halfmaxy-2,'Directory name');
 printself(pal.bkdInputNT,pal.txtdInputNT,19,halfmaxy-1,44);
 colour(pal.bkdInputNT,pal.txtdInputNT);
 curon;
 d:=nospace(scanf(20,halfmaxy-1,'',42,42,1));
 curoff;
 restscr;
 pcMakeDir:=not scanf_esc;
 if nospace(d)='' then pcMakeDir:=false;
end;

Begin
if pcMakeDir then
 begin
  s:=strhi(getof(d,_name)+getof(d,_ext));

  if (clen(d)=clen(without(d,':')))and(d[1]<>'\') then d:=path+d;
  if d[clen(d)]<>'\' then d:=d+'\';
  createdir(d);
  reMDF;
  if w=left then
   begin
    lp.pcnn:=s;
   end
  else
   begin
    rp.pcnn:=s;
   end;
  lp.TrueCur; lp.Inside;
  rp.TrueCur; rp.Inside;
  reInfo('cdsfi');
  rePDF;
 end;
end;





{============================================================================}
procedure pcDelete(ndpath:string; nm:pathstr; priory:byte; attr:byte);

procedure Dels(path:pathstr);
procedure DirDel(n:string); begin {$I-} rmdir(n); {$I+} if ioresult<>0 then; end;
procedure DelFileScan(path:pathstr);
var sr:searchrec; s:string; attr:word; dest:file;
begin
 FindFirst(path+'\*.*', $3F, sr);
 while DosError=0 do
  begin
   if (sr.attr and (directory or volumeid)=0) then
    begin
     s:=path+'\'+sr.name; delete(s,1,length(ndpath));
     assign(dest,{nospace{}(path+'\'+sr.name));
     getfattr(dest,attr); if attr and ReadOnly <> 0 then setfattr(dest,(attr xor ReadOnly));
     filedelete({nospace{}(path+'\'+sr.name));
    end;
   FindNext(sr);
  end;
end;

procedure DelDirScan(path:pathstr);
var sr:searchrec; s:string;
begin
 FindFirst(path+'\*.*', $3F, sr);
 while DosError=0 do
  begin
   if ((sr.attr and directory)=directory)and not((sr.name='.')or(sr.name='..')) then
    begin
     deldirscan(path+'\'+sr.name);
     cmcentre(pal.bkdLabelNT,pal.txtdLabelNT,
              halfmaxy-1,space((17-length(sr.name))div 2)+sr.name+space((17-length(sr.name))div 2));
     delfilescan(path+'\'+sr.name);
     dirdel(path+'\'+sr.name);
     if refresh then reInfo('sf');{}
    end;
   FindNext(sr);
  end;
end;

var a:string;
begin
deldirscan(path);
delfilescan(path);

if nospace(getof(path,_ext))=''
  then a:={nospace{}(getof(path,_name))
  else a:={nospace{}(getof(path,_name)+getof(path,_ext));

cmcentre(pal.bkdLabelNT,pal.txtdLabelNT,halfmaxy-1,
space((17-length(a))div 2)+
a+
space((17-length(a))div 2));
dirdel(path);
end;


var d:pathstr;
    i:integer;
    s:string;
Begin
if priory=0
 then s:='Deleting directory'
 else s:='  Deleting file   ';
cmCentre(pal.bkdLabelNT,pal.txtdLabelNT,halfmaxy-2,s);
cmCentre(pal.bkdLabelNT,pal.txtdLabelNT,halfmaxy-1,space((17-length(nm))div 2)+nm+space((17-length(nm))div 2));
if priory=0 then Dels(ndPath+nm) else FileDelete(ndPath+nm);
End;




{============================================================================}
Procedure pcF8;
Var
    i:word; n,s:string;
Begin
if InsedOf(focus)=0 then n:=TrueNameOf(focus,IndexOf(focus));
if InsedOf(focus)=1 then n:=TrueNameOf(focus,FirstMarkedOf(focus));
if IndexOf(focus)>tdirsOf(focus)
 then
  s:='Do you wish to delete'#255'file '+n+' ?'
 else
  s:='Do you wish to delete'#255'directory '+n+' ?';
if InsedOf(focus)>1 then
  s:='Do you wish to delete'#255'this files ?';
if (InsedOf(focus)=0)and(nospace(n)='..') then Exit;
CancelSB;
if cQuestion(s,lang) then
 Begin
  if InsedOf(focus)=0 then
   Case focus of
    left: lp.pcDir^[IndexOf(focus)].mark:=true;
    right: rp.pcDir^[IndexOf(focus)].mark:=true;
   End;
  PutSmallWindow(' Erase ','   Stop   ');
  for i:=1 to tdirsfilesOf(focus) do if pcDirMarkOf(focus,i) then
   Begin
    pcDelete(pcndOf(focus),TrueNameOf(focus,i),pcDirPrioryOf(focus,i),
             pcDirFAttrOf(focus,i));
    Case focus of
     left: lp.pcDir^[i].mark:=false;
     right: rp.pcDir^[i].mark:=false;
    End;
   End;
  RestScr;
  reMDF;
  lp.TrueCur; rp.TrueCur;
  lp.Inside; rp.Inside;
  reInfo('cbdnsfi');
  rePDF;
 End;
End;


{============================================================================}
Procedure pc2pc(flag:word);
Var
    was:longint;
    TargetPath:string;
    skip:boolean;
    total:longint;
    h,m,s,s100:word; timer,timerstart:longint;
    vert:array[1..4] of char; cvert,fcvert:byte;


Procedure CopyMove_pc2pc(cmflag:word; sPath:string; nm:string; tPath:string;
                priory:byte; fattr:word; fdt:datetime;
                skip:boolean; totalsize:longint; var UserOut:boolean);
Var
    path:string;
    stemp:string; itemp:integer;

function GetTimer(sec:string):string;
Var h,m,s:byte; t:integer;
begin
t:=vall(sec);
h:=t div 3600;
m:=t div 60;
s:=t-h*3600-m*60;
GetTimer:=LZ(h)+':'+LZ(m)+':'+LZ(s);
end;

procedure copyfile(cfrom,cto:string; fftime:datetime; ffattr:word);
type mas=array[1..2] of byte;
var buf:^mas;
    ffr,fto:file;
    numread,numwritten:word;
    k,j,i,bufsize:longint;
    q:char;
    ftime:longint;
label outloop,fin,fin2;
begin
if checkdir(getof(cto,_dir))<>0 then createdir(getof(cto,_dir)+'\');
if (checkdirfile(cto)=0)and(skip) then exit;

if pos('\.\',nospace(tPath))<>0 then
 begin
  errormessage('Can'#39't copy file to itself');
  {}
  userout:=true;
  goto fin2;
 end;

if checkdir(getof(cto,_dir))<>0 then
 begin
  errormessage('Error while checking directory');
  userout:=true;
  goto fin2;
 end;

if cfrom=cto then
 begin

  errormessage('Can'#39't copy file to itself');
  {}
  userout:=true;
  goto fin2;
 end;

if diskfree(ord(cto[1])-64)<=filelen(cfrom) then
 begin
  errormessage('Disk '+cto[1]+': full');
  userout:=true;
  goto fin2;
 end;

if not checkwrite(cto[1]) then
 begin
  errormessage('Disk '+cto[1]+': write protect');
  userout:=true;
  goto fin2;
 end;

 cmprint(pal.bkdLabelST,pal.txtdLabelST,20,halfmaxy-3,'File');
 cmprint(pal.bkdLabelST,pal.txtdLabelST,20,halfmaxy,'Total');
 cmprint(pal.bkdLabelNT,pal.txtdLabelNT,25,halfmaxy-3,strlo(getof(cfrom,_name)+getof(cfrom,_ext))+space(12));
 cmprint(pal.bkdStatic,pal.txtdStatic,22,halfmaxy-2,fill(37,#177));

{$I-}
assign(ffr,cfrom); assign(fto,cto);

setfattr(fto,archive);
bufsize:=49152; ftime:=0; k:=filelen(cfrom); fcvert:=1;

IF ((upcase(CFROM[1])<>upcase(CTO[1]))and(cmFlag=_F6))or(cmFlag=_F5) THEN
BEGIN
filemode:=1; rewrite(fto,1);
filemode:=0; reset(ffr,1);

getmem(buf,bufsize);
{$I-}
    if filesize(ffr)=0 then goto outloop;
    repeat
     if keypressed then
      begin
       q:=readkey;
       stemp:='Stop operation?';
       if q=#27 then if cquestion(stemp,lang) then begin userout:=true; break; end;
      end;

     blockread(ffr,buf^,bufsize,numread);
     blockwrite(fto,buf^,numread,numwritten);

     itemp:=ioresult;
     if itemp<>0 then begin {errormessage('Неожиданная ошибка '+strr(itemp));{} userout:=true; break; end;

     inc(was,numread); i:=round(((was)/totalsize)*100); if i>100 then i:=100;
     inc(ftime,numread); j:=round(((ftime)/k)*100); if j>100 then j:=100;

     gettime(h,m,s,s100); timer:=s+m*60+h*3600-timerstart;
     cmprint(pal.bkdStatic,pal.txtdStatic,55,halfmaxy-4,GetTimer(strr(timer)));

     if timer>0 then if lang=rus
     then cmcentre(pal.bkdStatic,pal.txtdStatic,halfmaxy-1,'   ('+strr(round((was/timer)/1024))+' kB/сек)  ')
     else cmcentre(pal.bkdStatic,pal.txtdStatic,halfmaxy-1,'   ('+strr(round((was/timer)/1024))+' kB/sec)  ');

     cmprint(pal.bkdStatic,pal.txtdStatic,20,halfmaxy-2,vert[fcvert]);
     cmprint(pal.bkdStatic,pal.txtdStatic,22,halfmaxy-2,fill(round(j/2.7),#$DB));
     cmprint(pal.bkdStatic,pal.txtdStatic,60,halfmaxy-2,strr(j)+'%'+space(4-length(strr(j)+'%')));
     cmprint(pal.bkdStatic,pal.txtdStatic,20,halfmaxy+1,vert[cvert]);
     cmprint(pal.bkdStatic,pal.txtdStatic,22,halfmaxy+1,fill(round(i/2.7),#$DB));
     cmprint(pal.bkdStatic,pal.txtdStatic,60,halfmaxy+1,strr(i)+'%'+space(4-length(strr(i)+'%')));
     if lang=rus then cmcentre(pal.bkdStatic,pal.txtdStatic,halfmaxy+2,extnum(strr(was))+' байт cкопиpовано')
                 else cmcentre(pal.bkdStatic,pal.txtdStatic,halfmaxy+2,extnum(strr(was))+' bytes copyed');{}
     inc(cvert); if cvert>4 then cvert:=1;
     inc(fcvert); if fcvert>4 then fcvert:=1;

     if moused then MouseOff;
     if moused then MouseOn;
    until (numread=0)or(numwritten<>numread);
outloop:
freemem(buf,bufsize);

fin:
packtime(fftime,ftime); setftime(fto,ftime);
close(ffr); close(fto);
if itcdrom(cfrom[1]) then else begin getfattr(ffr,ffattr); setfattr(fto,ffattr); end;
if cmflag=_F6 then
 begin
  setfattr(ffr,archive); erase(ffr);
 end;
END
ELSE
BEGIN
     setfattr(fto,archive); erase(fto);
     rename(ffr,cto);

     if keypressed then
      begin
       q:=readkey;
       stemp:='Stop operation?';
       if q=#27 then if cquestion(stemp,lang) then begin userout:=true; end;
      end;
     j:=100;
     inc(was,k); i:=round(((was)/totalsize)*100); if i>100 then i:=100;

     cmprint(pal.bkdStatic,pal.txtdStatic,20,halfmaxy-2,vert[fcvert]);
     cmprint(pal.bkdStatic,pal.txtdStatic,22,halfmaxy-2,fill(round(j/2.7),#$DB));
     cmprint(pal.bkdStatic,pal.txtdStatic,60,halfmaxy-2,strr(j)+'%'+space(4-length(strr(j)+'%')));
     cmprint(pal.bkdStatic,pal.txtdStatic,20,halfmaxy+1,vert[cvert]);
     cmprint(pal.bkdStatic,pal.txtdStatic,22,halfmaxy+1,fill(round(i/2.7),#$DB));
     cmprint(pal.bkdStatic,pal.txtdStatic,60,halfmaxy+1,strr(i)+'%'+space(4-length(strr(i)+'%')));

     inc(cvert); if cvert>4 then cvert:=1;
     inc(fcvert); if fcvert>4 then fcvert:=1;
END;

fin2:
if userout then erase(fto);
{$I+}
if ioresult<>0 then;
if refresh then reInfo('sf');{}
end;

procedure CopyFileScan(path:pathstr);
var sr:searchrec; s:string; dt:datetime;
begin
 FindFirst(path+'\*.*', $3F, sr);
 while DosError=0 do
  begin
   if (sr.attr and (directory or volumeid)=0) then
    begin
     if userout then exit;
     s:=path+'\'+sr.name; delete(s,1,length(pcndOf(focus)));
     unpacktime(sr.time,dt);
     copyfile({nospace{}(path+'\'+sr.name),{nospace{}(tPath+s),dt,sr.attr);{}
     if userout then exit;
    end;
   FindNext(sr);
  end;
end;

procedure CopyDirScan(path:pathstr);
var sr:searchrec; s:string;
begin
 FindFirst(path+'\*.*', $3F, sr);
 while DosError=0 do
  begin
   if ((sr.attr and directory)=directory)and not((sr.name='.')or(sr.name='..')) then
    begin
     if userout then exit;
     copydirscan(path+'\'+sr.name);
     if userout then exit;
     copyfilescan(path+'\'+sr.name);
     if userout then exit;
     {$I-} if cmFlag=_F6 then RmDir(path+'\'+sr.name); {$I+}
    end;
   FindNext(sr);
  end;
s:=path; delete(s,1,length(pcndOf(focus))); CreateDir(tpath+s+'\');
end;

Begin
Path:=sPath+nm;
if path[length(path)]='.' then delete(path,length(path),1);
stemp:=reversestr(path);
stemp:=reversestr(copy(stemp,1,pos('\',stemp)));
if pos(Path,tPath)<>0 then
 begin
  errormessage('Directory '+stemp+'; attempt copy to itself');
  exit;
 end;
if priory=0 then
 begin
  if userout then exit;
  copydirscan(path);
  if userout then exit;
  copyfilescan(path);
  if userout then exit;
  {$I-} if cmFlag=_F6 then RmDir(path); {$I+}
 end
else
 begin
  if userout then exit;
  CopyFile(path,tPath+nm,fdt,fattr);
  if userout then exit;
 end;
if Moused then MouseOff;
if Moused then MouseOn;
End;

Var dt:DateTime; ldt:longint; UserOutCopy:boolean;
BEGIN
UserOutCopy:=false;
 if WillCopyMove(Flag,TargetPath,Skip) then
  Begin
   Colour(pal.bkdRama,pal.txtdRama);
   scPutWin(pal.bkdRama,pal.txtdRama,17,halfmaxy-5,64,halfmaxy-3+6);
   if Flag=_F5
   then
     cmcentre(pal.bkdRama,pal.txtdRama,halfmaxy-5,' Copy ')
   else
     cmcentre(pal.bkdRama,pal.txtdRama,halfmaxy-5,' Move ');
   cmCentre(pal.bkdStatic,pal.txtdStatic,halfmaxy-1,' Scaning directories...');
   total:=ViewOf(focus,true);
   cmCentre(pal.bkdStatic,pal.txtdStatic,halfmaxy-1,'                       ');
   cmcentre(pal.bkdRama,pal.txtdRama,halfmaxy+3,' Total '+changechar(extnum(strr(total)),' ',',')+' bytes ');
   cmPrint(pal.bkdStatic,pal.txtdStatic,22,halfmaxy+1,fill(37,#177));
   was:=0;
gettime(h,m,s,s100); timerstart:=s+m*60+h*60*60;
vert[1]:='-'; vert[2]:='\'; vert[3]:='|'; vert[4]:='/';
cvert:=1;
   if InsedOf(focus)=0 then
    begin
     UnPackTime(pcDirFdtOf(focus,IndexOf(focus)),dt);
     CopyMove_pc2pc(flag,pcndOf(focus),TrueNameOf(focus,IndexOf(focus)),
                    TargetPath,
                    pcDirPrioryOf(focus,IndexOf(focus)),
                    pcDirFAttrOf(focus,IndexOf(focus)),dt,
                    Skip,total,UserOutCopy);
    end;
   if InsedOf(focus)>0 then for i:=1 to tdirsfilesOf(focus) do if pcDirMarkOf(focus,i) then
    begin
     if UserOutCopy then break;
     UnPackTime(pcDirFdtOf(focus,i),dt);
     CopyMove_pc2pc(flag,pcndOf(focus),TrueNameOf(focus,i),
                    TargetPath,
                    pcDirPrioryOf(focus,i),
                    pcDirFAttrOf(focus,i),dt,Skip,total,UserOutCopy);
     if UserOutCopy then break;
     Case focus of
      left: lp.pcDir^[i].mark:=false;
      right: rp.pcDir^[i].mark:=false;
     End;
    {}
    end;
  End;
 RestScr;
 reMDF;
  lp.TrueCur; lp.Inside;
  rp.TrueCur; rp.Inside;
 reInfo('cb nsfi');
 rePDF;
END;




{============================================================================}
Procedure pcRename;
Var
    s,stemp:string; ff:file; CurXPos, CurYPos:byte;
    n,dx:byte;
{== SCANF ===================================================================}
function SNscanf(scanf_posx, scanf_posy:byte;scanf_str:string):string;
var
     scanf_kod:char;
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
scanf_kod:=readkey;
if (scanf_kod in[' '..')','-','0'..'9','@'..'[',']'..#255])and(scanf_x<=length(scanf_str)) then
 begin
  scanf_str[scanf_x]:=scanf_kod;
  inc(scanf_x);
  if scanf_x=DX+1 then inc(scanf_x);
 end;
if scanf_kod='.' then scanf_x:=DX+2;

if scanf_kod=#0 then
 begin
  scanf_kod:=readkey;
  if scanf_kod=#77 then begin inc(scanf_x); if scanf_x=DX+1 then inc(scanf_x); end;
  if scanf_kod=#75 then begin dec(scanf_x); if scanf_x=DX+1 then dec(scanf_x); end;
  if scanf_kod=#72 then scanf_kod:=#13;
  if scanf_kod=#80 then scanf_kod:=#13;
 end;

if scanf_kod=#27 then begin snscanf:=scanf_str_old; scanf_esc:=true; exit; end;
if scanf_kod=#13 then begin snscanf:=scanf_str; exit; end;

if scanf_x<1 then scanf_x:=1;
if scanf_x>DX+4 then begin scanf_x:=DX+4; end;
goto loop;
end;


Begin
 Case focus of
  left: stemp:=lp.pcDir^[IndexOf(focus)].fname;
  right: stemp:=rp.pcDir^[IndexOf(focus)].fname;
 End;
 if nospace(stemp)='..' then exit;
 CancelSB;
 GetCurXYOf(focus,CurXPos,CurYPos);
 Case ColumnsOf(focus) of
  1,3: DX:=8;
  2:   Begin DX:=15; if (CurXPos=2)or(CurXPos=42) then dec(DX);{} End;
 End;

 Colour(pal.bkCurNT,pal.txtCurNT);
 Case focus of
  left:  stemp:=sRexpand(lp.pcdir^[IndexOf(focus)].fname,DX)+'.'+sRexpand(lp.pcdir^[IndexOf(focus)].fext,3);
  right: stemp:=sRexpand(rp.pcdir^[IndexOf(focus)].fname,DX)+'.'+sRexpand(rp.pcdir^[IndexOf(focus)].fext,3);
 End;
 s:=TrueNameOf(focus,IndexOf(focus));
 if IndexOf(focus)>tdirsOf(focus) then stemp:=strlo(stemp);
 CurOn; SetCursor(400); stemp:=nospace(snscanf(CurXPos,CurYPos,stemp)); CurOff;
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
   s,stemp:string;
   tc,xc,yc:byte;
   m:word;
   f:file;
begin
if not itHobeta(pcndOf(focus)+TrueNameOf(focus,IndexOf(focus)),HobetaInfo) then exit;{}
CancelSB;
colour(pal.bkCurNT,pal.txtCurNT);

stemp:=HobetaInfo.name+'.';
if TRDOS3 then stemp:=stemp+hobetainfo.typ+chr(lo(hobetainfo.start))+chr(hi(hobetainfo.start))
          else stemp:=stemp+'<'+hobetainfo.typ+'>';

GetCurXYOf(focus,xc,yc);
curon; SetCursor(400); stemp:=zxsnscanf(xc,yc,stemp,HobetaInfo.typ); curoff;
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
  assign(f,pcndOf(focus)+TrueNameOf(focus,IndexOf(focus))); FileMode:=2;
  Reset(f,1);  Seek(f,0); BlockWrite(f,buf,17); Close(f);
  {$I+}
  if IOResult=0 then;
 end;
rePDF;
end;


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
  Assign(f,name); filemode:=0; reset(f,1); seek(f,17);
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

stemp:=strlo(hob2pc(HobetaInfo.name));
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
Assign(f,path+stemp); filemode:=2; rewrite(f,1);

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
procedure MakeImages(var p:TPanel);
Var i:byte;
Begin
  menu_Name[1]:='~`TRD~`  - Standart TR-DOS Image';
  menu_Name[2]:='~`FDI~`  - TR-DOS Full Disk Image (UKV)';
  menu_Name[3]:='~`FDD~`  - TR-DOS for Scorpion256 by MOA';
  menu_Name[4]:='~`SCL~`  - Hobeta98 (AMD Copier)';
  menu_Name[5]:='~`TAP~`  - Tape Image';
  Menu_Name[6]:='~`FTiS~` - Format iS-DOS disk';
  Menu_Name[7]:='~`LDiS~` - Load iS-DOS disk to file';
  Menu_Name[8]:='~`FTTR~` - Format TR-DOS disk';
  Menu_Name[9]:='~`LDTR~` - Load TR-DOS disk to file';
  Menu_Name[10]:='~`WRTR~` - Save file to TR-DOS disk';
CancelSB;
menu_Total:=9;
if (isTRD(pcndOf(focus)+TrueNameOf(focus,IndexOf(focus))))or
   (isFDI(p,pcndOf(focus)+TrueNameOf(focus,IndexOf(focus))))or
   (isFDD(pcndOf(focus)+TrueNameOf(focus,IndexOf(focus))))
   then menu_Total:=10;

menu_f:=1; menu_title:=''; menu_visible:=10;
w_twosided:=false;
i:=ChooseItem;
w_twosided:=true;
Case i of
 1: trdMakeImage(p,false);
 2: fdiMakeImage(p,false);
 3: fddMakeImage(p,false);
 4: sclMakeImage(false);
 5: tapMakeImage;
 6: Format_ISDOS;
 7: Load_ISDOS;
 8: Format_TRDOS;
 9: Load_TRDOS;
 10: Save_TRDOS;{}
End;
reMDF;
p.truecur;
p.inside;
reInfo('cbdnsfi');
rePDF;
End;



End.