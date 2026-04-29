Unit Main;
{$mode objfpc}{$H+}
Interface

Function  CRC16(InString: String) : Word;
Function  CheckPath(p:string):string;
Procedure GlobalRedraw;
Procedure rePDF;
Procedure reMDF;
Procedure reInfo(parts:string);
Procedure reInside;
Procedure reOutside;
Procedure reTrueCur;

Procedure CancelSB;
Procedure ChangeFocus;
Function  PanelTypeOf(w:byte):byte;
Function  InsedOf(w:byte):word;
Function  IndexOf(w:byte):word;
Function  FirstMarkedOf(w:byte):word;
Function  TrueNameOf(w:byte; i:word):String;
Function  tDirsOf(w:word):word;
Function  tFilesOf(w:word):word;
Function  tDirsFilesOf(w:word):word;
Function  oFocus:byte;
Function  pcndOf(w:word):string;
Function  pcDirPrioryOf(w:byte; ind:word):byte;
Function  pcDirFAttrOf(w:byte; ind:word):word;
Function  pcDirMarkOf(w:byte; ind:word):boolean;
Function  trdDirMarkOf(w:byte; ind:word):boolean;
Function  TreeCOf(w:byte; path:string):byte;
Procedure GetCurXYOf(w:byte; var x,y:word);
Function  FocusedOf(w:byte):boolean;

Procedure Navigate;

Implementation
Uses
     RV,
     Vars, sn_Mem, sn_Obj, Palette,
     Main_Ovr, SysUtils, UnicodeVideo;


{============================================================================}
Function CRC16(InString: String) : Word;
Var
  CRC     : Word;
  Index1,
  Index2  : Byte;
begin
  CRC := 0;
  For Index1 := 1 to length(InString) do
  begin
    CRC := (CRC xor (ord(InString[Index1]) SHL 8));
    For Index2 := 1 to 8 do
      if ((CRC and $8000) <> 0) then
        CRC := ((CRC SHL 1) xor $1021)
      else
        CRC := (CRC SHL 1)
  end;
  CRC16 := (CRC and $FFFF)
end;



{============================================================================}
Function CheckPath(p:string):string;
Var
    orig:string;
 begin
orig:=GetCurrentDir;
while (Length(p)>1)and(p[Length(p)]=PathDelim) do Delete(p,Length(p),1);
if not SetCurrentDir(p) then
 begin
  repeat
    while (Length(p)>1)and(p[Length(p)]<>PathDelim) do
      Delete(p,Length(p),1);
    if Length(p)<=1 then begin p:=GetCurrentDir; break; end;
    Delete(p,Length(p),1);
  until SetCurrentDir(p) or (Length(p)<=1);
  if not SetCurrentDir(p) then p:=GetCurrentDir;
 end;

if p[Length(p)]<>PathDelim then p:=p+PathDelim;
CheckPath:=p;

SetCurrentDir(orig);
end;



{============================================================================}
Procedure GlobalRedraw;
var
  pf, pfrom, total: longint;
  pt: byte;
Begin
FlushWinStack;
Cls;
lp.PanelSetup; rp.PanelSetup;
pf:=lp.f; pfrom:=lp.from;
total:=lp.tdirs+lp.tfiles;
ClampPanel(pf, pfrom, lp.PanelHi, total);
lp.f:=pf; lp.from:=pfrom;
pf:=rp.f; pfrom:=rp.from;
total:=rp.tdirs+rp.tfiles;
ClampPanel(pf, pfrom, rp.PanelHi, total);
rp.f:=pf; rp.from:=pfrom;
if lp.PanelType<>noPanel then lp.Build('012');
if rp.PanelType<>noPanel then rp.Build('012');
lp.Info('cbdnsfi'); rp.Info('cbdnsfi');
Case lp.PanelType of
 pcPanel:  begin lp.TrueCur; lp.Inside; lp.pcPDF(lp.pcfrom); end;
 trdPanel: begin lp.TrueCur; lp.Inside; lp.trdPDFs(lp.trdfrom); end;
 fdiPanel: begin lp.TrueCur; lp.Inside; lp.fdiPDFs(lp.fdifrom); end;
 sclPanel: begin lp.TrueCur; lp.Inside; lp.sclPDFs(lp.sclfrom); end;
 tapPanel: begin lp.TrueCur; lp.Inside; lp.tapPDFs(lp.tapfrom); end;
 fddPanel: begin lp.TrueCur; lp.Inside; lp.fddPDFs(lp.fddfrom); end;
 zxzPanel: begin lp.TrueCur; lp.Inside; lp.zxzPDFs(lp.zxzfrom); end;
End;
Case rp.PanelType of
 pcPanel:  begin rp.TrueCur; rp.Inside; rp.pcPDF(rp.pcfrom); end;
 trdPanel: begin rp.TrueCur; rp.Inside; rp.trdPDFs(rp.trdfrom); end;
 fdiPanel: begin rp.TrueCur; rp.Inside; rp.fdiPDFs(rp.fdifrom); end;
 sclPanel: begin rp.TrueCur; rp.Inside; rp.sclPDFs(rp.sclfrom); end;
 tapPanel: begin rp.TrueCur; rp.Inside; rp.tapPDFs(rp.tapfrom); end;
 fddPanel: begin rp.TrueCur; rp.Inside; rp.fddPDFs(rp.fddfrom); end;
 zxzPanel: begin rp.TrueCur; rp.Inside; rp.zxzPDFs(rp.zxzfrom); end;
End;
if focus=Left then pt:=lp.PanelType else pt:=rp.PanelType;
cStatusBar(Pal.BkSBarNT,Pal.TxtSBarNT,
           Pal.BkSBarST,Pal.TxtSBarST,
           1, sBar[lang, pt]);
End;



{============================================================================}
Procedure rePDF;
begin
 case lp.PanelType of
  pcPanel:  lp.pcPDF(lp.pcfrom);
  trdPanel: lp.trdPDFs(lp.trdfrom);
  fdiPanel: lp.fdiPDFs(lp.fdifrom);
  sclPanel: lp.sclPDFs(lp.sclfrom);
  tapPanel: lp.tapPDFs(lp.tapfrom);
  fddPanel: lp.fddPDFs(lp.fddfrom);
  zxzPanel: lp.zxzPDFs(lp.zxzfrom);
 end;
 case rp.PanelType of
  pcPanel:  rp.pcPDF(rp.pcfrom);
  trdPanel: rp.trdPDFs(rp.trdfrom);
  fdiPanel: rp.fdiPDFs(rp.fdifrom);
  sclPanel: rp.sclPDFs(rp.sclfrom);
  tapPanel: rp.tapPDFs(rp.tapfrom);
  fddPanel: rp.fddPDFs(rp.fddfrom);
  zxzPanel: rp.zxzPDFs(rp.zxzfrom);
 end;
end;





{============================================================================}
Procedure reMDF;
Var lPT,rPT:byte;
begin
lPT:=lp.PanelType;
if lPT=noPanel then lPT:=lp.LastPanelType;
if lPT=infPanel then lPT:=lp.clLastPanelType;

rPT:=rp.PanelType;
if rPT=noPanel then rPT:=rp.LastPanelType;
if rPT=infPanel then rPT:=rp.clLastPanelType;

 case lPT of
  pcPanel:  lp.pcMDF(lp.pcnd);
  trdPanel: lp.trdMDFs(lp.trdfile);
  fdiPanel: lp.fdiMDFs(lp.fdifile);
  sclPanel: lp.sclMDFs(lp.sclfile);
  tapPanel: lp.tapMDFs(lp.tapfile);
  fddPanel: lp.fddMDFs(lp.fddfile);
  zxzPanel: lp.zxzMDFs(lp.zxzfile);
 end;

 case rPT of
  pcPanel:  rp.pcMDF(rp.pcnd);
  trdPanel: rp.trdMDFs(rp.trdfile);
  fdiPanel: rp.fdiMDFs(rp.fdifile);
  sclPanel: rp.sclMDFs(rp.sclfile);
  tapPanel: rp.tapMDFs(rp.tapfile);
  fddPanel: rp.fddMDFs(rp.fddfile);
  zxzPanel: rp.zxzMDFs(rp.zxzfile);
 end;

end;





{============================================================================}
Procedure reInfo(parts:string);
begin
lp.Info(parts);
rp.Info(parts);
end;




{============================================================================}
Procedure reInside;
begin
lp.Inside; rp.Inside;
end;


{============================================================================}
Procedure reOutside;
begin
lp.Outside; rp.Outside;
end;



{============================================================================}
Procedure reTrueCur;
begin
 case lp.PanelType of
  pcPanel: lp.TrueCur;
 end;
 case rp.PanelType of
  pcPanel: rp.TrueCur;
 end;
end;




{============================================================================}
Procedure CancelSB;
Begin
cstatusbar(pal.bkSBarNT,pal.txtSBarNT,pal.bkSBarST,pal.txtSBarST,0,'~`ESC~` Cancel');
End;



{============================================================================}
Procedure ChangeFocus;
Begin
 lp.focused:=not lp.focused;
 rp.focused:=not rp.focused;
 if focus=left then focus:=right else focus:=left;
End;





{============================================================================}
Function PanelTypeOf(w:byte):byte;
Begin
Case w of
 left:  PanelTypeOf:=lp.PanelType;
 right: PanelTypeOf:=rp.PanelType;
End;
End;





{============================================================================}
Function InsedOf(w:byte):word;
Begin
Case w of
 left:  InsedOf:=lp.Insed;
 right: InsedOf:=rp.Insed;
End;
End;




{============================================================================}
Function IndexOf(w:byte):word;
Begin
Case w of
 left:  IndexOf:=lp.Index;
 right: IndexOf:=rp.Index;
End;
End;




{============================================================================}
Function FirstMarkedOf(w:byte):word;
Begin
Case w of
 left:  FirstMarkedOf:=lp.FirstMarked;
 right: FirstMarkedOf:=rp.FirstMarked;
End;
End;




{============================================================================}
Function TrueNameOf(w:byte; i:word):String;
Begin
Case w of
 left:  TrueNameOf:=lp.TrueName(i);
 right: TrueNameOf:=rp.TrueName(i);
End;
End;



{============================================================================}
Function tDirsOf(w:word):word;
Begin
Case w of
 left:  tDirsOf:=lp.tDirs;
 right: tDirsOf:=rp.tDirs;
End;
End;




{============================================================================}
Function tFilesOf(w:word):word;
Begin
Case w of
 left:  tFilesOf:=lp.tFiles;
 right: tFilesOf:=rp.tFiles;
End;
End;





{============================================================================}
Function tDirsFilesOf(w:word):word;
Begin
Case w of
 left:  tDirsFilesOf:=lp.tFiles+lp.tDirs;
 right: tDirsFilesOf:=rp.tFiles+rp.tDirs;
End;
End;



{============================================================================}
Function oFocus:byte;
Begin
if focus=left then oFocus:=right else oFocus:=left;
End;





{============================================================================}
Function pcndOf(w:word):string;
Begin
Case w of
 left:  pcndOf:=lp.pcnd;
 right: pcndOf:=rp.pcnd;
End;
End;



{============================================================================}
Function  pcDirPrioryOf(w:byte; ind:word):byte;
Begin
Case w of
 left:  pcDirPrioryOf:=lp.pcDir^[ind].Priory;
 right: pcDirPrioryOf:=rp.pcDir^[ind].Priory;
End;
End;





{============================================================================}
Function  pcDirFAttrOf(w:byte; ind:word):word;
Begin
Case w of
 left:  pcDirFAttrOf:=lp.pcDir^[ind].FAttr;
 right: pcDirFAttrOf:=rp.pcDir^[ind].FAttr;
End;
End;



{============================================================================}
Function  pcDirMarkOf(w:byte; ind:word):boolean;
Begin
Case w of
 left:  pcDirMarkOf:=lp.pcDir^[ind].mark;
 right: pcDirMarkOf:=rp.pcDir^[ind].mark;
End;
End;



{============================================================================}
Function  trdDirMarkOf(w:byte; ind:word):boolean;
Begin
Case w of
 left:  trdDirMarkOf:=lp.trdDir^[ind].mark;
 right: trdDirMarkOf:=rp.trdDir^[ind].mark;
End;
End;



{============================================================================}
Function  TreeCOf(w:byte; path:string):byte;
Begin
Case w of
 left:  TreeCOf:=lp.GetTreeC(path);
 right: TreeCOf:=rp.GetTreeC(path);
End;
End;



{============================================================================}
Procedure GetCurXYOf(w:byte; Var x,y:word);
Begin
Case w of
 left:  lp.GetCurXY(x,y);
 right: rp.GetCurXY(x,y);
End;
End;



{============================================================================}
Function FocusedOf(w:byte):boolean;
Begin
Case w of
 left:  FocusedOf:=lp.focused;
 right: FocusedOf:=rp.focused;
End;
End;



{============================================================================}
Procedure Navigate;
Begin
snKernelExitCode:=0;
Case focus of
 Left:
   Begin
    lp.navigate;
   End;
 Right:
   Begin
    rp.navigate;
   End;
End;
End;






initialization
  OnResize := @GlobalRedraw;
End.