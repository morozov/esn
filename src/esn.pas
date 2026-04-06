{$M 37768,0,555350}
Program Easy_ZX_Spectrum_Navigator_v1_14;
Uses
{      SafeExit,{}
      Crt, RV,
      Vars, Init, sn_Obj, Main, Main_Ovr;


{================================= INIT =====================================}
BEGIN

CheckBreak:=false; snMouse:=false;
snInit(false);
{--------------------------------- LAUNCH -----------------------------------}
Case focus of
 left: lp.focused:=true;
 right: rp.focused:=true;
End;
reMDF;

if lp.PanelType<>pcPanel then if (lp.f<>0)and(lp.from<>0)and(lp.tfiles<>0) then lp.Outside;
if rp.PanelType<>pcPanel then if (rp.f<>0)and(rp.from<>0)and(rp.tfiles<>0) then rp.Outside;

lp.Build('012'); rp.Build('012');
reTrueCur; reInside;

Repeat
 Navigate;
 if snKernelExitCode=9 then ChangeFocus;
Until false;

END.

