{$O+,F+}
Unit Init;
Interface

Procedure snInit(sys:boolean);

Implementation
Uses
     Crt, Dos, RV, Clock,
     Vars, sn_Mem, sn_Obj, Palette, Main, Main_Ovr, sn_KBD;


Procedure snInit(sys:boolean);
Var
   s:string; i:word; f:text;
label contsys;
Begin
if sys then goto contsys;{}
if (DosMem<400*1024) then
 begin
  WriteLn('Not enough request 400K conventional memory. '+
          ChangeChar(ExtNum(strr(DosMem)),' ',',')+'K is free.');
  Halt;
 end;
CurOff; Flash(off);
SavedAttr:=TextAttr;
GetMemPCDirs;

if (MemAvail<60*1024) then
 begin
  WriteLn('Not enough request 60K data segment memory. '+
          ChangeChar(ExtNum(strr(MemAvail)),' ',',')+'K is free.');
  Halt;
 end;

ContSys:

WorkDir:=CurentDir; StartDir:=GetOf(ParamStr(0),_dir);
if StartDir='' then StartDir:=CurentDir;

Moused:=false;

focus:=left; Lang:=eng;

Esc_ShowUserScr:=true;
lp.pcnd:=curentdir;
rp.pcnd:=curentdir;

{GetPalFile;{}
LoadDefaultKBD;

menu_bkNT:=pal.bkMenuNT;          menu_txtNT:=pal.txtMenuNT;
menu_bkST:=pal.bkMenuST;          menu_txtST:=pal.txtMenuST;

menu_bkMarkNT:=pal.bkMenuMarkNT;  menu_txtMarkNT:=pal.txtMenuMarkNT;
menu_bkMarkST:=pal.bkMenuMarkST;  menu_txtMarkST:=pal.txtMenuMarkST;

clocked:=true;
lp.nameline:=true; rp.nameline:=true;
DiskLine:=true;
lp.infolines:=3; rp.infolines:=3;
w_animation:=false;
HideCmdLine:=true;
focus:=right;
DiskMenuType:=1;
HideHidden:=false;
Refresh:=false;
Del_F8:=true;
LANG:=eng;
InternalView:=true;
pr1:=';trd;fdi;fdd;scl;tap;';
pr2:=gExe;
pr3:=gArc;

TRDOS3:=false;
TRDOS3en:=true;{}

AutoMove:=false;
hob2scl:=false;

HobetaStartAddr:=32768;

noHobNaming:=1;
CheckMedia:=true;
LoadUp80:=true;
Cat9:=true;

if lp.pcnd[length(lp.pcnd)]<>'\' then lp.pcnd:=lp.pcnd+'\';
if rp.pcnd[length(rp.pcnd)]<>'\' then rp.pcnd:=rp.pcnd+'\';

if Clocked then ClockStart;{}
cStatusBar(pal.bkSBarNT,pal.txtSBarNT,pal.bkSBarST,pal.txtSBarST,0,sBar[lang,PanelTypeOf(focus)]);{}

if HideCmdLine then CmdLine:=false else CmdLine:=true;

flash(off);

End;

End.