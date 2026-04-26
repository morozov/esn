program run_tests;
{ Test runner for all ESN unit tests. }
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cwstring,
  {$ENDIF}
  consoletestrunner,
  test_trd,
  test_tap,
  test_scl,
  test_sn_utils,
  test_pc,
  test_resize,
  test_insert,
  test_unicode_width,
  test_infoline_clip;

var
  app: TTestRunner;

begin
  app := TTestRunner.Create(nil);
  app.Initialize;
  app.Run;
  app.Free;
end.
