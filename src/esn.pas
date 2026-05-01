{$mode objfpc}{$H+}
Program Easy_Spectrum_Navigator;
Uses
      {$IFDEF UNIX}
      cwstring,
      {$ENDIF}
      SysUtils,
      RV,
      Vars, Init, sn_Obj, Main, Palette;

{$IFDEF DARWIN}
{ Returns the ASLR slide for the main executable (image index 0).
  At runtime, every address in the image is its on-disk static address
  plus this slide. Subtracting it yields a stable offset that atos and
  other tools can resolve from the binary on disk. }
function dyld_get_image_vmaddr_slide(image_index: longword): ptrint;
  cdecl; external name '_dyld_get_image_vmaddr_slide';
{$ENDIF}

{ Print exception class, message, and the static (slide-adjusted)
  address to stderr after taking the terminal out of the alternate
  screen buffer. RV's finalization re-runs these sequences when END.
  is reached — that's idempotent. }
procedure ReportUnhandled(E: Exception);
var
  staticAddr: pointer;
begin
  Write(StdErr, #27'[?25h'#27'[?1049l');
  Flush(StdErr);
  {$IFDEF DARWIN}
  {$PUSH}{$POINTERMATH ON}
  staticAddr := PByte(ExceptAddr) - dyld_get_image_vmaddr_slide(0);
  {$POP}
  {$ELSE}
  staticAddr := ExceptAddr;
  {$ENDIF}
  WriteLn(StdErr);
  WriteLn(StdErr, 'unhandled ', E.ClassName, ': ', E.Message);
  WriteLn(StdErr, '  at 0x', HexStr(staticAddr));
  ExitCode := 217;
end;

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
try
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
except
  on E: Exception do ReportUnhandled(E);
end;

END.

