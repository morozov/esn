unit test_resize;
{ Tests for terminal resize helpers: ClampPanel
  and TPanel.PanelSetup geometry at various terminal sizes. }
{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry, sn_obj, rv, vars;

type
  TPanelGeometryTest = class(TTestCase)
  private
    p: TPanel;
    savedCmdLine: boolean;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestGeom_Standard;
    procedure TestGeom_Wide;
    procedure TestGeom_NameLine;
    procedure TestGeom_CmdLine;
    procedure TestGeom_MinSize;
  end;

  TClampTest = class(TTestCase)
  published
    procedure TestClamp_NoChange;
    procedure TestClamp_F_TooLarge;
    procedure TestClamp_From_TooLarge;
    procedure TestClamp_From_Becomes_Zero;
    procedure TestClamp_Empty_Panel;
    procedure TestClamp_MultiColumn;
  end;

implementation

{ ===== TPanelGeometryTest ===== }

procedure TPanelGeometryTest.SetUp;
begin
  savedCmdLine := CmdLine;
  {$push}{$notes off}
  FillChar(p, SizeOf(p), 0);
  {$pop}
  p.InfoLines := 3;
  p.NameLine  := false;
  p.Columns   := 1;
  CmdLine     := false;
end;

procedure TPanelGeometryTest.TearDown;
begin
  CmdLine := savedCmdLine;
end;

procedure TPanelGeometryTest.TestGeom_Standard;
var rgt: TPanel;
begin
  GmaxX := 80; GmaxY := 25;
  HalfMaxX := GmaxX div 2; HalfMaxY := GmaxY div 2;

  p.Place := Left;
  p.PosX  := 1;
  p.PanelSetup;
  AssertEquals('PanelW left std',  38, p.PanelW);
  AssertEquals('PanelHi left std', 18, p.PanelHi);
  AssertEquals('PanelLong std',    24, p.PanelLong);
  AssertEquals('PosX left std',     1, p.PosX);

  {$push}{$hints off}{$notes off}
  FillChar(rgt, SizeOf(rgt), 0);
  {$pop}
  rgt.InfoLines := 3;
  rgt.NameLine  := false;
  rgt.Columns   := 1;
  rgt.Place := Right;
  rgt.PosX  := 1;
  rgt.PanelSetup;
  AssertEquals('PosX right std', 41, rgt.PosX);
end;

procedure TPanelGeometryTest.TestGeom_Wide;
var rgt: TPanel;
begin
  GmaxX := 120; GmaxY := 40;
  HalfMaxX := GmaxX div 2; HalfMaxY := GmaxY div 2;

  p.Place := Left;
  p.PosX  := 1;
  p.PanelSetup;
  AssertEquals('PanelW wide',    58, p.PanelW);
  AssertEquals('PanelHi wide',   33, p.PanelHi);
  AssertEquals('PanelLong wide', 39, p.PanelLong);

  {$push}{$hints off}{$notes off}
  FillChar(rgt, SizeOf(rgt), 0);
  {$pop}
  rgt.InfoLines := 3;
  rgt.NameLine  := false;
  rgt.Columns   := 1;
  rgt.Place := Right;
  rgt.PosX  := 1;
  rgt.PanelSetup;
  AssertEquals('PosX right wide', 61, rgt.PosX);
end;

procedure TPanelGeometryTest.TestGeom_NameLine;
begin
  GmaxX := 80; GmaxY := 25;
  HalfMaxX := GmaxX div 2; HalfMaxY := GmaxY div 2;

  p.NameLine := true;
  p.Place := Left;
  p.PosX  := 1;
  p.PanelSetup;
  AssertEquals('PanelHi nameline', 17, p.PanelHi);
  AssertEquals('PutFrom nameline',  3, p.PutFrom);
end;

procedure TPanelGeometryTest.TestGeom_CmdLine;
begin
  GmaxX := 80; GmaxY := 25;
  HalfMaxX := GmaxX div 2; HalfMaxY := GmaxY div 2;

  CmdLine := true;
  p.Place := Left;
  p.PosX  := 1;
  p.PanelSetup;
  AssertEquals('PanelHi cmdline',   17, p.PanelHi);
  AssertEquals('PanelLong cmdline', 23, p.PanelLong);
end;

procedure TPanelGeometryTest.TestGeom_MinSize;
var rgt: TPanel;
begin
  GmaxX := 40; GmaxY := 12;
  HalfMaxX := GmaxX div 2; HalfMaxY := GmaxY div 2;

  p.Place := Left;
  p.PosX  := 1;
  p.PanelSetup;
  AssertEquals('PanelW min',  18, p.PanelW);
  AssertEquals('PanelHi min',  5, p.PanelHi);

  {$push}{$hints off}{$notes off}
  FillChar(rgt, SizeOf(rgt), 0);
  {$pop}
  rgt.InfoLines := 3;
  rgt.NameLine  := false;
  rgt.Columns   := 1;
  rgt.Place := Right;
  rgt.PosX  := 1;
  rgt.PanelSetup;
  AssertEquals('PosX right min', 21, rgt.PosX);
end;

{ ===== TClampTest ===== }

procedure TClampTest.TestClamp_NoChange;
var f, from: longint;
begin
  f := 5; from := 1;
  ClampPanel(f, from, 10, 1, 20);
  AssertEquals('f no change',    5, f);
  AssertEquals('from no change', 1, from);
end;

procedure TClampTest.TestClamp_F_TooLarge;
var f, from: longint;
begin
  f := 15; from := 1;
  ClampPanel(f, from, 10, 1, 20);
  AssertEquals('f clamped',      10, f);
  AssertEquals('from unchanged',  1, from);
end;

procedure TClampTest.TestClamp_From_TooLarge;
var f, from: longint;
begin
  f := 10; from := 15;
  ClampPanel(f, from, 10, 1, 20);
  AssertEquals('f unchanged',   10, f);
  AssertEquals('from adjusted', 11, from);
end;

procedure TClampTest.TestClamp_From_Becomes_Zero;
var f, from: longint;
begin
  f := 8; from := 1;
  ClampPanel(f, from, 10, 1, 5);
  AssertEquals('f clamped to total', 5, f);
  AssertEquals('from stays 1',       1, from);
end;

procedure TClampTest.TestClamp_Empty_Panel;
var f, from: longint;
begin
  f := 1; from := 1;
  ClampPanel(f, from, 10, 1, 0);
  { No crash; f stays 1, from stays 1 }
  AssertEquals('f empty panel',    1, f);
  AssertEquals('from empty panel', 1, from);
end;

procedure TClampTest.TestClamp_MultiColumn;
var f, from: longint;
begin
  f := 25; from := 1;
  { panelHi * cols = 30, but f=25 > total=20
    → from + f - 1 = 25 > 20 → from := 20 - 25 + 1 = -4 → 1 }
  ClampPanel(f, from, 10, 3, 20);
  AssertEquals('f multicol',    20, f);
  AssertEquals('from multicol',  1, from);
end;

initialization
  RegisterTest(TPanelGeometryTest);
  RegisterTest(TClampTest);

end.
