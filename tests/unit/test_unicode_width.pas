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

    { ===== CMPrint trailing-cell handling for wide chars ===== }
    procedure TestCMPrint_WideChar_ClearsTrailingCell;
    procedure TestCMPrint_AstralEmoji_StoredAsCluster;

    { ===== StatusLineColor advances by display width ===== }
    procedure TestStatusLineColor_CJK_AdvancesByDisplayWidth;

    { ===== Helpers measure by display width, not code units ===== }
    procedure TestCmCentre_CJK_CentersByCells;
    procedure TestCButton_CJK_ShadowMatchesDisplayWidth;
    procedure TestCButton_AstralFirstCluster_NotSplit;
    procedure TestCButton_SingleClusterActive_WrapsWithArrows;
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

procedure TUnicodeWidthTest.TestCMPrint_WideChar_ClearsTrailingCell;
{ When CMPrint writes a wide char (display width 2) at column N, it
  must also clear the trailing cell at column N+1.  Otherwise stale
  content from prior renders at the same screen position remains
  visible through the wide glyph's overlay area, producing phantom
  characters between adjacent wide glyphs. }
var
  W, H: integer;
begin
  W := 10;
  H := 1;
  ScreenWidth := W;
  ScreenHeight := H;
  SetLength(EnhancedVideoBuf, longword(W) * longword(H));

  { Pre-populate cell 1 (offset 0) and cell 2 (offset 1) with stale
    content to simulate a prior render. }
  EnhancedVideoBuf[0].ExtendedGraphemeCluster := 'X';
  EnhancedVideoBuf[0].Attribute := $07;
  EnhancedVideoBuf[1].ExtendedGraphemeCluster := 'r';
  EnhancedVideoBuf[1].Attribute := $07;

  { Write a wide char at col 1.  CMPrint must overwrite cell 1 with
    the wide char AND clear cell 2 (its trailing half). }
  CMPrint(0, 7, 1, 1, '中');

  AssertEquals('Leading cell holds wide char',
    UnicodeString('中'), EnhancedVideoBuf[0].ExtendedGraphemeCluster);
  AssertEquals('Trailing cell cleared',
    UnicodeString(''), EnhancedVideoBuf[1].ExtendedGraphemeCluster);

  SetLength(EnhancedVideoBuf, 0);
end;

procedure TUnicodeWidthTest.TestCMPrint_AstralEmoji_StoredAsCluster;
{ Astral codepoints (U+10000+) are encoded as a UTF-16 surrogate pair.
  CMPrint must store the pair as a single grapheme cluster in one
  cell, not two cells of bare surrogate halves.

  Note: this asserts only the buffer state.  The Windows display
  path (lib/fpc/rtl-console/src/win/unicodevideo.pp:SysUpdateScreen)
  packs each cell into a single TCharInfo WideChar and substitutes
  ' ' for any cluster longer than 1 codeunit, so astral codepoints
  blank out on Windows.  Unix renders them via OutData and shows
  the full cluster.  See lib/fpc/UPSTREAM.md (caveat under P3). }
var
  W, H: integer;
  emoji: UnicodeString;
begin
  W := 10;
  H := 1;
  ScreenWidth := W;
  ScreenHeight := H;
  SetLength(EnhancedVideoBuf, longword(W) * longword(H));

  emoji := UTF8Decode('😀');  { U+1F600 = surrogate pair D83D DE00 }
  CMPrint(0, 7, 1, 1, emoji);

  AssertEquals('Cell holds full surrogate pair (2 codeunits)',
    2, Length(EnhancedVideoBuf[0].ExtendedGraphemeCluster));
  AssertEquals('Cell cluster equals input emoji',
    emoji, EnhancedVideoBuf[0].ExtendedGraphemeCluster);
  AssertEquals('Trailing cell cleared',
    UnicodeString(''), EnhancedVideoBuf[1].ExtendedGraphemeCluster);

  SetLength(EnhancedVideoBuf, 0);
end;

procedure TUnicodeWidthTest.TestStatusLineColor_CJK_AdvancesByDisplayWidth;
{ StatusLineColor renders a string with `~`-toggle markers between
  alternating color regions.  The fix: emit each marker-bounded run
  as a single CMPrint call so the per-cluster grapheme iteration
  inside CMPrint applies, and advance x by StringDisplayWidth of the
  whole segment — not by UTF-16 code-unit count.  Two regressions
  this test would catch:

    1. Astral emoji '😀' (U+1F600) is a surrogate pair.  The old
       per-code-unit loop stored two lone surrogates in two cells.
       The fix stores the full cluster in one cell and clears the
       trailing cell.

    2. The marker toggle after the emoji must land x at cell 3, so
       'X' (mark color) and 'y' (normal) follow the wide glyph
       without overwriting it. }
var
  W, H: integer;
  s: UnicodeString;
begin
  W := 20;
  H := 1;
  ScreenWidth := W;
  ScreenHeight := H;
  SetLength(EnhancedVideoBuf, longword(W) * longword(H));

  s := UTF8Decode('😀~`X~`y');
  StatusLineColor(0, 7, 4, 14, 1, 1, s);

  AssertEquals('Cell 1 holds full astral cluster',
    2, Length(EnhancedVideoBuf[0].ExtendedGraphemeCluster));
  AssertEquals('Cell 2 cleared as wide trailing',
    UnicodeString(''), EnhancedVideoBuf[1].ExtendedGraphemeCluster);
  AssertEquals('Cell 3 holds X (mark color region)',
    UnicodeString('X'), EnhancedVideoBuf[2].ExtendedGraphemeCluster);
  AssertEquals('Cell 4 holds y (back to normal color)',
    UnicodeString('y'), EnhancedVideoBuf[3].ExtendedGraphemeCluster);

  SetLength(EnhancedVideoBuf, 0);
end;

procedure TUnicodeWidthTest.TestCmCentre_CJK_CentersByCells;
{ cmCentre must measure the input by display width (cells), not by
  UTF-16 code-unit length.  '中文' is 2 codepoints / 2 codeunits but
  occupies 4 cells.  With HalfMaxX = 40 (screen width 80), the
  centred draw must start at x = 1 + (40 - 2) = 39, so cell 39 holds
  '中' (leading half) and cell 41 holds '文'.  Old `Length(s) div 2 = 1`
  arithmetic put it at cell 40, which would land asymmetrically. }
var
  W, H: integer;
begin
  W := 80;
  H := 1;
  ScreenWidth := W;
  ScreenHeight := H;
  GmaxX := W;
  HalfMaxX := W div 2;
  SetLength(EnhancedVideoBuf, longword(W) * longword(H));

  cmCentre(0, 7, 1, UTF8Decode('中文'));

  AssertEquals('Cell 39 holds first CJK glyph (centred by cells)',
    UnicodeString('中'), EnhancedVideoBuf[38].ExtendedGraphemeCluster);
  AssertEquals('Cell 41 holds second CJK glyph',
    UnicodeString('文'), EnhancedVideoBuf[40].ExtendedGraphemeCluster);

  SetLength(EnhancedVideoBuf, 0);
end;

procedure TUnicodeWidthTest.TestCButton_CJK_ShadowMatchesDisplayWidth;
{ cButton's shadow row is `Fill(w, '▀')`.  The shadow must span the
  visible label's display width, not its code-unit count.  Inactive
  '中a' = 3 cells (CJK 2 + ASCII 1).  The '▄' shadow corner lands at
  x + 3, and the bottom row holds 3 '▀' cells. }
var
  W, H, x: integer;
begin
  W := 20;
  H := 3;
  ScreenWidth := W;
  ScreenHeight := H;
  SetLength(EnhancedVideoBuf, longword(W) * longword(H));

  x := 1;
  cButton(0, 7, 0, 8, x, 1, UTF8Decode('中a'), false);

  { Shadow corner at (x + w, y) = (4, 1). }
  AssertEquals('Shadow corner at x + display-width',
    UnicodeString('▄'),
    EnhancedVideoBuf[longword(0) * W + 3].ExtendedGraphemeCluster);
  { Shadow row cells at y+1: x+1=2, x+2=3, x+3=4. }
  AssertEquals('Shadow row cell 1',
    UnicodeString('▀'),
    EnhancedVideoBuf[longword(1) * W + 1].ExtendedGraphemeCluster);
  AssertEquals('Shadow row cell 2',
    UnicodeString('▀'),
    EnhancedVideoBuf[longword(1) * W + 2].ExtendedGraphemeCluster);
  AssertEquals('Shadow row cell 3',
    UnicodeString('▀'),
    EnhancedVideoBuf[longword(1) * W + 3].ExtendedGraphemeCluster);

  SetLength(EnhancedVideoBuf, 0);
end;

procedure TUnicodeWidthTest.TestCButton_SingleClusterActive_WrapsWithArrows;
{ With one grapheme cluster the active path can't replace both
  ends; wrap the input between the arrow markers instead so the
  button still reads as active. }
var
  W, H: integer;
begin
  W := 10;
  H := 2;
  ScreenWidth := W;
  ScreenHeight := H;
  SetLength(EnhancedVideoBuf, longword(W) * longword(H));

  cButton(0, 7, 0, 8, 1, 1, UTF8Decode('X'), true);

  AssertEquals('Cell 1 holds left arrow marker',
    UnicodeString('►'), EnhancedVideoBuf[0].ExtendedGraphemeCluster);
  AssertEquals('Cell 2 holds the original cluster',
    UnicodeString('X'), EnhancedVideoBuf[1].ExtendedGraphemeCluster);
  AssertEquals('Cell 3 holds right arrow marker',
    UnicodeString('◄'), EnhancedVideoBuf[2].ExtendedGraphemeCluster);

  SetLength(EnhancedVideoBuf, 0);
end;

procedure TUnicodeWidthTest.TestCButton_AstralFirstCluster_NotSplit;
{ When active=true cButton replaces the first and last grapheme
  clusters with arrow markers ('►' and '◄').  An astral emoji
  '😀' is a surrogate pair (2 codeunits).  Old code used
  `Copy(t, 2, Length(t)-2)` which would split the pair, leaving a
  lone low surrogate as the first cluster of the middle.  Cluster-
  aware replace must yield exactly '►X◄' for input '😀X😀'. }
var
  W, H: integer;
begin
  W := 10;
  H := 2;
  ScreenWidth := W;
  ScreenHeight := H;
  SetLength(EnhancedVideoBuf, longword(W) * longword(H));

  cButton(0, 7, 0, 8, 1, 1, UTF8Decode('😀X😀'), true);

  AssertEquals('Cell 1 holds left arrow marker',
    UnicodeString('►'), EnhancedVideoBuf[0].ExtendedGraphemeCluster);
  AssertEquals('Cell 2 holds preserved middle cluster',
    UnicodeString('X'), EnhancedVideoBuf[1].ExtendedGraphemeCluster);
  AssertEquals('Cell 3 holds right arrow marker',
    UnicodeString('◄'), EnhancedVideoBuf[2].ExtendedGraphemeCluster);

  SetLength(EnhancedVideoBuf, 0);
end;

initialization
  RegisterTest(TUnicodeWidthTest);

end.
