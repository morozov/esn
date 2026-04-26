unit test_drawbox_guard;
{ Regression coverage for DrawBox's inverted-coordinate guard.
  Pre-fills the cell buffer with a sentinel and asserts that
  DrawBox(...) leaves every cell untouched when y2 < y1 or
  x2 < x1.  Without the guard, word-typed bounds underflow to
  huge positives and the procedure paints stray rows. }

{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry;

type
  TDrawBoxGuardTest = class(TTestCase)
  published
    procedure TestInvertedY_DoesNotPaint;
    procedure TestInvertedX_DoesNotPaint;
  end;

implementation

uses rv, UnicodeVideo;

procedure TDrawBoxGuardTest.TestInvertedY_DoesNotPaint;
var
  W, H, i: integer;
begin
  W := 20;
  H := 5;
  ScreenWidth := W;
  ScreenHeight := H;
  SetLength(EnhancedVideoBuf, longword(W) * longword(H));
  for i := 0 to W * H - 1 do
  begin
    EnhancedVideoBuf[i].ExtendedGraphemeCluster := '#';
    EnhancedVideoBuf[i].Attribute := $07;
  end;

  { y1=4, y2=2 — coordinates inverted.  Old code drew '╔══╗' at row 4
    and '╚══╝' at row 2; the guard must suppress both. }
  DrawBox(0, 7, 2, 4, 8, 2);

  for i := 0 to W * H - 1 do
    AssertEquals('No cell rewritten when y2 < y1',
      UnicodeString('#'), EnhancedVideoBuf[i].ExtendedGraphemeCluster);

  SetLength(EnhancedVideoBuf, 0);
end;

procedure TDrawBoxGuardTest.TestInvertedX_DoesNotPaint;
{ Mirror of the y-inversion case for x.  word-typed parameters mean
  x2-x1 wraps to a huge value when x1 > x2, which without the guard
  would produce a multi-thousand-cell Fill string before CMPrint
  clips it. }
var
  W, H, i: integer;
begin
  W := 20;
  H := 3;
  ScreenWidth := W;
  ScreenHeight := H;
  SetLength(EnhancedVideoBuf, longword(W) * longword(H));
  for i := 0 to W * H - 1 do
  begin
    EnhancedVideoBuf[i].ExtendedGraphemeCluster := '#';
    EnhancedVideoBuf[i].Attribute := $07;
  end;

  { x1=10, x2=4 — inverted. }
  DrawBox(0, 7, 10, 1, 4, 3);

  for i := 0 to W * H - 1 do
    AssertEquals('No cell rewritten when x2 < x1',
      UnicodeString('#'), EnhancedVideoBuf[i].ExtendedGraphemeCluster);

  SetLength(EnhancedVideoBuf, 0);
end;

initialization
  RegisterTest(TDrawBoxGuardTest);

end.
