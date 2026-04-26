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

    { ===== pcNameLine padding to 12 display cells ===== }
    procedure TestNameLine_Cyrillic_PadToTwelve;
    procedure TestNameLine_CJK_PadToTwelve;

    { ===== CCLen: display width of UTF-8 string ===== }
    procedure TestCCLen_Cyrillic;
    procedure TestCCLen_CJK;
    procedure TestCCLen_TildaMarker_Cyrillic;
    procedure TestCCLen_Emoji_BMP_Symbol;
    procedure TestCCLen_Emoji_BMP_VS16Presentation;
    procedure TestCCLen_Emoji_AstralFace;
    procedure TestCCLen_Emoji_SkinToneModifier;
    procedure TestCCLen_Emoji_ZWJSequence;
    procedure TestCCLen_Emoji_RegionalIndicatorFlag;
  end;

implementation

uses pc, sn_obj, vars, rv, UnicodeVideo, graphemebreakproperty, SysUtils;

const
  MaxEntries = 4;

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

{ ===== pcNameLine tests =====
  pcNameLine pads the file name to 12 display cells via dispWidth,
  then appends size, date, time. We verify the *prefix* width: the
  first 12 display cells must hold name + trailing spaces. }

function MakePanel: TPanel;
begin
  {$push}{$notes off}
  FillChar(result, SizeOf(result), 0);
  {$pop}
  result.PanelType := pcPanel;
  GetMem(result.pcDir, MaxEntries * SizeOf(pcDirRec));
  {$push}{$notes off}
  FillChar(result.pcDir^, MaxEntries * SizeOf(pcDirRec), 0);
  {$pop}
end;

procedure FreePanel(var p: TPanel);
begin
  FreeMem(p.pcDir, MaxEntries * SizeOf(pcDirRec));
end;

{ Return the prefix of UTF-8 string s whose display width equals w
  cells. Used to extract the padded-name portion of pcNameLine's
  result for verification. }
function CellPrefix(const s: AnsiString; w: integer): AnsiString;
var
  us, picked, egc: UnicodeString;
  acc, cw: integer;
begin
  us := UTF8Decode(s);
  acc := 0;
  picked := '';
  for egc in TUnicodeStringExtendedGraphemeClustersEnumerator.Create(us) do
  begin
    cw := ExtendedGraphemeClusterDisplayWidth(egc);
    if acc + cw > w then break;
    picked := picked + egc;
    Inc(acc, cw);
    if acc = w then break;
  end;
  result := UTF8Encode(picked);
end;

procedure TUnicodeWidthTest.TestNameLine_Cyrillic_PadToTwelve;
{ 'файл.txt' → name 'файл' (4 cells) + '.txt' (4 cells) = 8 cells;
  pcNameLine pads to 12 cells with 4 spaces. Verify the 12-cell
  prefix ends with at least one space. }
var
  p: TPanel;
  line, prefix: string;
begin
  p := MakePanel;
  try
    p.pcDir^[1].fname := 'файл';
    p.pcDir^[1].fext  := 'txt';
    p.pcDir^[1].flength := 100;
    line := pcNameLine(p, 1);
    prefix := CellPrefix(line, 12);
    AssertEquals('Cyrillic name prefix is 12 cells',
                 12, CellWidth(prefix));
    AssertEquals('Cyrillic name prefix trailing space',
                 ' ', Copy(prefix, Length(prefix), 1));
  finally
    FreePanel(p);
  end;
end;

procedure TUnicodeWidthTest.TestNameLine_CJK_PadToTwelve;
{ '中文.txt' → name '中文' (4 cells) + '.txt' (4 cells) = 8 cells;
  must be padded to 12. }
var
  p: TPanel;
  line, prefix: string;
begin
  p := MakePanel;
  try
    p.pcDir^[1].fname := '中文';
    p.pcDir^[1].fext  := 'txt';
    p.pcDir^[1].flength := 100;
    line := pcNameLine(p, 1);
    prefix := CellPrefix(line, 12);
    AssertEquals('CJK name prefix is 12 cells',
                 12, CellWidth(prefix));
  finally
    FreePanel(p);
  end;
end;

{ ===== CCLen tests =====
  CCLen counts display cells in a UTF-8 string with `~`+`` ` ``
  marker pairs treated as zero-width toggles (used by
  StatusLineColor for inline-color escapes in dialog text). }

procedure TUnicodeWidthTest.TestCCLen_Cyrillic;
begin
  AssertEquals('Cyrillic 4 chars', 4, CCLen('файл'));
end;

procedure TUnicodeWidthTest.TestCCLen_CJK;
begin
  AssertEquals('CJK 2 chars × 2 cells', 4, CCLen('中文'));
end;

procedure TUnicodeWidthTest.TestCCLen_TildaMarker_Cyrillic;
{ Marker pair is `~` followed by `` ` `` (two chars opening and
  closing); both are zero-width. The 4 Cyrillic letters between
  them remain countable. }
begin
  AssertEquals('tilda-marker around Cyrillic', 4, CCLen('~`файл~`'));
end;

procedure TUnicodeWidthTest.TestCCLen_Emoji_BMP_Symbol;
{ '★' U+2605 is single-codepoint BMP, EAW Ambiguous → 1 cell. }
begin
  AssertEquals('BMP symbol star', 1, CCLen('★'));
end;

procedure TUnicodeWidthTest.TestCCLen_Emoji_BMP_VS16Presentation;
{ '❤️' = U+2764 + U+FE0F (variation selector). The two codepoints
  are one grapheme cluster. FPC's StringDisplayWidth returns the
  East Asian Width of the cluster's first codepoint (U+2764, EAW=N
  → 1 cell) and does NOT yet upgrade to 2 cells when VS-16 selects
  emoji presentation (FPC video.inc has a `todo: handle emoji +
  modifiers` for this). Asserting 1 documents the current
  behavior; if FPC fixes the TODO this test alerts us. }
begin
  AssertEquals('BMP heart with VS-16', 1, CCLen('❤️'));
end;

procedure TUnicodeWidthTest.TestCCLen_Emoji_AstralFace;
{ '😀' U+1F600 is astral-plane (surrogate pair in UTF-16).
  The grapheme is 2 cells. }
begin
  AssertEquals('astral grinning face', 2, CCLen('😀'));
end;

procedure TUnicodeWidthTest.TestCCLen_Emoji_SkinToneModifier;
{ '👍🏽' = U+1F44D (thumbs up) + U+1F3FD (medium skin tone). Two
  surrogate pairs that combine into one grapheme cluster of 2 cells. }
begin
  AssertEquals('thumbs-up + skin tone', 2, CCLen('👍🏽'));
end;

procedure TUnicodeWidthTest.TestCCLen_Emoji_ZWJSequence;
{ '👨‍💻' = man + ZWJ + laptop. Modern terminals render this as a
  single 2-cell glyph; FPC's vendored grapheme-break table predates
  Unicode 11's `ZWJ + Extended_Pictographic → no break` rule, so it
  splits into two clusters: 'man' (2 cells) + 'laptop' (2 cells) =
  4. Asserting 4 documents the FPC limitation; the result will be
  one cluster (2 cells) once the vendored table is refreshed. }
begin
  AssertEquals('man + ZWJ + laptop', 4, CCLen('👨‍💻'));
end;

procedure TUnicodeWidthTest.TestCCLen_Emoji_RegionalIndicatorFlag;
{ '🇺🇸' = RI U+1F1FA + RI U+1F1F8. The two regional indicators
  cluster into a single flag glyph that terminals render in 2
  cells. FPC's StringDisplayWidth uses the first codepoint's East
  Asian Width (U+1F1FA, EAW=N → 1 cell) and does not yet recognize
  RI-pair emoji presentation (same `todo: handle emoji + modifiers`
  in video.inc). Asserting 1 documents the current behavior. }
begin
  AssertEquals('US flag', 1, CCLen('🇺🇸'));
end;

initialization
  RegisterTest(TUnicodeWidthTest);

end.
