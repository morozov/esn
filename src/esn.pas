{$mode objfpc}{$H+}
Program Easy_Spectrum_Navigator;
Uses
      RV,
      Vars, Init, sn_Obj, Main, Palette;


{================================= INIT =====================================}
BEGIN

if (ParamCount = 1) and (ParamStr(1) = '--version') then
begin
  WriteLn('Easy Spectrum Navigator ', Ver);
  WriteLn('Built with Free Pascal ', {$I %FPCVERSION%});
  Halt(0);
end;

RvInit;
ApplyVGAPalette;
snInit(false);
{--------------------------------- LAUNCH -----------------------------------}
Case focus of
 left: lp.focused:=true;
 right: rp.focused:=true;
End;
lp.Build('012'); rp.Build('012');
reMDF;

if lp.PanelType<>pcPanel then if (lp.f<>0)and(lp.from<>0)and(lp.tfiles<>0) then lp.Outside;
if rp.PanelType<>pcPanel then if (rp.f<>0)and(rp.from<>0)and(rp.tfiles<>0) then rp.Outside;

reTrueCur; reInside;
GlobalRedraw;

Repeat
 Navigate;
 if snKernelExitCode=9 then ChangeFocus;
Until false;

END.

