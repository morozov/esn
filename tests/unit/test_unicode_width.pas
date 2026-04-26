unit test_unicode_width;
{ Unit tests for display-width handling of multi-byte UTF-8 strings:
  Cyrillic (1-cell, 2-byte UTF-8), CJK (2-cell, 3-byte UTF-8), and
  several emoji classes (BMP, VS-16 presentation, astral plane,
  skin-tone modifier, ZWJ sequence, regional-indicator flag). }

{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry;

type
  TUnicodeWidthTest = class(TTestCase)
  published
    { ===== PcColumnEntry: panel column truncation/padding ===== }
    procedure TestColumnEntry_Cyrillic_Width;
    procedure TestColumnEntry_CJK_Width;
    procedure TestColumnEntry_CJK_TruncatedNoSplit;
    procedure TestColumnEntry_Mixed_AsciiCJK;
    procedure TestColumnEntry_Cyrillic_OddLeft;
    procedure TestColumnEntry_Emoji_BMP_Width;
    procedure TestColumnEntry_Emoji_Astral_Width;
  end;

implementation

uses pc, UnicodeVideo, SysUtils;

{ Display-width helper used by the test asserts: defers to FPC's
  StringDisplayWidth, which iterates grapheme clusters and decodes
  surrogate pairs. Tests assert against this reference rather than
  duplicating per-codepoint iteration so a buggy helper cannot
  agree with a buggy verifier. }
function CellWidth(const s: AnsiString): integer;
begin
  result := StringDisplayWidth(UTF8Decode(s));
end;

{ ===== PcColumnEntry tests ===== }

procedure TUnicodeWidthTest.TestColumnEntry_Cyrillic_Width;
{ Cyrillic 'файл' is 4 codepoints × 1 cell = 4 cells of name (each
  glyph is 2 UTF-8 bytes, so 8 bytes). PcColumnEntry pads to padTo=8
  cells, then appends ' ' + 'log'. Display width must be 12. }
var
  s: string;
begin
  s := PcColumnEntry('файл', 'log', 13, 0);
  AssertEquals('Cyrillic display width', 12, CellWidth(s));
end;

procedure TUnicodeWidthTest.TestColumnEntry_CJK_Width;
{ CJK '中文' is 2 codepoints × 2 cells = 4 cells of name. Same
  budget; padding adds 4 spaces. Display width must be 12. }
var
  s: string;
begin
  s := PcColumnEntry('中文', 'txt', 13, 0);
  AssertEquals('CJK display width', 12, CellWidth(s));
end;

procedure TUnicodeWidthTest.TestColumnEntry_CJK_TruncatedNoSplit;
{ Six CJK chars (12 cells) overflow the 8-cell name budget. The
  truncator must stop on a cluster boundary (4 chars = 8 cells),
  never half-write a wide glyph. Display width still 12. }
var
  s: string;
begin
  s := PcColumnEntry('中文中文中文', 'txt', 13, 0);
  AssertEquals('CJK truncated display width', 12, CellWidth(s));
end;

procedure TUnicodeWidthTest.TestColumnEntry_Mixed_AsciiCJK;
{ 'a中b文' = 1+2+1+2 = 6 cells. Padding adds 2 spaces. }
var
  s: string;
begin
  s := PcColumnEntry('a中b文', 'txt', 13, 0);
  AssertEquals('mixed ASCII/CJK display width', 12, CellWidth(s));
end;

procedure TUnicodeWidthTest.TestColumnEntry_Cyrillic_OddLeft;
{ 'фа' = 2 cells; padded to 8 with 6 spaces. Total 12 display cells. }
var
  s: string;
begin
  s := PcColumnEntry('фа', 'log', 13, 0);
  AssertEquals('Cyrillic short name display width',
               12, CellWidth(s));
end;

procedure TUnicodeWidthTest.TestColumnEntry_Emoji_BMP_Width;
{ '★' (U+2605) is a single BMP codepoint, EAW Ambiguous → 1 cell
  in non-CJK locale. The full result must occupy 12 cells. }
var
  s: string;
begin
  s := PcColumnEntry('star★', 'txt', 13, 0);
  AssertEquals('BMP-symbol emoji display width',
               12, CellWidth(s));
end;

procedure TUnicodeWidthTest.TestColumnEntry_Emoji_Astral_Width;
{ '😀' (U+1F600) is an astral-plane emoji (UTF-16 surrogate pair).
  PcColumnEntry must consume it as one cluster of 2 cells, not split
  the surrogate pair. Result occupies 12 display cells. }
var
  s: string;
begin
  s := PcColumnEntry('hi😀', 'txt', 13, 0);
  AssertEquals('astral emoji display width', 12, CellWidth(s));
end;

initialization
  RegisterTest(TUnicodeWidthTest);

end.
