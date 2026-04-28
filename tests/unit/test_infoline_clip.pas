unit test_infoline_clip;
{ When the input is wider than pw cells, InfoLine must clip rather
  than draw past the panel border, must respect grapheme-cluster
  boundaries (so wide glyphs are not split), and must let the `~`
  + `` ` `` color-toggle markers pass through as zero-width. }

{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry;

type
  TInfoLineClipTest = class(TTestCase)
  published
    procedure TestOverflowClipped_Ascii;
    procedure TestOverflowClipped_CJK;
    procedure TestOverflowClipped_PreservesMarkers;
  end;

implementation

uses rv, UnicodeVideo;

procedure TInfoLineClipTest.TestOverflowClipped_Ascii;
{ Input wider than pw: clip to pw cells; cells beyond pw stay
  untouched. }
var
  W, H, i: integer;
begin
  W := 30;
  H := 1;
  ScreenWidth := W;
  ScreenHeight := H;
  GmaxX := W;
  HalfMaxX := W div 2;
  SetLength(EnhancedVideoBuf, longword(W) * longword(H));
  for i := 0 to W - 1 do
  begin
    EnhancedVideoBuf[i].ExtendedGraphemeCluster := '#';
    EnhancedVideoBuf[i].Attribute := $07;
  end;

  { 21-cell input, pw=10. }
  InfoLine(0, 7, 0, 7, 1, 1,
    UTF8Decode('AAAAAAAAAAAAAAAAAAAAA'), 10);

  AssertEquals('Cell 1 holds clipped content',
    UnicodeString('A'), EnhancedVideoBuf[0].ExtendedGraphemeCluster);
  AssertEquals('Cell 10 (last permitted) holds A',
    UnicodeString('A'), EnhancedVideoBuf[9].ExtendedGraphemeCluster);
  AssertEquals('Cell 11 not overwritten by InfoLine',
    UnicodeString('#'), EnhancedVideoBuf[10].ExtendedGraphemeCluster);

  SetLength(EnhancedVideoBuf, 0);
end;

procedure TInfoLineClipTest.TestOverflowClipped_CJK;
{ Clip respects cluster boundaries.  '中' is 2 cells; with pw=5 the
  budget admits two clusters (4 cells) and rejects a third (would
  push to 6).  Cell 5 must remain the sentinel. }
var
  W, H, i: integer;
begin
  W := 30;
  H := 1;
  ScreenWidth := W;
  ScreenHeight := H;
  GmaxX := W;
  HalfMaxX := W div 2;
  SetLength(EnhancedVideoBuf, longword(W) * longword(H));
  for i := 0 to W - 1 do
  begin
    EnhancedVideoBuf[i].ExtendedGraphemeCluster := '#';
    EnhancedVideoBuf[i].Attribute := $07;
  end;

  { 12-cell CJK input, pw=5.  Clip yields '中文' (4 cells). }
  InfoLine(0, 7, 0, 7, 1, 1,
    UTF8Decode('中文中文中文'), 5);

  AssertEquals('Cell 1 holds first CJK glyph',
    UnicodeString('中'), EnhancedVideoBuf[0].ExtendedGraphemeCluster);
  AssertEquals('Cell 3 holds second CJK glyph',
    UnicodeString('文'), EnhancedVideoBuf[2].ExtendedGraphemeCluster);
  AssertEquals('Cell 5 not overwritten (third cluster rejected)',
    UnicodeString('#'), EnhancedVideoBuf[4].ExtendedGraphemeCluster);

  SetLength(EnhancedVideoBuf, 0);
end;

procedure TInfoLineClipTest.TestOverflowClipped_PreservesMarkers;
{ `~`-toggle markers are zero-width.  Clip must let them through
  without consuming the cell budget so color regions stay correctly
  bracketed when the visible content has to be truncated. }
var
  W, H, i: integer;
begin
  W := 30;
  H := 1;
  ScreenWidth := W;
  ScreenHeight := H;
  GmaxX := W;
  HalfMaxX := W div 2;
  SetLength(EnhancedVideoBuf, longword(W) * longword(H));
  for i := 0 to W - 1 do
  begin
    EnhancedVideoBuf[i].ExtendedGraphemeCluster := '#';
    EnhancedVideoBuf[i].Attribute := $07;
  end;

  { 16 visible cells (A×10 + B×6); pw=4.  Clip drops to 'AAAA'
    inside the marker pair and leaves cell 5 untouched. }
  InfoLine(0, 7, 4, 14, 1, 1,
    UTF8Decode('~`AAAAAAAAAA~`BBBBBB'), 4);

  AssertEquals('Cell 1 holds A (mark color region)',
    UnicodeString('A'), EnhancedVideoBuf[0].ExtendedGraphemeCluster);
  AssertEquals('Cell 4 holds last permitted A',
    UnicodeString('A'), EnhancedVideoBuf[3].ExtendedGraphemeCluster);
  AssertEquals('Cell 5 not overwritten by InfoLine',
    UnicodeString('#'), EnhancedVideoBuf[4].ExtendedGraphemeCluster);

  SetLength(EnhancedVideoBuf, 0);
end;

initialization
  RegisterTest(TInfoLineClipTest);

end.
